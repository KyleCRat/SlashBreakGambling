# Transactional Stats Reconciliation Plan

Status: Deferred. Do not implement unless the owner explicitly decides to pursue this direction.

Discussion recorded: 2026-09-09.

This document records a potential future design. The addon currently retains its simpler net-total statistics system. The performance budgets, protocol details, and retention policy below are proposals, not implemented behavior or final commitments.

## Context

A suspected missing result prompted this discussion. Glazerbeam-Sargeras won 98,536g after rolling 99,381 against a losing roll of 845. Lithdx-Illidan hosted that session and had also recorded an earlier 70,570g loss by Glazerbeam that Yvairel-Illidan had not witnessed.

The reported totals were correct:

- Lithdx's record: 98,536g - 70,570g = 27,966g.
- Yvairel's record: 98,536g.

That incident did not establish a synchronization bug. Reconciliation would be a new capability for recovering missing game history, not a required fix for that report.

The rough effort estimate discussed was 3-5 engineering days for a reliable first version, including migration and multi-client testing. This is a planning estimate; resolve the open decisions before treating it as an implementation commitment.

## Current Implementation

- [Stats.lua](Stats.lua) stores per-character net totals in `addon.db.acedb.char.stats`. It has no transaction history, result IDs, reconciliation indexes, or historical timestamps.
- [Session.lua](Session.lua) calculates results on the session host. `BroadcastAndUpdateStats` sends a `RESULT` message and then updates the host's totals. Receivers call `OnRemoteResult` and add the amounts to their own totals.
- Existing result messages have no transaction identity, duplicate protection, acknowledgement, or recovery protocol. The remote result handler also does not establish that a player was witnessed live before adding their stats.
- [SlashCommands.lua](SlashCommands.lua) exposes local stats lookup, addition, removal, and reset commands. These currently mutate net totals directly.
- [Initialize.lua](Initialize.lua) creates the database during `OnInitialize`, before registering addon-message listeners. This is the proposed migration integration point.
- The addon embeds Ace3 components but does not currently embed AceComm or ChatThrottleLib. Session messages call `C_ChatInfo.SendAddonMessage` directly.

Existing aggregate totals cannot reveal which individual games produced them. Do not attempt to reconstruct old winner-loser transactions from those totals.

## Goals And Boundaries

- Record each scored winner-loser pair as a uniquely identified transaction.
- Recover missing eligible transactions from other connected addon clients without counting a transaction more than once.
- Reconcile only players the requesting client already knows through live SBG games, with existing stats names used as the initial migration seed.
- Prevent reconciliation from expanding the user's tracked-player list through opponents they have never observed.
- Keep imported starting totals and manual adjustments editable and local.
- Bound history storage, network traffic, temporary buffers, and processing work.
- Preserve current game modes, gold accounting, and statistics presentation.

This does not require sharing individual random rolls, adding a transaction-history UI, changing game rules, introducing a server, building a global player database, or tracking whether gold was traded. A transaction represents a scored game outcome.

Successful reconciliation means clients agree on applicable game records within a shared history window. It does not require identical displayed totals: local adjustments, migration cutoffs, reset choices, and retained history can intentionally differ.

## Transaction Model

The following is a conceptual model, not a finalized SavedVariables or wire schema.

| Field | Purpose |
|---|---|
| Transaction ID | Stable identity of one winner-loser pair, assigned by the host |
| Game ID | Links the pairs produced by the same game |
| `completedAt` | Original host-assigned time when the valid game result was finalized |
| Host identity | Records the originating session host |
| Winner | Canonical full `Name-Realm` |
| Loser | Canonical full `Name-Realm` |
| Amount | Positive gold amount for this pair |
| Game mode | Optional immutable context for the recorded outcome |

The transaction ID is an event identity, not merely a player's WoW GUID. A timestamp alone is not unique enough. The host must assign an ID once and reuse it for retries and forwarding. The exact ID format remains to be selected.

`completedAt` is the agreed field name. It means the game result was finalized, not that gold changed hands. Every copy retains the original value; receiving, retrying, or reconciling a transaction never changes it. Pairs from one finalized result should share its completion timestamp.

