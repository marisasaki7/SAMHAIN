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

## Script Syntax

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

### Appending `0` to Creation Commands
- Adding `0` after a creation command (e.g. `cg0`, `textbox0`) creates the object with alpha = 0 (invisible)
- Useful for fading objects in after creation

## Coordinate System

- **Origin**: top-left corner of the screen
- **X axis**: increases to the right →
- **Y axis**: increases downward ↓
- **R axis (layer)**: higher = in front, z = r * 100
- **Scale**: `100` = 100% (base unit is 100, not 1.0)
- **Rotation**: degrees, clockwise positive
- **Pivot/Origin point**: `(0,0)` = top-left of object, `(1,1)` = bottom-right, `(0.5, 0.5)` = center

## Object System

### Creating Objects
- Objects are created via commands: `cg`, `bg`, `textbox`, `button`, `text`, `bgm`, `soundEffect`, etc.
- Every object has a unique name (first parameter after command)
- Example: `cg alice alice_smile.png 400 100 50` — creates image "alice" from file, at position (400, 100), r 50

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

## R (Layer) System

- Every object has an `r` value (layer): higher = in front, z = r * 100
- `r` is a float value
- `on_camera` option: attaches object to camera so it's unaffected by camera movement
  - Useful for UI elements that should stay fixed on screen

## Variable System

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

**How dialogue waiting works:**
- When `textAutoWait` is `1`, every `"` / `-"` line triggers a wait after the text finishes displaying
- When `textAutoWait` is `2`, only blank `"` lines (just `"` with no text) trigger a wait
- `\w` in a line forces a wait regardless of `textAutoWait` setting
- `\c` in a line suppresses the auto-wait for that line only

**`textOverflowAutoWait`** — automatic pagination:
- `textOverflowAutoWait true` (default) — when text overflows the textbox, the engine displays as much as fits, waits for player input, then continues with the remaining text
- `textOverflowAutoWait false` — overflow text is not auto-paginated

**`wait` command** — explicit wait:
- `wait` — wait for player input (`continueRead`)
- `wait 1500` — wait for 1500ms then continue
- `wait preventContinueRead` — halt script; only `jump` can resume (use for menus where only buttons should advance)

**`continueRead` command** — resumes script after a wait:
- If text is still flowing: instantly displays all remaining text
- If text is finished: resumes script reading (advances past the wait)
- Typically triggered automatically by player click/input
- Can be called explicitly from button commands or key triggers

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
  - `textColour r g b` — change text color
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
- Creates a child object named `[textbox]_skin` that can be further tweened

### Static Text
- `text` command creates non-flowing text (all text appears at once)
- Use for labels, UI text, etc.

### Changing an Object's Image
- `image alice alice_happy.png` — swaps the image/animation of an existing object without recreating it
- Optional transition: `image alice alice_happy.png 500` — crossfade over 500ms

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
- `a0` through `a18` — acceleration curves
- Named: `Linear`, `QuadEaseIn`, `QuadEaseOut`, `QuadEaseInOut`, `ExpoEaseIn`, `ExpoEaseOut`, etc.

### Fade In / Fade Out
- `fadein target (duration_ms) (easing)` — fades object in (sets alpha to 255)
- `fadeout target (duration_ms) (easing)` — fades object out **and destroys it**

### Completion
- `tweenEnd object_name` — wait for object's tweens to finish
- `finishTweens object_name` — immediately complete all tweens on object

## Script Flow

### Waiting
- `wait` — wait for player click
- `wait 1500` — wait 1500 ms
- `wait tween_finish object_name` — wait for tween to complete
- `wait buttonSelect` — wait for a button click
- `wait textDisplayFin` — wait for text to finish displaying
- `wait animation_finish object_name` — wait for sprite animation
- `wait movieFin` — wait for video to finish

### Bookmarks & Jumps
- `bookmark my_label` — define a jump target
- `jump my_label` — jump to bookmark (same script)
- `jump filename.txt` — jump to another script file (replaces current script, does not return)

### Subscripts
- `script filename.txt` — run another script file (pauses current, resumes when subscript finishes)
- `parallel_script filename.txt` — run script in parallel (does not pause current)
- `script_fin` — end current subscript, return to parent script
- `endGame` — terminate the application (use on the main script to end the game)

### Conditionals
Two forms:

**Single-line** (command on same line):
```
if (condition) command (else) (command)
```
- `if (answer == 2) jump reached else jump not_reached`
- `if (answer == 2) fadeout cg0`

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

