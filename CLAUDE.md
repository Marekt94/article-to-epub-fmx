# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working directives (do not skip)

- **No global save.** Never write to the global `~/.claude` folder for this project — this includes auto-memory (`~/.claude/projects/.../memory/`), global skills, and global settings. Persist everything **inside this repo** instead: project knowledge/guidelines in `CLAUDE.md` or `docs/`, skills in `.claude/skills/`, config in `.claude/settings.json`. This is a standing rule, not per-session.

## What this is

A Delphi **FireMonkey (FMX)** mobile-first app (RAD Studio / Delphi 12.1 CE, `ProjectVersion` 20.3). The user submits an article URL; a backend simplifies it, converts it to EPUB, and emails it to an e-reader. The app is the thin client: it collects a URL + settings and calls a REST backend. Primary target is **Android64**; also builds for Win64/Win32. On Android it accepts a shared URL via a `SEND` intent.

## Build, run, debug

There is no command-line build in this repo — build and run through the RAD Studio IDE, driven via the **Kai MCP** tools (see the IDE-integration instructions and skills). Key tools:
- `compileProjects` — compile without running.
- `runProject` / `terminateProcess` — run and stop under the debugger.
- `getProjectInfo`, `addFileToProject`, `removeFileFromProject` — project structure. The unit list lives in `ArticleToEpub.dpr` and `ArticleToEpub.dproj`; keep both in sync when adding/removing units.

There are no automated tests in this project.

## Architecture

UI is deliberately separated from logic; all external communication is hidden behind interfaces (`src/interfaces/`).

- **Entry point** `ArticleToEpub.dpr` → creates `TForm1` from **`FmMain.pas`** (NOT `Main.pas`).
- **`FmMain` (`TForm1`)** — host shell. A `TTabControl` with two tabs, each hosting a frame instance (`FfrmSettings`, `FfrmConverter`). In `Init` it constructs the settings repository, injects it into both frames, and wires the three lifecycle callbacks (`OnStart`/`OnSuccess`/`OnError`) into any frame that supports `IExecutingHandlers`. Those callbacks drive the busy indicator (`AniIndicator1`) and result dialogs. Switching away from the settings tab auto-saves settings (`TabControl1Change` → `FfrmSettings.SaveToRepo`).
- **`FrmSettings` (`TFrame1`)** — settings form (receiver emails + an advanced `TExpander` with backend URL, API key, sender email, sender app password). Maps UI ↔ `TAppSettings` (`ReadSettingsFromUi`/`ReadSettingsToUi`), loads/saves via the repo, and its button runs a `Health` check against the backend.
- **`FrmConverter` (`TFrame2`)** — URL input + convert button; calls `IClient.FetchURL`. On Android, `OnShareIntent` reads a shared URL from the launch intent into the edit box.
- **Settings model & persistence**:
  - `Settings.pas` — `TAppSettings` record (the config value object passed everywhere).
  - `SettingsInterface.pas` — `ISettingsRepository` (`Load`/`Save`).
  - `SettingsRepository.pas` — two implementations. **`TIniFileSettingsRepository` is the one actually used** (wired in `FmMain.Init`); it stores an INI file in the Documents folder. `TJsonFileSettingsRepository` also exists but is currently unused.
- **REST client**:
  - `ClientInterface.pas` — `IClient` (`FetchURL`, `Health`) and `IExecutingHandlers` (the start/success/error callback contract).
  - `ClientFactory.pas` — `TClientFactory.CreateInstance(AppSettings): IClient`; the single place that constructs a client. Use it rather than instantiating `TRESTClient` directly.
  - `DMRestClient.pas` + `.dfm` — `TDataModule1` holds the `TRESTClient`/`TRESTRequest`/`TRESTResponse` components; `TRESTClient` (implements `IClient` + `IExecutingHandlers`) wraps it. Requests run via `ExecuteAsync`; completion/error handlers marshal back to the UI thread with `TThread.Synchronize` before invoking the callbacks. Endpoints: `health` and `api/fetch-url`. Auth is an `Authorization: API-Key <key>` header added in `AddCommonHeaders`.
- **Backend API contract** — the app talks to a separate **Gin (Go)** service (repo `article-to-epub`). `postman/` holds the canonical request collection + a local environment (`baseUrl`, `apiKey`). Endpoints there:
  - `POST /api/fetch-url` — JSON body `{"url": ..., "email": [...]}`. Empty `email` returns the EPUB as a binary download; a non-empty `email` array sends the EPUB by mail and returns JSON. This is the one the app uses (send-email variant, via `TBody`).
  - `POST /api/convert-html` — multipart form upload; **not called by the app** and its backend handler is currently empty.
  - `health` (used by the settings tab's health check) is not in the collection.
  Auth on every request: `Authorization: API-Key <key>`. Keep `postman/` in sync when the backend contract changes. Full contract table: `docs/BACKEND_API.md`.

Typical flow: frame button → `TClientFactory.CreateInstance(repo.Load)` → wire `IExecutingHandlers` callbacks → `IClient` async call → `Synchronize`d success/error callback → `TForm1` shows indicator/dialog.

## Coding guidelines

- **Self-documenting code over comments.** Maximally avoid comments; express intent through the code itself. Identifiers (variables, methods, types) may be longer but must be tied to *what they do* — e.g. `SaveSettingsToRepository` over `Save2`, `receiverEmailsCsv` over `s`. This is the clean-code principle the project follows.
- **Comment only when code cannot express it** — a non-obvious *why*, a workaround, or an external contract. No restating/decorative comments; don't add comments to existing code gratuitously.
- Keep existing Polish comments and user-facing Polish strings intact (see Language, below).

## Conventions & gotchas

- **`FmMain`/`FrmSettings`/`FrmConverter` are the live units.** `Main.pas`, `Main.fmx`, and `frames/Settings.pas`/`Settings.fmx` are empty or legacy leftovers — do not edit them expecting an effect. `docs/CONTEXT.md` describes an older `Main.pas`-based layout and is partly stale; trust the code.
- **DFM/FMX encoding**: keep `.fmx`/`.dfm` files as text saved **UTF-8 with BOM**. Mixed encodings with non-ASCII (Polish) text produce garbled designer strings and stream-read errors. `DMRestClient.pas` currently contains corrupted Polish string literals (mojibake) — fix them as UTF-8 when touched. See `docs/CONTEXT.md` for the full DFM-stability checklist (single root `object` block, single-line `Text = '...'`, watch `StyledSettings`/`TextSettings`).
- **UI-as-DFM**: per project rules, prefer defining UI in the `.fmx` designer files over building controls in code ("Delphi style").
- **Language**: user-facing strings and many comments are in **Polish**; keep new UI strings consistent.
- **Editing `.fmx`/`.dfm` + `.pas` pairs**: use the IDE-file-operations skill — keep the form file and its unit's published field list in sync, and reload in the designer after manual edits.
- Editor line/column positions in Kai tools are **1-based**.
