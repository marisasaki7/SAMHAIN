# Light.vn Engine Manual

> For detailed per-command documentation, see `Commands.xml` in this folder.

## Engine Overview

- Light.vn is a visual novel game engine
- Games are built by writing plain-text script files
- Scripts execute line-by-line, top to bottom
- Each line is either a **command** or a **dialogue line**
- The engine handles rendering, audio, input, save/load, and UI automatically

### Project Structure
```
ProjectFolder/
├── settings.xml          ← project configuration (resolution, entry script, etc.)
├── Config/               ← engine config files (Commands.xml, etc.)
├── Scripts/              ← script files (.txt)
├── Images/               ← image files (png, jpg, etc.)
├── BGM/                  ← background music files
├── SFX/                  ← sound effect files
├── Voices/               ← voice files
├── Fonts/                ← font files (ttf, otf)
├── Movies/               ← video files (mpg, webm)
├── Models/               ← 3D model files (glb)
├── Maps/                 ← tilemap files
├── Shaders/              ← shader files
├── SaveData/             ← save files (auto-managed)
└── Screenshots/          ← screenshots (auto-managed)
```

### settings.xml
Key attributes in `<Settings>`:
- `Width`, `Height` — project resolution
- `InitialScript` — entry point script file (e.g. `"init.txt"`)
- `NovelTitle` — window title
- `ApplicationSize` — `"Window"` or `"Fullscreen"`

## Quick Start

A minimal working game: background, character, dialogue, and a choice.

```
// init.txt
textbox main_box 0 400 81 800 200 myfont.ttf 24
useTextbox main_box

bg scene park.png
cg alice alice_smile.png 400 100 50

"Hello! Welcome to Light.vn.
"Would you like to continue?
~

button0 choice_yes btn.png btn_t.png btn_c.png 300 300 90 "var answer = 1"
button0 choice_no  btn.png btn_t.png btn_c.png 500 300 90 "var answer = 2"
btnText choice_yes myfont.ttf 20 "Yes"
btnText choice_no  myfont.ttf 20 "No"
fadein choice_yes, choice_no 200
setButtonGroup choice_

wait buttonSelect choice_

if (answer == 1) {
  "Great, let's go!
  ~wait
} else {
  "Maybe next time.
  ~wait
}
```

## Script Language

### Line Processing Order
Each line is processed through these steps in order:
1. Macro expansion
2. `{{ }}` variable interpolation
3. `( )` expression evaluation
4. Execute as command

### Commands
- Format: `command_name param1 param2 param3`
- Parameters are space-separated
- String parameters containing spaces must be quoted: `"hello world"`
- `[param]` = required, `(param)` = optional
- Multiple commands on one line: separate with `|`
  - e.g. `cg alice alice.png 100 200 50 | cg bob bob.png 500 200 50`

### Dialogue Lines
- New dialogue line: `"This is dialogue text`
  - Starts with `"` (double quote) — displays text in the active textbox (waits for input depending on `textAutoWait` setting)
- Continue on same line: `-"more text on same line`
  - Starts with `-"` — appends to current text without clearing

### Command Block (`~`)
- `~` signals that the line (or following lines) should be parsed as commands, not dialogue text
- After a `"` dialogue line, subsequent lines are still in text context — use `~` to return to command mode
- Can be used standalone or as a prefix to a command:
  ```
  "Hello, how are you?
  ~
  fadeout alice 500
  ```
  ```
  "Hello, how are you?
  ~fadeout alice 500
  ```

### Variable Interpolation
- `{{ variable_name }}` — replaced with the variable's value before the line executes
- If the value is a string, outer quotes are stripped (designed for use inside dialogue)
- If the value is a number with no fractional part, displayed as integer (e.g. `5` not `5.000000`)

### Expression Evaluation
- `( expression )` — evaluated as a math/function expression
- Unlike `{{ }}`, string results keep their quotes
- Supports arithmetic: `+`, `-`, `*`, `/`, `%`
- Supports comparisons: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Supports logic: `&&`, `||`, `!`
- Function calls: `(lvRandom(1, 10))`, `(lvMath::sin(3.14))`

