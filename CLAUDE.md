# CLAUDE.md — Hourglass

Shared context for everyone (humans and Claude sessions) working on this repo.
Claude reads this file automatically at the start of every session, so **keep it current**:
when a decision is made, record it here in the same commit as the change.

---

## 1. Project

**Hourglass (v0.1)** — an immersive pomodoro timer for iPhone.

> Claude must not invent answers to anything marked TODO — ask instead.

- **What it is:** a pomodoro (focus / break) timer where the whole iPhone screen *is* the hourglass.
  The hourglass is rendered in Apple's **Liquid Glass** style and holds a **liquid, not sand**, which
  drains from the top bulb to the bottom as time passes.
- **Who it's for:** TODO — target users.
- **v0.1 scope:**
  - Liquid hourglass that **reacts to tilt** (device motion) and drains with elapsed time.
  - **Flip the phone upside down to start** a session, like turning a real hourglass (with a tap
    fallback for accessibility).
  - Pomodoro cycle: focus → short break, long break every N focus sessions; **custom durations**.
  - **Local notification** when a session ends while the app is in the background.
  - **Live Activity** countdown on the Lock Screen / Dynamic Island.
  - **Session history** of completed pomodoros, stored on-device (SwiftData).
- **Out of scope for v0.1:** TODO (proposed: accounts, cloud sync, iPad-specific layout, Apple Watch).

## 2. Team

| Who | Role / areas owned |
|-----|--------------------|
| Rahul (`Rahul-Gaikar`, repo owner) | TODO |
| TODO (collaborator) | TODO |

## 3. Tech stack

TODO — record each choice with a one-line reason in the decision log (§7).

- Platform: **native iOS**, minimum **iOS 26.0** (required for native Liquid Glass APIs), iPhone (portrait only) + iPad (template default — revisit).
- Language / framework: **Swift 6** (strict concurrency) + **SwiftUI**.
- Project generation: **XcodeGen** — `project.yml` is the source of truth; `Hourglass.xcodeproj` is generated and git-ignored.
- Tests: **Swift Testing** (`HourglassTests` target, hosted in the app).
- Lint / format: **swift-format** (ships with Xcode; config in `.swift-format`).
- CI: **GitHub Actions** on `macos-15` — lint, generate, build, test on every push.
- Package manager: **Swift Package Manager** (declared in `project.yml` when needed).
- Database: **SwiftData**, on-device only (session history).
- Auth / backend: TODO (none proposed for v0.1).
- Distribution: TestFlight → App Store. Needs an Apple Developer account; bundle ID prefix `app.hourglass` is a placeholder (TODO: confirm).

**Layout**
```
project.yml            # XcodeGen spec (targets, settings, schemes)
Hourglass/App/         # app entry point
Hourglass/Screens/     # full screens and panels (TimerScreen, DurationsPanel)
Hourglass/Timer/       # pomodoro state machine + settings (pure, no UI)
Hourglass/Liquid/      # hourglass geometry, slosh physics, Canvas renderer, glass view
Hourglass/Motion/      # Core Motion gravity reader, flip detection
Hourglass/Notifications/ # end-of-session local notification (behind a protocol for tests)
Hourglass/LiveActivity/  # starts/updates/ends the Live Activity (behind a protocol for tests)
HourglassWidgets/      # widget extension: Lock Screen + Dynamic Island Live Activity UI
Shared/                # compiled into BOTH the app and the widget (activity attributes, phase, palette, time label)
Hourglass/Resources/   # asset catalog
HourglassTests/        # unit tests (Swift Testing)
.github/workflows/     # CI
```

## 4. Commands

Keep this list accurate; Claude uses it to verify work. All require macOS with **Xcode 26+** (iOS 26 SDK).

```bash
# install:   brew install xcodegen
# generate:  xcodegen generate            # after every pull or project.yml edit
# dev:       open Hourglass.xcodeproj     # then Run (⌘R) on a simulator
# lint:      xcrun swift-format lint --strict --recursive Hourglass HourglassTests HourglassWidgets Shared
# format:    xcrun swift-format format --in-place --recursive Hourglass HourglassTests HourglassWidgets Shared
# test:      xcodebuild test -project Hourglass.xcodeproj -scheme Hourglass -destination 'platform=iOS Simulator,name=<an installed iPhone>'
# build:     same as test, with `build` instead of `test`
```

Typecheck happens as part of build/test (Swift compiler).

## 5. How we work together

We both ship **directly to `main`** — no long-lived feature branches.

1. **Sync before you start and before you push:** `git pull --rebase origin main`.
2. **Small, focused commits.** One logical change per commit; don't touch unrelated files.
3. **Commit messages:** imperative, conventional style — `feat: …`, `fix: …`, `chore: …`,
   `docs: …`, `refactor: …`, `test: …`.
4. **`main` must stay green.** Run lint, typecheck and tests (§4) before pushing.
5. **Never force-push `main`** and never rewrite shared history. On a conflict, rebase locally,
   resolve, re-run checks, then push.
6. **Shout before big moves.** Schema changes, new dependencies, folder restructures or anything
   destructive: tell the other person first.
7. **Update this file** when you add a command, make a stack/architecture decision, or learn a
   gotcha. A stale CLAUDE.md is worse than none.

