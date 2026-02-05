# BeamMP Tag Mod

BeamMP-Tag is a team-focused variant of the Outbreak mod. It replaces the infection terminology with a color-based tagging experience (red/blue/purple/white/green/yellow) and exposes a `/tag` command suite for managing rounds, teams, and visual effects.

## Highlights
- Team-colored nametags and postFX per role.
- `/tag` chat commands to start/stop/reset rounds, tweak vignette strength, and adjust team settings.
- Configurable per-team colors (red & blue by default, now extended to yellow and purple).
- Server-driven state sync via the `outbreak_*`/now `tag_*` events so clients know their teammates.

## Setup
1. Place the `Client/` and `Server/` folders into your BeamMP mod install directory.
2. Start BeamMP with the `tag.lua` extension enabled.
3. Run the `Server/Tag/main.lua` script on your BeamMP server to register the `/tag` commands and game logic.

## Commands
All commands now use the `/tag` prefix. Examples:
- `/tag start` – Start a tagging round. Add an optional duration in minutes.
- `/tag stop` – End the current round.
- `/tag reset` – Reset player weights.
- `/tag set teams <count>` – (Upcoming) configure how many color teams play.
- `/tag set greenFadeDist <m>` – Adjust how close players need to be before a tint starts.
- `/tag <command> help` – Show available commands and descriptions.
