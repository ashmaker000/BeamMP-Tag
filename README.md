# BeamMP Tag Mod

BeamMP-Tag is a tag/infection-style multiplayer mode with server-authoritative rounds, team state sync, and client-side color/vignette feedback.

## Features
- Server-managed round lifecycle (`start`, `stop`, timer, win/end states)
- Tagged vs survivor state with synchronized client updates
- Distance-based vignette feedback and vehicle tinting
- Reset-at-speed restrictions (configurable)
- Weighted first-tagger randomization when nobody is tagged at round start
- Multiteam support (red/blue/purple/white/green/yellow)
- Team-aware visuals (car tint, vignette, and nametag colors)
- Countdown-safe visuals: team tinting starts after initial tagger selection

## Setup
1. Unpack `BeamMP-Tag.zip` and your see `Client` and `Server` folders
2. Go into `Client folder` place the `BeamMP-Tag.zip` in your Clients folder, then head to `Server folder` and create a folder called `Tag` and add `main.lua` into your new folder.
3. Start a round by using `/tag start` in the chat box.
4. After a few seconds the round will start and the person being Tag will turn to Red and will need to tag every one in Blue.

## Commands
Use `/tag ...`.

### Core
- `/tag help`
- `/tag status`
- `/tag start [minutes]`
- `/tag stop`
- `/tag reset`

### Settings
- `/tag set mode classic|multiteam`
- `/tag set teamCount <2..6>`
- `/tag set taggers <count>`
- `/tag set winCondition classic|lastteam`
- `/tag set gameLength <minutes>`
- `/tag set greenFadeDist <meters>`
- `/tag set filterIntensity <0..1>`
- `/tag set maxResetSpeed <speed>`
- `/tag toggle colorPulse`
- `/tag toggle taggerTint`
- `/tag toggle resetAtSpeedAllowed`

### Team/tagger management
- `/tag teams random`
- `/tag teams set <username> <color>`
- `/tag teams clear <username>`
- `/tag teams list`
- `/tag taggers add <username>`
- `/tag taggers remove <username>`
- `/tag taggers clear`
- `/tag taggers list`

### Legacy aliases (still supported)
- `/tag game length set <minutes>`
- `/tag greenFadeDist set <meters>`
- `/tag filterIntensity set <0..1>`
- `/tag MaxResetSpeed set <speed>`
- `/tag ColorPulse toggle`
- `/tag tagger tint toggle`
- `/tag ResetAtSpeedAllowed toggle`

## Notes
- Defaults are now tuned for multiteam:
  - `mode=multiteam`
  - `teamCount=6` (all team colors enabled)
- `classic` mode uses tagged/non-tagged infection behavior.
- `multiteam` includes server-side assignment + client-side team color visuals.
- `winCondition=lastteam` ends the round when one survivor team remains.
- `/tag teams random` clears manual assignments and auto-balances across all enabled colors.
- `/tag teams set <username> <color>` auto-expands `teamCount` when needed so requested colors are active.
- Team color visuals are delayed until the initial tagger is chosen (not during countdown).
