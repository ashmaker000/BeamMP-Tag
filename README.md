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

## Install
1. Put `Client/` and `Server/` into your BeamMP mod setup.
2. Ensure the server runs `Server/Tag/main.lua`.
3. Ensure the client package includes `scripts/tag/modScript.lua` at ZIP root.
   - This loads `tag` + `vignetteShaderAPI` early so rounds do not miss startup events.

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