Low Pays High produces one pair. A mode with one winner and multiple losers produces one pair per loser. For example, a 20-player Last Man Standing result can produce 19 transactions. Preserve the existing per-loser amount and guild-cut accounting conventions; reconciliation must not change the economic result of a game.

Cancelled, unscored, or tied outcomes without a payable result produce no payout transactions.

## Local State And Displayed Totals

Proposed persistent state belongs to the same per-character database scope as current stats:

- A schema/migration version.
- `migratedAt`, set once when that character first initializes the transactional system.
- Editable local adjustments keyed by player name.
- A locally observed/eligible player set, separate from transaction counterpart metadata.
- Transactions keyed by their stable IDs.
- Retention/compaction boundaries and any local reset/removal boundaries required to prevent replay.

Derived lookup indexes and summary caches can be rebuilt from the persistent records. Avoid persisting redundant structures without a measured need.

The displayed total is:

```text
local adjustment + sum of applicable reconciled game transactions
```

Winner contributions are positive and loser contributions are negative. A pair exists once in the ledger even if both sides are relevant locally. Cached totals should be updated incrementally rather than summing the entire ledger whenever the stats UI opens or a message arrives.

### Editable Starting Totals

Import each existing player total once into its local adjustment balance. There is no separate immutable opening-balance field.

Local adjustments are excluded from shared transactions, reconciliation fingerprints, and peer totals. Synchronization must neither overwrite nor broadcast them.

`/sbg stats add` continues to change the local adjustment, including negative values. Two users can intentionally have different totals despite sharing identical game records.

If someone manually credits a missing win and that win is later recovered through reconciliation, both amounts would count. The user must reverse the manual correction, or a separately designed repair action must explicitly link it to a transaction. Do not infer that equal amounts represent the same event.

### Reset And Removal

Preserve the intent of `/sbg stats reset` and `/sbg stats rm`: a subsequent sync must not silently restore what the user cleared. Simply deleting a total or forgetting transaction IDs is insufficient.

These are local operations, not instructions to delete or edit other clients' game records. The exact combination of local time boundaries, eligibility changes, and retained ledger entries needs a decision before implementation. Include behavior when a removed player is later witnessed live again.

Also decide whether manually adding a previously unseen player should ever enable reconciliation for that player. The live-observation requirement must not be bypassed accidentally by the adjustment command.

## One-Time Migration And Time Boundaries

Run an idempotent migration after the existing database is initialized and before live result processing or reconciliation starts:

1. Check the stored schema version.
2. Preserve current totals as editable local adjustments.
3. Seed eligible names from existing stats keys, including names with zero net totals.
4. Record a server-based `migratedAt` timestamp and initialize the transaction store.
5. Mark the migration complete only after the state has been established successfully.

Legacy data does not record how each name was discovered, so using existing stats keys as the seed is an explicit migration assumption.

This records the first initialization of the new system, including an upgrade applied through `/reload`. It is not the filesystem installation time. Since stats are currently per-character, each character receives its own cutoff on first initialization. Ordinary later addon updates must not reset that cutoff or re-import the totals.

Ignore transactions completed before the local migration cutoff, including records forwarded by clients that upgraded earlier. Use the original `completedAt`, not receipt time. A game started before migration but finalized afterward can qualify if it otherwise meets the live-player eligibility rule.

This prevents older records from being added on top of imported totals. It also means pre-migration discrepancies are not automatically repaired; they remain part of each client's editable local adjustment.

Timestamp precision and boundary ordering need explicit treatment. Define same-timestamp behavior and the interaction between legacy result handling, migration, and the new protocol. A timestamp filter alone does not provide duplicate protection.

## Player Eligibility And Selective Import

Maintain an explicit distinction between locally tracked names and names merely present as opponents in transaction metadata.

- Existing names are seeded at migration.
- Future enrollment requires live observation in an SBG game.
- Receiving historical records must never enroll another player.
- Once a player is eligible, their available post-cutoff history can include games the local user did not attend.
- Unrelated random rolls outside an observed SBG game must not populate the tracking set.

The exact live-witness rule still needs to be finalized: accepted roll observations, witnessed session participation, and how to handle a missed final roll/message must be specified consistently for hosts and observers.

The recommended import rule discussed was **known side only**:

