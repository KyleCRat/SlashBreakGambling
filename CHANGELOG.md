# Changelog

## [Unreleased]

### Added

- Losing players get a separate, movable payment reminder, even when the main window is hidden. Losses append to a scrollable list that persists across games and reloads until dismissed with X.

### Fixed

- Ending an unfinished game now cancels it without scoring or creating payment reminders.
- Active sessions clear when their leader leaves the group, but not merely when the leader goes offline.
- All game modes require at least two participants before rolling can start.
- Player matching retains realm names and no longer assigns ambiguous short-name rolls to the first matching participant.
- Existing stats automatically migrate to normalized player names on each character's first login after updating, preserving balances and keeping different realms separate.
- Last Man Standing followers can roll again in the next round instead of retaining the previous round's last roll.
- Automatic hiding on encounter start continues working after games end.
- Reopening the game-mode menu reuses its rows instead of accumulating hidden frames.
- Fixed startup and `/sbg` failing when no other addon supplied a required library.
- Followers now see who owes whom at game end. When the leader is also updated, any guild payment appears on a separate line in the results and payment reminder.
- Long loser lists are split into smaller messages so payment results and announcements fit the chat limits.

## [12.1.5-11] - 2026-10-06

- Updated for WoW 12.1.5.

- `/sbg` now toggles the window; use `/sbg help` or `/sbg h` for command help.