### Comments
- Single-line: `// comment text`
- Multi-line: `/*` on its own line to start, `*/` on its own line to end

## Variables

### Types
- **Number** — floating-point (e.g. `42`, `3.14`)
- **String** — text (e.g. `"hello"`)
- **Boolean** — `true` / `false`
- **List** — ordered collection
- **HashMap** — key-value map

### Scopes
| Command | Scope | Saved? | Lifetime |
|---------|-------|--------|----------|
| `var` | Temp Local | No | Current script only |
| `temp_globalvar` | Temp Global | No | Until game closes |
| `datavar` | Data | Yes (per save slot) | Persists in save file |
| `globalvar` | Global | Yes (shared) | Persists across all saves |
| `systemvar` | System | Yes (settings) | Modify existing system vars only |

System variables (`vn_sys*`) are pre-defined — use `systemvar` to modify them.

### Setting Variables
```
var myvar = 10
var mystr = "hello"
var mybool = true
temp_globalvar shared_val = 5
datavar progress = 1
globalvar endings_seen = 0
systemvar vn_sysTextSpeed = 50
```

### Operators
- Assignment: `=`
- Arithmetic: `+=`, `-=`, `*=`, `/=`
- Comparison (in expressions): `==`, `!=`, `<`, `>`, `<=`, `>=`

### Reading Variables
- In expressions: `(myvar + 10)`
- In dialogue/commands: `{{ myvar }}`
- In conditions: `if (myvar == 10)`

## Control Flow

### Conditionals

**Single-line** (command on same line):
```
if (condition) command (else) (command)
```
- `if (answer == 2) jump reached else jump not_reached`

**Multi-line** (brace blocks):
```
if (myvar == 1) {
  "You chose option 1.
  ~wait
} elseif (myvar == 2) {
  "You chose option 2.
  ~wait
} else {
  "You chose something else.
  ~wait
}
```

### Loops
- `while (condition) { ... }` — repeatedly executes the block while condition is true
  - Use `break` to exit early
```
var i = 0
while (i < 5) {
  ~cg0 card_{{i}} card.png ((i * 200) + 100) 100 50
  ~var i += 1
}
```

### Bookmarks & Jumps
- `bookmark my_label` — define a jump target
- `jump my_label` — jump to bookmark (same script)
- `jump filename.txt` — jump to another script file (replaces current script, does not return)

### Subscripts
- `script filename.txt` — run another script file (pauses current, resumes when subscript finishes)
- `parallel_script filename.txt` — run script in parallel (does not pause current)
- `script_fin` — end current subscript, return to parent script
- `endGame` — terminate the application (use on the main script to end the game)

### Waiting
- `wait` — wait for player click
- `wait 1500` — wait 1500 ms
- `wait tween_finish object_name` — wait for tween to complete
- `wait buttonSelect [prefix]` — wait for a button click
- `wait textDisplayFin` — wait for text to finish displaying
- `wait animation_finish object_name` — wait for sprite animation
- `wait movieFin` — wait for video to finish
- `wait preventContinueRead` — halt script; only `jump` can resume (use for menus where only buttons should advance)

### Screenspaces
- `screenSpaceStart name` — create an isolated rendering/input context (for menus, overlays)
- `screenSpaceFin name` — close and destroy the screenspace
- Objects in a screenspace don't interfere with the main game context

### Macros

**String Macros:**
- `macro [pattern] [replacement]` — regex text replacement applied before variable interpolation
  - `macro "~fadein_all" "~fadein card1 300 | fadein card2 300"`

**Command Macros:**
- `commandMacro [source] [replacement]` — when source appears at start of a line, replaced and executed
  - `commandMacro "show_menu" "script ui/menu.txt"`
  - No regex support (exact match only)

## Objects

### Creating Objects
- Objects are created via commands: `cg`, `bg`, `textbox`, `button`, `text`, `bgm`, `soundEffect`, etc.
- Every object has a unique name (first parameter after command)
- Example: `cg alice alice_smile.png 400 100 50` — creates image "alice" from file, at position (400, 100), r 50
- Adding `0` after a creation command (e.g. `cg0`, `textbox0`) creates the object with alpha = 0 (invisible) — useful for fading in after creation