- If Glazerbeam is already tracked and a transaction involves an unknown opponent, update Glazerbeam's applicable contribution.
- Retain the opponent as transaction metadata, without adding them to stats or requesting their history.
- Never recursively discover players by following opponents from imported transactions.
- If both sides are already eligible, apply both contributions using the same ledger entry.

Requiring both names to be previously known was presented as an alternative, but it would leave known players' totals incomplete. The known-side-only recommendation was used in subsequent examples; confirm it before implementation.

Partial visibility means a user's displayed player totals do not necessarily sum to zero. That is expected when an unknown counterparty is intentionally excluded.

## Cached Indexes And Fingerprints

Use two related derived structures:

- An index linking player/date buckets to transaction IDs, with full records stored once by ID.
- A cached transaction count and deterministic fingerprint for each bucket, plus an overall player fingerprint built from those bucket summaries.

Use consistent day boundaries, such as UTC days derived from `completedAt`. Fingerprints must describe the same canonically encoded immutable contents in the same deterministic order. Include transaction IDs and relevant contents, not local adjustments, displayed gold totals, arrival order, or local receipt timestamps.

The exact canonical encoding and hash algorithm remain open. Use a suitable proven implementation; do not assume record counts or a simplistic additive checksum establish equality.

### Comparison Example

Illustrative summaries for Glazerbeam:

| Day | Local summary | Peer summary | Next action |
|---|---|---|---|
| September 8 | 3 records, hash A | 4 records, hash B | Investigate this bucket |
| September 9 | 2 records, hash C | 2 records, hash C | Skip this bucket |

The reconciliation sequence is:

1. Compare an eligible player's overall fingerprint for an agreed interval. Matching summaries finish that comparison without sending transaction bodies.
2. For a mismatch, compare daily summaries to identify differing buckets.
3. Exchange transaction IDs for those buckets in bounded pages.
4. Compute missing IDs in either direction and request only the corresponding records.
5. Validate and merge the records once, then refresh the affected caches and totals.

For example, if the local set is `T1, T2, T3` and the peer has `T1, T2, T3, T4`, only `T4` needs to be downloaded as a complete record.

A larger count does not make a peer authoritative. Equal counts can also describe different sets, such as `T1, T2` versus `T1, T3`. Merge missing records in both directions when needed. The same ID with different immutable contents is a conflict to detect and handle, not a second payout or an automatic overwrite.

### Cache Maintenance

- Build indexes and initial fingerprints incrementally at initialization.
- Inserting a new transaction updates its index memberships and applicable totals, and marks only the affected player/day summaries dirty.
- Rebuild dirty fingerprints once after a batch, followed by the affected overall player fingerprints. Reuse every unchanged summary.
- Cache rebuilding, including ordering large buckets, must honor the work budget. Caching does not make the initial build free.
- Refresh the stats UI once per processed batch, rather than for every imported record.

Before comparing, negotiate the same interval using migration, reset, and retained-history boundaries. Whole-day fingerprints can be reused. Boundary days partially inside the interval need filtered summaries.

A peer that has already compacted older records cannot establish whether another client's older history is complete. Consult another source for any still-eligible gaps outside that peer's available interval.

Use a stable upper time bound and a revision/snapshot strategy for a comparison round. Records arriving during pagination must not cause skipped IDs, inconsistent manifests, or endless retries.

## Peer Discovery And Transfers

Begin with small, cached presence/summary announcements, not full transaction inventories or entire SavedVariables tables. Follow up only for the requester's eligible players and history interval.

In a 20-person group:

- One announcement per client means 20 outgoing broadcasts.
- Each client receives the other 19 announcements, or 380 received copies across the raid, excluding self-echoes.
- That is not 380 mandatory full-database reconciliation jobs.
- A logical summary can span multiple packets, and missing records require additional request/response messages.

Caching reduces the cost of each comparison but does not eliminate broadcast fanout. If clients genuinely hold different relevant records, additional data exchange is unavoidable. Do not claim the entire reconciliation always requires exactly 20 messages or that worst-case data delivery is independent of group size.

Select one source for each missing batch to avoid redundant responses. Consult other peers for remaining gaps or failures; one peer is not assumed to hold the complete history. Final peer selection, any coordinator role, and failover behavior are open design choices.

