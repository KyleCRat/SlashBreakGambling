# Saved Data Migrations

Migrations run during addon initialization, immediately after AceDB is created
and before slash commands, events, or UI modules are enabled. Each character has
its own `db.acedb.char.migrationVersion`, so characters migrate on their first
login with the updated addon. An absent marker means version `0`.

## Sequence

1. `001_NormalizeStatNames.lua`: normalize saved stat keys to `Name-Realm`,
   removing spaces and hyphens from the realm while preserving each balance.
   Different realms remain separate. No GUIDs or shared history are introduced.

## Adding a Migration

1. Add the next numbered file, such as `002_DescribeChange.lua`.
2. Register it with `addon:RegisterMigration(2, function(char) ... end)`.
3. Add it to `SlashBreakGambling.toc` after the previous numbered migration.

Keep released migrations unchanged. Registration requires consecutive versions
starting at `1`. New characters also run the sequence, so migrations must handle
absent optional data. The version advances only after a migration succeeds.

Make migrations safe to retry. Build replacement tables before assigning them,
preserve unrelated data, and keep conversion rules in the migration rather than
depending on helpers that may change in future releases. Migration `001` rejects
conflicting destination keys without overwriting the original stats or merging
balances. A migration error stops addon startup and leaves that version pending.