### Destroying Objects
- `fadeout object_name (duration_ms)` — fades out and removes an object
  - e.g. `fadeout alice 500` — fades alice out over 500ms, then destroys
  - e.g. `fadeout alice` — destroys instantly (no fade)
  - Supports regex: `fadeout btn.*` — removes all objects matching pattern
- `fadeout type_name` — removes all objects of a given type (e.g. `fadeout cg`)
- `clear` — removes all objects and resets camera/key triggers

### Object Types
**Graphics:**
- `cg` — character/sprite image
- `bg` — background image (auto-stretched to fill screen)
- `ninecg` — nine-slice scalable image
- `spine_cg` — Spine animation
- `flow_cg` — scrolling/flowing image
- `empty` — invisible object (used as parent for grouping)
- `particle` — particle effect (via `particleMaker`)
- `model` — 3D model (GLTF)
- `tilemap` — tile-based map
- `light` — light source
- `sky` — skybox

**UI:**
- `textbox` — dialogue/message box (flowing text)
- `text` — static text label (no flow)
- `button` — clickable button
- `trackbar` — slider control

**Audio:**
- `bgm` — background music
- `voice` — character voice
- `soundEffect` — sound effect
- `sound_cg` — visual with synchronized sound

**System Singletons:**
- Camera, Backlog, Mouse Cursor — managed automatically

### Coordinate System

- **Origin**: top-left corner of the screen
- **X axis**: increases to the right
- **Y axis**: increases downward
- **R axis (layer)**: higher = in front, z = r * 100
- **Scale**: `100%` = original size
- **Rotation**: degrees, clockwise positive
- **Pivot/Origin point**: `(0,0)` = top-left of object, `(1,1)` = bottom-right, `(0.5, 0.5)` = centre

### R (Layer) System

- Every object has an `r` value (layer): higher = in front, z = r * 100
- `r` is a float value
- `on_camera` option: attaches object to camera so it's unaffected by camera movement
  - Useful for UI elements that should stay fixed on screen

### Changing an Object's Image
- `image alice alice_happy.png` — swaps the image/animation of an existing object without recreating it
- Optional transition: `image alice alice_happy.png 500` — crossfade over 500ms