Use targeted addon transfers for historical records. Request only missing records and resume large backlogs in bounded batches. Use an established throttled transport, such as an appropriately embedded AceComm/ChatThrottleLib implementation, and account for other addons' traffic. Do not rely on another installed addon to provide required libraries.

Normal live results should create and distribute their transactions once. Do not initiate a full history exchange for every individual roll. Preserve fast live game handling while background history work is queued.

## Proposed Resource Budgets

These are initial application budgets, not WoW API guarantees or owner-approved final settings.

| Area | Starting proposal |
|---|---|
| Detailed history | Up to 90 days or 10,000 pair transactions per character, whichever limit is reached first |
| One requested batch | At most 100 transactions and 16 KiB of record data, fragmented into valid small messages |
| Historical sending | Approximately 512 bytes/second per client total across peers, before any further transport throttling |
| Concurrency | One incoming and one outgoing history transfer per client |
| Processing | Target at most 0.5 ms of reconciliation work per frame while work is pending |
| UI updates | One refresh per processed batch |
| Scheduling | Debounced checks on group changes and after games; pause bulk reconciliation during combat |

Apply byte limits as well as record-count limits to inventories, requests, responses, and temporary assembly buffers. Specify accounting for protocol overhead, rate-limit bursts, retry limits, timeouts, and queue backpressure during detailed implementation design.

Twenty fully active history senders at the proposed application rate would collectively send about 10 KiB/second. Targeted transfers avoid delivering every historical record to every raid client. Other addon traffic may reduce actual progress.

A missed ordinary Low Pays High game is one pair. A 20-player multi-loser game can be 19 pairs. Large backlogs should take longer to finish rather than increasing the per-frame work or bypassing traffic limits.

### Exploratory Sizing Results

A standalone Lua 5.1 experiment during this discussion built synthetic transaction tables, per-name ID indexes, and totals across 200 synthetic names. Records included IDs, completion time, host, winner, loser, amount, and game mode.

| Records | Ledger and index memory | Uninterrupted construction | Full scan |
|---|---|---|---|
| 1,000 | Approximately 0.63 MiB | 2 ms | Below the measured timer resolution |
| 10,000 | Approximately 6.12 MiB | 19 ms | 1 ms |
| 50,000 | Approximately 29.27 MiB | 105 ms | 11 ms |

The sampled text encoding was approximately 120 bytes per transaction. At 512 bytes/second, 100 missing records would take roughly 24 seconds to transfer before protocol overhead, competing traffic, or retries.

These measurements are illustrative, not an implemented-addon benchmark or an in-game FPS measurement. They exclude the finished protocol, all summary caches, UI work, and WoW's SavedVariables load behavior. They demonstrate why uninterrupted large rebuilds and unlimited history transfers are inappropriate.

The local Blizzard API export inspected was Retail 12.1.0.69497; the supplemental runtime inventory reported 12.1.0.69587. Treat exact transport behavior as requiring current-build and in-game validation before implementation.

## Retention And Compaction

The recommended starting policy was up to 90 days and 10,000 pairs per character. Alternatives discussed were one year/50,000 pairs or retaining all transactions since migration. No retention option has been explicitly selected.

With bounded retention:

1. Calculate the already-counted contributions of records leaving the retained window.
2. Fold those contributions into the relevant editable local adjustments, preserving displayed totals.
3. Advance a persistent compaction/history boundary and remove the expired detailed records.
4. Ensure future reconciliation excludes those records so they cannot be imported and counted again.

Compaction must be idempotent and respect local eligibility and reset/removal boundaries. Updating adjustments and the replay boundary must form one consistent operation. Do not simply delete old IDs and leave their transactions eligible for import.

If a record-count cap forces the window forward sooner than the age limit, advertise that narrower available interval. Define a safe rule for records sharing the boundary timestamp; arbitrarily discarding part of a timestamp group without corresponding replay protection is insufficient.

Lifetime totals remain available and editable, but detailed recovery is limited to the retained interval. Missing games older than a client's effective cutoff cannot be repaired automatically through this design, even if another peer still holds those records.

## Compatibility And Failure Handling