### Screenspaces
- `screenSpaceStart name` — create an isolated rendering/input context (for menus, overlays)
- `screenSpaceFin name` — close and destroy the screenspace
- Objects in a screenspace don't interfere with the main game context

## Save / Load

- `save slot_number (screenshot_width) (screenshot_height)` — save game state to slot
- `load slot_number` — restore game state from slot
- Saves include: script position, all variables (DATA scope), object states, audio states
- Global variables persist across all saves automatically
- System variables persist in settings file

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

## Common Patterns

### Typical VN Game Structure
```
// init.txt — entry point (set as InitialScript in settings.xml)
textbox main_box 0 400 81 800 200 myfont.ttf 24
useTextbox main_box

// Title screen
bg title_bg title.png 0 0 0
button btn_start start_btn.png 400 300 90 "jump chapter1.txt"
button btn_load load_btn.png 400 400 90 "load 0"
wait buttonSelect btn_
```

```
// chapter1.txt
bg room bedroom.png
cg alice alice_neutral.png 400 100 50
bgm chapter1_bgm.ogg repeat

"Good morning!
"How are you today?
~

// Choice menu
button choice_a choice_bg.png 300 200 90 "var choice = 1"
btnText choice_a myfont.ttf 20 "I'm great!"
button choice_b choice_bg.png 300 350 90 "var choice = 2"
btnText choice_b myfont.ttf 20 "Could be better..."
setButtonGroup choice_
wait buttonSelect choice_

if (choice == 1) {
  "I'm great!
  ~wait
} else {
  "Could be better...
  ~wait
}

jump init.txt
```

### Scene Transitions
```
// Fade out current scene, change background, fade in
fadeout room 500
bg0 room2 new_scene.png | fadein room2 500
```

### Character Sprite Swapping
```
// Replace character expression (instant)
image alice alice_happy.png

// Replace with crossfade transition
image alice alice_happy.png 500
```

## System Variables

All system variables are automatically saved/loaded from settings.

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
| `vn_sysTextSkipMethod` | Number | Skip method (0 = read lines only, 1 = all lines) |
| `vn_sysWindowMode` | Number | Window mode setting |
| `vn_win_width` | Number | Window width (pixels) |
| `vn_win_height` | Number | Window height (pixels) |
| `vn_sysVoicePlayType` | Number | Voice playback method |
| `vn_mouse_x` | Number | Current mouse X position (read-only) |
| `vn_mouse_y` | Number | Current mouse Y position (read-only) |
| `vn_mouse_delta_x` | Number | Mouse X movement delta (read-only) |
| `vn_mouse_delta_y` | Number | Mouse Y movement delta (read-only) |

## Script-Callable Functions

Functions usable inside `( )` expressions.

### Math
| Function | Description |
|----------|-------------|
| `lvRandom(min, max)` | Random integer in [min, max] |
| `lvMin(a, b, ...)` | Minimum of values |
| `lvMax(a, b, ...)` | Maximum of values |
| `lvRoundToInteger(n)` | Round to nearest integer |
| `lvFloor(n)` | Floor to integer |
| `lvMath::pi()` | Pi constant |
| `lvMath::abs(n)` | Absolute value |
| `lvMath::sin(rad)` | Sine |
| `lvMath::cos(rad)` | Cosine |
| `lvMath::tan(rad)` | Tangent |
| `lvMath::asin(n)` | Inverse sine |
| `lvMath::acos(n)` | Inverse cosine |
| `lvMath::atan(n)` | Inverse tangent |
| `lvMath::atan2(y, x)` | Two-argument inverse tangent |
| `lvMath::sqrt(n)` | Square root |
| `lvMath::deg(rad)` | Radians to degrees |
| `lvMath::rad(deg)` | Degrees to radians |

### String
| Function | Description |
|----------|-------------|
| `lvSubstring(str, start, count)` | Extract substring |
| `lvRemoveSuffix(str, suffix_or_count)` | Remove suffix |
| `lvNumberToString(n, precision)` | Number to string (precision optional) |
| `lvStringToNumber(str)` | String to number |
| `lvSubstringCount(haystack, needle)` | Count occurrences |
| `lvStringRemoveFormat(str)` | Strip `<>` formatting tags |

### Time
| Function | Description |
|----------|-------------|
| `lvTimeNow(format_string)` | Current time as formatted string |

### Data / Save
| Function | Description |
|----------|-------------|
| `lvSaveExists(slot)` | True if save slot exists |
| `lvSaveImagePath(slot)` | Path to save thumbnail |
| `lvSaveInfo(slot, attr)` | Get save metadata |
| `lvSaveGetDataVar(slot, varname)` | Get variable from save |
| `lvSaveSetDataVar(slot, varname, value)` | Write variable to save |