## 6. Engineering standards

Applies to all code, whether written by a person or by Claude.

**General**
- Correctness over speed. Simple, readable, maintainable over clever.
- Never guess requirements — ask when something is ambiguous.
- Follow the existing architecture; reuse existing components; don't duplicate logic.
- Small, focused files with meaningful names. Comments only where they add value.
- Avoid unnecessary dependencies and over-engineering.

**Quality**
- Type-safe (TypeScript strict mode if/when we use TS).
- Every UI/data flow handles loading, empty, error and edge cases; validate inputs; fail gracefully.
- Add or update tests for important logic.

**Security**
- Never commit secrets. Use env vars; commit only a `.env.example`.
- Validate and sanitise all input; guard against XSS, CSRF and injection.
- Enforce authentication *and* authorization server-side; least privilege everywhere.
- Rate-limit public endpoints where appropriate.

**Performance**
- Don't optimise prematurely, but call out obvious bottlenecks (N+1 queries, large bundles,
  unnecessary re-renders). Memoise only when justified.

**Database**
- Migrations must preserve existing data and have a rollback path. Explain impact in the commit.

**APIs**
- Predictable, consistent, typed, validated and documented.

**UI**
- Responsive, accessible, consistent spacing/typography, reusable components, all interaction states.

**Debugging**
- Find the root cause; no random fixes. Explain why it broke and why the fix works.

### Instructions for Claude
- Before non-trivial changes: brief plan + tradeoffs. Ask for approval only if large or destructive.
- Self-review before finishing: simpler solution? duplication? security? performance? edge cases?
- Never claim something works without verifying it; state uncertainty explicitly.
- When done, report: summary, files changed, key decisions, risks, and (only if useful) next steps.
- Do not put model names or personal details (emails etc.) in commits or code.

## 7. Decision log

Newest first. Format: `YYYY-MM-DD — decision — reason — who`.

- 2026-11-19 — Live Activity: a widget extension (`HourglassWidgets`) shows phase, a system-driven countdown and a draining bar while a session runs or is paused; it ends on reset/completion, goes stale at the end date (shows "Session complete"), and leftovers are cleared on relaunch. Types the app and widget both need live in `Shared/`.
- 2026-11-19 — End-of-session alert: one local notification scheduled for the session's end date whenever the timer runs, cancelled on pause/reset or when the session ends with the app open (no banner over the hourglass). Permission is asked on the first start, not at launch; refusal just means no alerts.
- 2026-11-19 — Custom durations: edited in a glass panel drawn inside the (rotatable) timer screen rather than a sheet, so it reads correctly after a flip; saved as JSON in UserDefaults; changes made mid-session apply from the next session so the liquid never jumps.
- 2026-11-19 — Flip to start: an idle hourglass shows drained; turning the phone over (held ~0.3 s) starts the next session and the UI rotates 180° with it. Flips while running/paused are ignored. iPhone locked to portrait so system rotation doesn't fight the physical flip.
- 2026-11-19 — Generate the Xcode project with XcodeGen and don't commit `.xcodeproj` — avoids `project.pbxproj` merge conflicts with two people pushing to `main`.
- 2026-11-19 — Product: immersive pomodoro timer; liquid (not sand) hourglass, tilt-reactive, flip to start; v0.1 includes custom durations, notifications, Live Activity, history — Dinkar.
- 2026-11-19 — Minimum iOS 26 — use native Liquid Glass APIs instead of maintaining an imitation for older iOS — Dinkar.
- 2026-11-19 — Native iOS with SwiftUI + Swift 6 — native feel, least code, SwiftData available on 17+.
- 2026-11-19 — Work directly on `main`; shared CLAUDE.md as the single source of project context — keep collaboration simple for a two-person team.

## 8. Gotchas / notes

- Never edit `Hourglass.xcodeproj` settings by hand — they're lost on the next `xcodegen generate`. Change `project.yml` instead. New files under `Hourglass/` are picked up automatically after regenerating.
- Claude cloud sessions run on Linux: they can write Swift but can't build or run it. CI (macOS runner) is the check for that work.
- Keep logic out of views: geometry, physics and timer code are plain value types with no actor
  isolation so they're unit-testable and can run inside `Canvas`. Views only wire them together.
- CI uploads a Simulator screenshot (`hourglass-screenshot` artifact) — the quickest way to eyeball
  UI changes made from a Claude cloud session. The Simulator has no motion sensors, so tilt can only
  be judged on a real device.
- Swift Testing: when comparing an **optional** `TimeInterval` in `#expect`, write the expected value as
  `TimeInterval(25 * 60)`, not `25 * 60`. Inside the macro the literal is typed as `Int`, so the check
  fails even though both print as 1500. Non-optional comparisons infer `Double` and are fine.
- `Shared/` is compiled into two targets — keep it free of app-only types (e.g. `PomodoroTimer`). App-only
  conveniences on shared types go in the app (see `Hourglass/LiveActivity/PomodoroTimer+Activity.swift`).
- `HourglassWidgets/Info.plist` is generated by XcodeGen from `project.yml` and git-ignored.
- Signing: set `DEVELOPMENT_TEAM` in `project.yml` once we have the team ID (it isn't a secret).