### Parent-Child Relationships
- `parentChild parent child1 child2 ...` — children become positioned relative to parent's top-left
- `parentChild2 parent child1 child2 ...` — children become positioned relative to parent's center
- Each child's transform follows the parent: when the parent moves, children move with it
- **Collision behaviour with `preventEntry`**: the parent-child link is a *transform* relationship only.
  - The parent's own movement is NOT blocked by a parent-child child's `preventEntry` collider.
  - Instead, the child receives a per-frame local displacement that keeps its world position out of any `preventEntry` overlap. The parent moves freely; the child holds at the obstacle.
  - This matches the conventional "kinematic body as child of transform-driven parent" pattern from mainstream physics engines.
  - For colliders that *should* constrain the parent (e.g. an additional preventEntry shape that belongs to the parent's own body), add them directly to the parent via `衝突範囲方形追加` / `addColliderRect` rather than via a parent-child link.

## Text & Dialogue

### Textbox Setup
```
textbox my_textbox 0 400 81 800 200 myfont.ttf 24
useTextbox my_textbox
```
- Creates a textbox at (0, 400), r 81, size 800x200, font size 24
- `useTextbox` sets it as the active textbox for dialogue lines

### Displaying Dialogue
```
"Hello, how are you?
"I'm doing well, thanks.
-" And you?
```
- `"` starts a new line (clears previous text, displays new text)
- `-"` continues on the same display (appends without clearing)

### Text Flow
- Text is revealed character-by-character at the speed set by `vn_sysTextSpeed` (ms per letter)
- Player can click to instantly show all text

### Escape Sequences (in dialogue lines)
- `\n` — newline
- `\w` — force wait after this line (triggers a wait for player input, regardless of `textAutoWait` setting)
- `\c` — suppress auto-wait for this line (prevents `textAutoWait` from triggering even if enabled)
- `\\` — literal backslash
- `\<` / `\>` — literal `<` / `>` (prevents interpretation as text decoration tags)
- Leading `.` characters at the start of a dialogue line are converted to `\n` (shorthand for newlines)

### Waiting for Player Input

**`textAutoWait` command** — controls when the engine automatically waits for player input during dialogue:
- `textAutoWait 0` — disabled (no auto-wait; use `\w` or explicit `wait` commands)
- `textAutoWait 1` — wait after every dialogue line
- `textAutoWait 2` — wait on blank dialogue lines only (consecutive blank lines trigger only one wait)
- Default can be set in `settings.xml` via `TextAutoWaitMethodDefault`

**`textOverflowAutoWait`** — automatic pagination:
- `textOverflowAutoWait true` (default) — when text overflows the textbox, the engine displays as much as fits, waits for player input, then continues with the remaining text
- `textOverflowAutoWait false` — overflow text is not auto-paginated

**`continueRead` command** — resumes script after a wait:
- If text is still flowing: instantly displays all remaining text
- If text is finished: resumes script reading (advances past the wait)
- Typically triggered automatically by player click/input
- Can be called explicitly from button commands or key triggers

See also: `wait` in [Control Flow > Waiting](#waiting) for all `wait` forms.

### Auto Mode
- Enabled via `vn_sysTextAutoOn = true`
- Text advances automatically after display completes
- Speed controlled by `vn_sysAutoSpeed` (ms per letter for flow) and `vn_sysAutoWait` (ms to wait after text finishes)

### Skip Mode
- Enabled via `vn_sysTextSkipOn = true`
- By default, displays all text instantly (when `vn_sysSkipSpeed = 0`)
- If `vn_sysSkipSpeed > 0`, text flows at that speed instead of instant
- Wait commands resolve instantly, tweens jump to destination, sounds are muted

### Text Decoration (Inline Formatting)
- Wrap text in `<command>styled text</>`
- Multiple decorations separated by `|`: `<textSize 20 | textColour 255 0 0>red big text</>`
- Available decorations:
  - `textSize size` — change font size
  - `textColour r g b` — change text colour
  - `textFont fontfile.ttf` — change font
  - `textShadow ...` — add text shadow
  - `ruby annotation` — add ruby/furigana text above
  - `rubyAt distance (start_offset)` — position ruby text
  - `rubyFont fontfile.ttf` — set ruby font

### Speaker Names
- `backlogCurSpeaker "Name\n"` — sets the current speaker name for backlog entries
- Speaker names are typically displayed via a separate `text` object that you update before each dialogue line

### Textbox Skin
- `textboxSkin skin.png 300 400` — attaches a background image to the active textbox
- `textboxSkin fadeout` — removes the textbox skin
- Creates a child object named `[textbox]_skin` that can be further tweened

### Static Text
- `text` command creates non-flowing text (all text appears at once)
- Use for labels, UI text, etc.

## Audio

### Background Music
```
bgm song.ogg repeat
```
- `repeat` is optional — loops the track
- Only one BGM plays at a time; playing a new one replaces the current
- Cross-fade pattern:
  ```
  nameChange bgm bgm_fade | fadeout bgm_fade 800
  bgm0 new_song.ogg | fadein bgm 800
  ```

### Sound Effects
```
soundEffect roar roar.ogg
soundEffect click click.ogg repeat
```

### Voice
```
voice voice ep0-3.ogg
```
- Optional: bind to a volume variable: `voice voice ep0-3.ogg char_vol char_vol_on`

### Volume Control
- Use system variables: `vn_sysMasterVolume`, `vn_sysBgmVolume`, `vn_sysSfxVolume`, `vn_sysVoiceVolume`
- Tween volume: `volume bgm 50 1000` — fade BGM to 50% over 1 second

## Tween / Animation

### Basic Usage
Each tween property has its own command. There is no generic `tween` command.
```
command target_name value (duration_ms) (easing)
```
- `move alice 500 200 1000` — move alice to (500, 200) over 1 second
- `movex alice 500 1000` — move alice to x=500 over 1 second
- `alpha alice 0 500` — fade alice to transparent over 500ms
- `zoom alice 200% 300` — scale alice to 200% over 300ms

### Tween Commands
- Position: `move` (x+y), `movex`, `movey`, `movez`
- Scale: `zoom` (uniform or x+y), `zoomx`, `zoomy`, `zoomz`
- Rotation: `rotate`, `rotatex`, `rotatey`, `rotatez`
- Visual: `alpha`, `rgb`, `hsl`
- Audio: `volume`
- Physics: `speedx`, `speedy`

### Modifiers
- Suffix `2` = relative value: `movex2 alice +50 300` — move 50px to the right
- Prefix `.` = blocking: `.alpha alice 255 500` — wait for tween to finish before next line
- `ups` notation: `movex2 alice 100 30ups` — move at 30px/sec instead of fixed duration

### Easing (acceleration)
- Format: `a0` through `a19` — see `Commands.xml` for full details
- If omitted, uses the current default (see `tweenMethodDefault`, `tweenMethodDefaultColour`, `tweenMethodDefaultCamera`)
- Defaults reset on `clear`

### Fade In / Fade Out
- `fadein target (duration_ms) (easing)` — fades object in (sets alpha to 255)
- `fadeout target (duration_ms) (easing)` — fades object out **and destroys it**

### Looping
- `loop [type] (xN) [tween_command]` — repeat a tween
  - Type `0` = play once, `1` = restart loop, `2` = ping-pong (forward then backward)
  - `loop 2 movex2 alice +100 500` — ping-pong move indefinitely
  - `loop 1 x6 zoom2 glow 110% 400` — restart loop, 6 repetitions

### Queued Sequences
- `tweenListAdd [target] [delay_ms] [command]` — queue a command to run after a delay from the previous queued command's *start*
  - `tweenListAdd actor 0 movex2 actor 300 1000` — starts immediately
  - `tweenListAdd actor 500 rotatey actor 360 800` — starts 500ms after previous starts

### Variable Tweening
- `varChange [var_name] [value] (duration_ms) (easing)` — smoothly tween a numeric variable over time
  - `varChange hp 0 300` — tween hp to 0 over 300ms
  - `varChange2 hp -50 300` — relative: decrease hp by 50 over 300ms

### Completion
- `tweenEnd object_name` — wait for object's tweens to finish
- `finishTweens object_name` — immediately complete all tweens on object

## Masks

### Creating Masks
- `mask [name] [image] [x] [y] [layer] (displayImage) (camera_option)` — create an invisible mask object
  - The mask image defines the visible area: white = visible, transparent = hidden
  - `mask0` creates at alpha 0

### Applying Masks
- `applyMask [target(s)] [mask_name]` — multiply target alpha by mask alpha (hides outside mask)
- `applyMask2 [target(s)] [mask_name]` — multiply target alpha by inverse mask alpha (hides inside mask)
- Targets support regex and comma-separated lists: `applyMask alice1, alice2 my_mask`

### Auto-Apply
- `autoApplyMask true [mask_name]` — automatically apply mask to all subsequently created objects
- `autoApplyMask false` — disable auto-apply

## UI / Buttons

### Creating Buttons
```
button [name] (untouched_img) (touched_img) (clicked_img) [x] [y] [r] (options) [callback_command]
```
- All three images must be the same size
- `button0` creates at alpha 0 (invisible)
- The callback command executes on click — can be any command (`jump`, `var`, `script`, etc.)
- Example: `button btn1 btn.png btn_t.png btn_c.png 300 200 90 "var choice = 1"`

### Button Text
- `btnText [button_name] [font] [size] (x_offset) (y_offset) ["text"]` — add a text label to a button
  - Creates a child object named `[button_name]_text`
  - Centred on button by default; offsets are from centre

### Default Button Resources
- `touchableRes [untouched] [touched] [clicked] (touch_sfx) (click_sfx) (highlighted_img) (disabled_img)` — set defaults for all buttons created after this command
  - Buttons created after this can omit image parameters: `button btn1 300 200 50 "jump action"`

### Button Groups & Selection
- `setButtonGroup [prefix]` — group buttons by name prefix; clicking one disables all in the group
- `wait buttonSelect [prefix]` — halt script until a button with matching prefix is clicked

### Touch Events
- `onTouchStart [button_name] [command]` — execute when cursor enters button
- `onTouchExit [button_name] [command]` — execute when cursor leaves button

### Touch Area
- `touchArea [target] [x] [y] [width] [height]` — define clickable region (offset from button top-left)
- `touchAreaScreen [target] [x] [y] [width] [height]` — define clickable region in screen coordinates

### Button State Control
- `touchStateForce [name] [0|1|2]` — force button to untouched/touched/clicked state
- `touchStateForce [name] false` — release forced state
- `highlight_if [button_name] [condition]` — button state driven by condition instead of input

## Input & Events

### Key Events
- `keyDown key_name "command"` — execute command while key is held
- `keyUp key_name "command"` — execute command when key is released
- `keyPress key_name "command"` — execute command on key press (once)
- `keyTrigger key_name "command"` — persistent key trigger (survives script changes)

### Input Functions (in expressions)
- `(lvKeyDown(key_name))` — returns true if key is currently held
- `(lvKeyPressed(key_name))` — returns true if key was just pressed
- `(lvKeyFree(key_name))` — returns true if key is not pressed

### Mouse
- `vn_mouse_x`, `vn_mouse_y` — current mouse position (system variables)
- `vn_mouse_delta_x`, `vn_mouse_delta_y` — mouse movement since last frame

### Input Locking
- `inputLock true` — disable player input
- `inputLock false` — re-enable player input

## Save / Load

- `save slot_number (screenshot_width) (screenshot_height)` — save game state to slot
- `load slot_number` — restore game state from slot
- Saves include: script position, all variables (DATA scope), object states, audio states
- Global variables persist across all saves automatically
- System variables persist in settings file

## Patterns

### Title Screen Menu
```
bookmark menu_top
bg0 title_bg title.png 0 0 0 | .fadein title_bg 300

button0 menu_start btn.png btn_t.png btn_c.png 400 200 90 "var menu_choice = 1"
button0 menu_load  btn.png btn_t.png btn_c.png 400 300 90 "var menu_choice = 2"
button0 menu_quit  btn.png btn_t.png btn_c.png 400 400 90 "var menu_choice = 3"
btnText menu_start myfont.ttf 22 "Start"
btnText menu_load  myfont.ttf 22 "Load"
btnText menu_quit  myfont.ttf 22 "Quit"
fadein menu_start, menu_load, menu_quit 300
setButtonGroup menu_

wait buttonSelect menu_

.fadeout menu_.* 200

if (menu_choice == 1) {
  ~jump chapter1.txt
} elseif (menu_choice == 2) {
  ~load 0
} else {
  ~endGame
}
```

### Pause Menu (Screenspace Overlay)
```
// Isolated rendering/input layer on top of the current scene
screenSpaceStart pause_menu

cg0 pause_dim dim.png 0 0 80 on_camera | .fadein pause_dim 200

button0 pause_resume btn.png btn_t.png btn_c.png 400 250 90 on_camera "var pause_choice = 1"
button0 pause_title  btn.png btn_t.png btn_c.png 400 350 90 on_camera "var pause_choice = 2"
btnText pause_resume myfont.ttf 20 "Resume"
btnText pause_title  myfont.ttf 20 "Title"
fadein pause_resume, pause_title 200
setButtonGroup pause_

wait buttonSelect pause_

.fadeout pause_.* 200
.fadeout pause_dim 200

screenSpaceFin pause_menu

if (pause_choice == 2) {
  ~clear
  ~jump init.txt
}
```

### Animated Button Entrance
```
// Stagger buttons in from below with easing
button0 opt_a btn.png btn_t.png btn_c.png 400 600 90 "var pick = 1"
button0 opt_b btn.png btn_t.png btn_c.png 400 650 90 "var pick = 2"
button0 opt_c btn.png btn_t.png btn_c.png 400 700 90 "var pick = 3"

fadein opt_a, opt_b, opt_c 200

// Slide up to final positions with staggered timing
movey opt_a 200 400 a12
tweenListAdd opt_b 100 movey opt_b 300 400 a12
tweenListAdd opt_c 200 movey opt_c 400 400 a12

wait tween_finish opt_c
```

### Input Lock During Transitions
```
// Prevent player clicks from interrupting an animated transition
inputLock true

.fadeout old_scene 500
bg0 new_scene new_bg.png 0 0 0 | .fadein new_scene 500

inputLock false
```

### Paginated Screen
```
// Grid of items with page navigation
var cur_page = 0
var max_page = 3

bookmark show_page

// Clean previous page
.fadeout slot_.*
.fadeout page_.*

// Create slots for current page (6 per page, 3 columns x 2 rows)
var i = 0
while (i < 6) {
  ~cg0 slot_{{i}} item_page{{cur_page}}_{{i}}.png (((i % 3) * 200) + 100) (((i / 3) * 200) + 100) 50
  ~var i += 1
}
.fadein slot_.* 200

// Page buttons
if (cur_page > 0) {
  ~button page_prev arrow_l.png arrow_l_t.png arrow_l_c.png 50 300 90 "var cur_page -= 1"
}
if (cur_page < max_page) {
  ~button page_next arrow_r.png arrow_r_t.png arrow_r_c.png 750 300 90 "var cur_page += 1"
}
button page_back back.png back_t.png back_c.png 400 550 90 "var cur_page = -1"

wait buttonSelect page_

if (cur_page == -1) {
  ~fadeout slot_.* 200
  ~fadeout page_.* 200
} else {
  ~jump show_page
}
```

## Reference

### System Variables

System variables are persisted automatically as part of the game state.

| Variable | Type | Description |
|----------|------|-------------|
| `vn_sysMasterVolume` | Number | Master volume level |
| `vn_sysBgmVolume` | Number | Background music volume |
| `vn_sysSfxVolume` | Number | Sound effect volume |
| `vn_sysVoiceVolume` | Number | Voice volume |
| `vn_sysMasterVolumeOn` | Bool | Master volume enabled |
| `vn_sysBgmVolumeOn` | Bool | BGM volume enabled |
| `vn_sysSfxVolumeOn` | Bool | SFX volume enabled |
| `vn_sysVoiceVolumeOn` | Bool | Voice volume enabled |
| `vn_sysTextSpeed` | Number | Text display speed (ms per letter) |
| `vn_sysAutoSpeed` | Number | Auto mode text flow speed (ms per letter) |
| `vn_sysAutoWait` | Number | Auto mode wait after text finishes (ms) |
| `vn_sysSkipSpeed` | Number | Skip mode text flow speed (ms per letter, 0 = instant) |
| `vn_sysTextSkipOn` | Bool | Skip mode enabled |
| `vn_sysTextAutoOn` | Bool | Auto mode enabled |
| `vn_sysTextNormalForce` | Bool | Force normal text mode |
| `vn_sysTextSkipMethod` | Number | Skip method (0 = all lines, 1 = read lines only) |
| `vn_sysWindowMode` | Number | Window mode setting |
| `vn_win_width` | Number | Window width (pixels) |
| `vn_win_height` | Number | Window height (pixels) |
| `vn_sysVoicePlayType` | Number | Voice playback method |
| `vn_mouse_x` | Number | Current mouse X position (read-only) |
| `vn_mouse_y` | Number | Current mouse Y position (read-only) |
| `vn_mouse_delta_x` | Number | Mouse X movement delta (read-only) |
| `vn_mouse_delta_y` | Number | Mouse Y movement delta (read-only) |

### Script-Callable Functions

Functions are called inside `( )` expressions. All function names start with `lv`.
- Example: `var roll = (lvRandom(1, 6))`
- Example: `if (lvExistsObj("alice"))` 
- See `Commands.xml` for the full list of available functions (math, string, save, input, system, containers, object queries).
