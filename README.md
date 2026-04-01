# /break Gambling

A World of Warcraft addon for running gold gambling games during raid breaks. Supports multiple game modes, syncs state across all players who have the addon installed, and provides a lightweight UI for the session leader to manage games.

---

## Getting Started

Open the addon window with:

```
/sbg show  (or /sbg s)
```

or left click the minimap button to open.

All of the above toggle the window open or closed. Your window position and whether it was open are saved between sessions.

---

## The UI

The window has the following sections from top to bottom:

**Game Mode selector** — A dropdown listing all available game modes. Hover any mode to see a tooltip describing how it works. Only changeable while no game is in progress.

**Gold Amount slider** — Sets the gold stake for the next game. Use the **Use Token Price** button (visible below the game button when idle) to automatically set the amount to the current WoW Token market price.

**Game button** — Drives the session through its states:
- **Start Game** — Opens entries and announces the game in party/raid chat
- **Last Call** — Warns players this is their last chance to join
- **Close Entries** — Locks the player list and prompts rolling
- **End Game** — Ends the session and announces results

Only the session leader can click the game button. If you end a game while players haven't rolled yet, a confirmation dialog appears.

**Join Game / Leave Game button** — Visible to all players (including non-leaders) while entries are open. Sends `1` or `-1` to chat on your behalf.

**Request Rolls button** — Visible to the leader during the rolling phase. Announces in chat who still needs to roll (or whose turn it is for turn-based modes).

**Roll for Me button** — Visible when it's your turn to roll. Fires `/roll` automatically with the correct number.

**Toggle Player List button** — Shows or hides the player list panel, which displays each player, their class color, and their roll result.

**Stats button** — Shows or hides the statistics panel, which displays the top 10 winners and top 10 losers with their net gold. Includes buttons to report stats to party/raid chat.

---

## How a Game Works

1. The leader configures the **gold amount** and **game mode**, then clicks **Start Game**.
2. An announcement is sent to party/raid chat. Players type `1` to join or `-1` to leave.
3. The leader clicks **Last Call**, then **Close Entries** when ready.
4. Players roll using `/roll` (or click **Roll for Me**).
5. Results are calculated and announced automatically when all rolls are in.
6. Click **End Game** to wrap up and clear the session.

**The addon is not required to participate.** Any player can join or leave a game by simply typing `1` or `-1` in party/raid chat, and roll normally with `/roll` when prompted. The addon just provides a UI on top of that chat interface.

Players who also have the addon installed will additionally see live updates in the player list and have access to the **Join/Leave** and **Roll for Me** buttons.

### Auto-open on break timer

If Deadly Boss Mods (DBM) is installed and the raid leader starts a break timer, the addon window will open automatically. It will close automatically when an encounter starts.

---

## Game Modes

### Low Pays High (Diff)
Everyone rolls once. The lowest roller pays the highest roller the **difference** between their two rolls in gold.

*Example: High rolls 847,000 and Low rolls 124,000 → Low pays 723,000g*

### Low Pays High (Total)
Everyone rolls once. The lowest roller pays the highest roller the full **gold amount** set on the slider.

*Example: Gold set to 500,000g → Low roller pays 500,000g*

### Death Roll (1v1)
Two players only. Players take turns rolling. Each roll sets the new maximum for the next roll. The first player to roll **1** loses and pays the other player the full gold amount.

*Example: Start at 500,000 → Player A rolls 312,847 → Player B rolls 64,203 → Player A rolls 1 → Player A pays 500,000g*

### Death Roll (Round Robin)
Any number of players. Same death roll mechanic, but players take turns in the order they joined. Rolling **1** eliminates you from the round. The last player standing wins — all eliminated players each pay the winner the full gold amount.

*Example: 4 players at 100,000g → last player standing collects 300,000g total (100,000g × 3 losers)*

### Last Man Standing
Any number of players. Everyone rolls the same amount simultaneously each round. The player(s) with the lowest roll are eliminated. Rounds continue until one player remains. All eliminated players each pay the winner the full gold amount.

Ties on the lowest roll eliminate all tied players in the same round.

*Example: 5 players at 50,000g → last player standing collects 200,000g total (50,000g × 4 losers)*

---

## Multi-Client Sync

The addon uses addon messages to keep all installed clients in sync. Non-leaders automatically:
- See the player list update as players join and leave
- Receive turn announcements and elimination messages
- Have access to **Join/Leave** and **Roll for Me** at the appropriate times

Only the session leader drives game logic and makes announcements to chat.

---

## Stats Tracking

The addon automatically tracks each player's net gold won or lost across all games. Stats are stored per-character and updated for all addon users when a game ends.

- Click **Show Stats** to view the top 10 winners and losers
- Use **Report Top 3** to announce the top 3 winners and losers to chat (one line each)
- Use **Report All** to send all stats to chat in batched messages

Stats can also be managed via slash commands (see below).

---

## Commands

| Command | Description |
|---|---|
| `/sbg show` | Toggle the window |
| `/sbg s` | Toggle the window |
| `/sbg open` / `/sbg o` | Toggle the window |
| `/sbg hide` / `/sbg h` | Toggle the window |
| `/sbg stats` | Print all stats to local chat |
| `/sbg stats <name>` | Look up a specific player's stats |
| `/sbg stats add <name> <amount>` | Adjust a player's net gold |
| `/sbg stats rm <name>` | Remove a player from stats |
| `/sbg stats reset` | Reset all stats (with confirmation) |

Player names can be entered as `Name-Realm` or just `Name` (defaults to your realm). Lookups are case-insensitive.