### Input
| Function | Description |
|----------|-------------|
| `lvKeyDown(key)` | True if key held |
| `lvKeyPressed(key)` | True if key just pressed |
| `lvKeyFree(key)` | True if key not pressed |

### System
| Function | Description |
|----------|-------------|
| `lvSystem::InputType()` | Current input type |
| `lvSystem::WindowMode()` | Window mode |
| `lvSystem::WindowSize()` | [width, height] list |
| `lvSystem::ViewportSize()` | [width, height] list |
| `lvSystem::IsDesktop()` | True if desktop platform |
| `lvSystem::IsFixedWindowSize()` | True if window size is fixed |
| `lvSystem::IsPausingLowerScripts()` | True if lower scripts paused |

### Containers
| Function | Description |
|----------|-------------|
| `lvCreateVarList(count, initial)` | Create list of N elements (initial optional) |
| `lvCreateVarHashMap()` | Create empty hashmap |
| `lvCreateVarHashMapFromJson(path)` | Load JSON as hashmap |
| `lvCreateVarHashMapFromCsv(path)` | Load CSV as hashmap |
| `lvCreateVarListFromCsv(path)` | Load CSV as list of hashmaps |
| `lvCreateVarArrayFromCsv(path)` | Load CSV as 2D list |
| `lvSize(container)` | Element count |
| `lvIsEmpty(container)` | True if empty |
| `lvClear(container)` | Empty the container |
| `lvCopyDeep(var)` | Deep clone |
| `lvVarFromString(str)` | Create identifier from string |
| `lvShuffle(list)` | Randomize list order |
| `lvListPushFront(list, val)` | Prepend to list |
| `lvListPushBack(list, val)` | Append to list |
| `lvListAppendBack(a, b)` | Append all of B to A |
| `lvListPopFront(list)` | Remove first element |
| `lvListPopBack(list)` | Remove last element |
| `lvListPushAt(list, idx, val)` | Insert at index |
| `lvListPopAt(list, idx)` | Remove at index |
| `lvListIndexWithHashKeyValue(list, key, val)` | Find hashmap by key-value |
| `lvListIndexEmptyFirst(list)` | Find first empty slot |
| `lvHashMapHasKey(map, key)` | True if key exists |
| `lvHashMapEraseKey(map, key)` | Remove key |

### Object Queries
| Function | Description |
|----------|-------------|
| `lvExistsObj(name_regex)` | True if matching object exists |
| `lvGetNames(name_regex)` | List of matching object names |
| `lvGetClosestObjWithName(from, to_regex)` | Closest matching object |
| `lvRandomName(prefix)` | Generate unique object name |
| `lvPositionCenter(obj)` | [x, y, z] center position |
| `lvPositionCenterX(obj)` | X center coordinate |
| `lvPositionCenterY(obj)` | Y center coordinate |
| `lvPositionCenterR(obj)` | Layer (r) coordinate |
| `lvPositionCenterZ(obj)` | Z coordinate |
| `lvPositionDeltaX(obj)` | Tweened X delta |
| `lvPositionDeltaY(obj)` | Tweened Y delta |
| `lvRotationX(obj)` | X rotation (degrees) |
| `lvRotationY(obj)` | Y rotation (degrees) |
| `lvRotationZ(obj)` | Z rotation (degrees) |
| `lvSpeedX(obj)` | X velocity |
| `lvSpeedY(obj)` | Y velocity |
| `lvSpeedZ(obj)` | Z velocity |
| `lvTileX(obj)` | Tile X index |
| `lvTileY(obj)` | Tile Y index |
| `lvTextureW(path)` | Texture width (pixels) |
| `lvTextureH(path)` | Texture height (pixels) |
| `lvMediaOffset(obj)` | Playback offset (ms) |
| `lvTextboxInUse()` | Name of active textbox |
| `lvText(textbox)` | Current text content |
| `lvTextBoundsW(textbox)` | Text width (pixels) |
| `lvTextBoundsH(textbox)` | Text height (pixels) |
| `lvAnimationIsPlaying(obj)` | True if animation active |
| `lvState(obj)` | Current state string |
| `lvHasState(obj)` | True if has state component |
| `lvObjTransformPoint(obj, x, y, z)` | Transform point by object matrix |
| `lvObjTransformVector(obj, x, y, z)` | Transform vector by object matrix |