- Version the transactional protocol independently enough to detect incompatible peers.
- Updated hosts must generate stable IDs and retain original `completedAt` values. Forwarding peers preserve the record's identity and origin.
- Decide how mixed old/new addon versions behave. Existing `RESULT` messages have no stable event identity, so they cannot automatically provide the same reconciliation guarantees.
- A compatibility path must prevent counting both a legacy result and its transactional equivalent. Do not assume dual broadcasting is safe without an explicit rule.
- Validate senders, expected sessions or sync requests, player identities, amounts, time ranges, and message sizes before accepting data. Forwarded historical records require a clearly stated trust model.
- Duplicate delivery and retry must be harmless. Conflicting contents for one ID must not silently alter existing payouts.
- Handle disconnects, group changes, throttling, partial messages, timeouts, and donor failover with bounded queues and retries.
- Remote data must not change local adjustments, migration timestamps, tracking eligibility, or reset decisions.

## Decisions To Resolve Before Implementation

- Confirm known-side-only import versus requiring both endpoints to be known.
- Define exactly what live evidence enrolls a player, including late joins, missed roll messages, and manual additions of unseen names.
- Select retention duration and record cap, including whether users can configure them.
- Define reset/removal behavior, later live rediscovery, and applicable per-player history boundaries.
- Choose stable game/transaction ID generation, canonical field encoding, and fingerprint implementation.
- Specify timestamp precision, same-timestamp migration/compaction boundaries, and clock-related validation.
- Decide mixed-version support and the minimum updated-peer/host requirements for reconciliation.
- Finalize peer/source selection, optional coordination, fixed comparison windows, and pagination consistency.
- Specify exact traffic accounting, buffer limits, scheduling delays, retry/backoff behavior, and conflict diagnostics.

## Suggested Implementation Sequence

Only begin after the owner explicitly chooses to add this complexity.

1. Resolve the open decisions and formalize the storage and protocol contracts.
2. Implement the local ledger, editable adjustments, idempotent migration, and projections while preserving current stats behavior.
3. Integrate host-generated result IDs, `completedAt`, live-name eligibility, and duplicate-safe receipt.
4. Add indexes, cached fingerprints, bounded discovery, missing-ID comparison, and targeted record transfer.
5. Implement compaction and local reset/removal behavior, then complete compatibility and failure handling.
6. Validate correctness and performance with multiple clients, update player documentation and the development changelog, and prepare a release only when requested.

Expected ownership: local data and projections in the stats subsystem, scoring integration in the session subsystem, migration at initialization, and a focused reconciliation module for the new protocol and scheduling. Avoid expanding the existing session file into a general history engine.

## Validation Scenarios

- Migration preserves every existing total and runs once across login, reload, later versions, and different characters.
- Imported balances and later positive/negative adjustments remain editable and are never shared.
- Transactions before the effective cutoff are ignored; original `completedAt` survives forwarding. Test games spanning migration and exact timestamp boundaries.
- Repeated results, retries, and the same transaction received from several peers count once. Separate games with identical names and amounts remain distinct transactions.
- Existing stats names are seeded correctly; unseen opponents stay metadata. Receiving records cannot recursively expand tracking.
- Cover newly observed players, zero-net players, full realm names, and consistent canonicalization.
- Verify all game modes, one pair versus multiple losers, cancelled/unscored outcomes, and existing guild-cut accounting.
- Equal fingerprints send no transaction bodies. Equal counts with different IDs still reconcile. Two clients with disjoint missing records both recover the applicable union.
- Date-window differences and partial boundary days do not create false matches or endless mismatch loops. Peers advertise genuinely available history.
- Transactions arriving during pagination, interrupted batches, changed peers, and duplicate requests neither skip nor double-apply records.
- Resets, removals, and compaction preserve their intended local effects across reload and later synchronization.
- Validate old/new version combinations and conflicting or malformed records without assuming every peer's data is authoritative.
- Simulate 20 and 40 clients with identical histories, overlapping histories, mostly unrelated names, and large eligible backlogs.
- Measure bytes/messages, duplicate responses, queue sizes, progress, memory, and time per processing slice at 1,000, 10,000, and 50,000 records.
- Confirm UI refresh batching, combat pauses, bounded retry/backoff, and stable memory through repeated group joins and sync rounds.
- Complete real multi-client in-game validation with other raid addons active before claiming the resource budgets are proven.

Until this direction is explicitly approved, this document is the only planned feature artifact. No transaction system, migration, reconciliation, or runtime complexity should be added as a consequence of recording it.
