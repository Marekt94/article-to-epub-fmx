# Project context (article-to-epub-firemonkey)

## Repo

- Path: `c:\Repo\article-to-epub-firemonkey`
- UI framework: Delphi FireMonkey (FMX)
- Target: Windows + Android (multi-device)

## Entry UI

### Main form

- File: `Main.pas` + `Main.fmx`
- Class: `TForm1 = class(TForm)`

### Resources / device-specific FMX

`Main.pas` links multiple form resources:

- `{$R *.fmx}` (master)
- `{$R *.Windows.fmx MSWINDOWS}`
- `{$R *.LgXhdpiPh.fmx ANDROID}`
- `{$R *.Surface.fmx MSWINDOWS}`

Implication:

- There are device/platform-specific overrides for the form.
- Android uses a specific FMX resource file: `*.LgXhdpiPh.fmx` (Large XHDPI Phone).

## Main.fmx snapshot (active)

- Form:
  - `ClientHeight = 480`, `ClientWidth = 640`
  - `FormFactor.Width = 320`, `FormFactor.Height = 480`
  - `FormFactor.Devices = []`
  - `DesignerMasterStyle = 3`
- Root layout:
  - `TabControl1: TTabControl`
    - `Align = Client`
    - `Images = ImageList1`
    - `TabPosition = Bottom`
    - `TabHeight = 49`
    - `TabIndex = 1`
    - Contains:
      - `TabItem1` (ImageIndex = 0)
      - `TabItem2` (ImageIndex = 0, selected)
        - Inline frame: `TFrame11: TFrame1` (from unit `Settings`)
- Animation:
  - `FloatAnimation1` exists under `TabControl1` (Enabled=True, Duration=1s). Not currently referenced in code.
- Images:
  - `ImageList1: TImageList` exists but `MultiResBitmap` content currently appears empty in the provided snippet (placeholders).
    - This may mean images are defined elsewhere or not persisted in the snippet.

## Main.pas snapshot

### Uses

- Core: `System.*`
- FMX: `FMX.Types`, `FMX.Controls`, `FMX.Forms`, `FMX.Graphics`, `FMX.StdCtrls`,
  `FMX.Controls.Presentation`, `FMX.Objects`, `FMX.ImgList`, `FMX.TabControl`,
  `FMX.Ani`, `FMX.Gestures`
- Project unit: `Settings` (provides `TFrame1`)

### Components on TForm1

- `TabControl1`, `TabItem1`, `TabItem2`
- `ImageList1`
- `TFrame11: TFrame1` (inline frame instance on TabItem2)
- `GestureManager1: TGestureManager`

### Behavior

- Only explicit logic is gesture handling:
  - `TabControl1Gesture` checks:
    - `sgiLeft` => switches to `TabItem1` with slide transition normal
    - `sgiRight` => switches to `TabItem2` with slide transition reversed
  - Sets `Handled := True` when it processes a gesture

No explicit code for:

- toolbar sizing
- button sizing
- image assignment
- styling changes
- Skia (already removed from this unit)

## Known issues / observations (from current state)

1. **Form factor / designer device list**
   - `FormFactor.Devices = []` in the shown `Main.fmx`. In multi-device projects this can cause confusing designer “Desktop/iPhone/iPad” behavior and inconsistent sizing expectations.
2. **Android-first design**
   - Because Android has a dedicated FMX (`*.LgXhdpiPh.fmx`), changes done in Master may not reflect on Android unless updated in that device-specific file too.
3. **Images in TabControl**
   - Both TabItems use `ImageIndex = 0`. If different icons are expected, this should be adjusted or multiple images added.
4. **Animation object existence**
   - `FloatAnimation1` exists but is not referenced; verify whether it is needed.

## FMX/DFM Designer stability notes (important for new frames)

### Encoding rules (avoid "krzaczki" and stream errors)

- Keep `.fmx` / `.dfm` files as **text** and save them consistently as **UTF-8 with BOM**.
  - Mixed encodings (ANSI/no BOM vs UTF-8) + non-ASCII text (PL) often leads to designer showing garbage characters.
- If you see corrupted Polish characters in string properties, the file was likely saved in the wrong encoding.

### Common causes of `Error reading ... Invalid property value` / `Read stream error`

1. **Broken FMX structure**
   - Typical symptom: duplicated/partially appended blocks like a second `object Frame1: ...` at the end of the file.
   - Fix: ensure there is exactly **one** root `object FrameX: TFrameX` (or `object FormX`) and the file ends correctly.

2. **Broken property line formatting**
   - A single property line with wrong indentation or broken string literal can poison the whole stream.
   - Watch out for a property like `Text = '...'` being accidentally:
     - moved to the wrong indentation level,
     - or split across lines,
     - or containing invisible control characters.

3. **Style/text settings differences**
   - Some combinations of `StyledSettings` + `TextSettings.*` can be brittle across Delphi versions/styles.
   - If the designer fails on a label, try temporarily removing:
     - `TextSettings.FontColor`
     - `TextSettings.Font.*`
     - custom `StyledSettings`

### Quick sanity checks before committing a new frame

- Search for duplicate root blocks: `object Frame` / `object Form` should appear once.
- Ensure all `Text = '...'` values are single-line and properly indented.
- Prefer ASCII in designer text while iterating; reintroduce Polish strings after encoding is confirmed stable.
- If you manually edit `.fmx`, always re-open in the designer quickly to confirm it still parses.

## What to inspect next (files to open)

To fully diagnose sizing/UI differences across platforms:

- `Main.LgXhdpiPh.fmx` (Android-specific)
- `Main.Windows.fmx` and `Main.Surface.fmx` (Windows-specific)
- `Settings.pas` + its `.fmx` (frame content/layout; might be influencing perceived size)
- Project options (Android manifest, styles, form scaling) — not in files yet

## Operating assumptions

- Delphi version not specified; behavior/properties vary slightly across versions.
- Debugger disconnect issues previously tied to Skia; current units do not reference Skia.
