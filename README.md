# BeamMP Tag Mod

BeamMP-Tag is a tag/infection-style multiplayer mode with server-authoritative rounds, team state sync, and client-side color/vignette feedback.
<img width="2560" height="1440" alt="screenshot_2026-02-05_12-55-50" src="https://github.com/user-attachments/assets/ab0dafd6-a207-46c2-b4b4-9bf23fa42d97" />
<img width="2560" height="1440" alt="screenshot_2026-02-05_12-56-02" src="https://github.com/user-attachments/assets/00dfffd6-373b-4974-acca-bb2e43d35dfb" />
<img width="2560" height="1440" alt="screenshot_2026-02-12_13-13-04" src="https://github.com/user-attachments/assets/3319febe-9f19-4dd3-9df9-5a1b07fa6a26" />
<img width="2560" height="1440" alt="screenshot_2026-02-12_13-13-14" src="https://github.com/user-attachments/assets/2b89bddb-a4d7-4eed-a6db-43002d8835ac" />




## Features
- Server-managed round lifecycle (`start`, `stop`, timer, win/end states)
- Tagged vs survivor state with synchronized client updates
- Distance-based vignette feedback and vehicle tinting
- Reset-at-speed restrictions (configurable)
- Weighted first-tagger randomization when nobody is tagged at round start
- Multiteam support (red/blue/purple/white/green/yellow)
- Team-aware visuals (car tint, vignette, and nametag colors)
- Countdown-safe visuals: team tinting starts after initial tagger selection

### Installation

1. **Download the release**

   * Go to the **Releases** page.
   * Download the latest `.zip` file.

2. **Extract the files**

   * Unzip the download.
   * You will get two folders:

     * `Client`
     * `Server`

3. **Install the client files**

   * Open the extracted **Client** folder.
   * Inside it is a `.zip` file.
   * Upload that `.zip` into your server’s **client mods folder**.

4. **Install the server files**

   * Open the extracted **Server** folder.
   * Inside is a folder for the game mode (e.g. `CarHunt`, `Tag`, `PropHunt` etc.).
   * On your server, open the main **server folder**.
   * Create a folder for that game mode (for example: `CarHunt`, `Tag`, `PropHunt`).
   * Copy **all files** from the extracted game mode folder into the matching folder you just created on the server.

5. **Restart the server**

   * Restart your BeamMP server.
   * The game mode should now be active.

---

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
