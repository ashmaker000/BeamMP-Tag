# BeamMP Tag Mod
<img width="2560" height="1440" alt="screenshot_2026-02-05_12-55-50" src="https://github.com/user-attachments/assets/e349c6ac-7763-4237-9360-4276fd9c722c" />
<img width="2560" height="1440" alt="screenshot_2026-02-05_12-56-02" src="https://github.com/user-attachments/assets/867f611b-9bb2-4102-a332-821839712456" />


BeamMP-Tag is a team-focused variant of the BeamMP-Outbreak mod BY Olrosse. It replaces the infection terminology with a color-based tagging experience (red/blue) and exposes a `/tag` command suite for managing rounds, teams, and visual effects.

## Highlights
- Team-colored nametags and postFX per role.
- `/tag` chat commands to start/stop/reset rounds, tweak vignette strength, and adjust team settings.
- Configurable per-team colors (red & blue by default, now extended to yellow and purple).
- Server-driven state sync via the `tag_*` events so clients know their teammates.

## Setup
1. Place the `BeamMP-Tag.zip` in your Clients folder and create a folder called `Tag` and add `main.lua` into your new folder.
2. Start a round by using `/tag start` in the chat box.
3. After a few seconds the round will start and the person being Tag will turn to Red and will need to tag every one in Blue.

## Commands
All commands now use the `/tag` prefix. Examples:
- `/tag start` – Start a tagging round. Add an optional duration in minutes.
- `/tag stop` – End the current round.
- `/tag reset` – Reset player weights.
- `/tag <command> help` – Show available commands and descriptions.

Credit to [Olrosse](https://github.com/Olrosse),
