# CLAUDE.md — Hourglass

Shared context for everyone (humans and Claude sessions) working on this repo.
Claude reads this file automatically at the start of every session, so **keep it current**:
when a decision is made, record it here in the same commit as the change.

---

## 1. Project

**Hourglass (v0.1)** — early stage. A native iOS app (SwiftUI); the project is scaffolded but the product itself is not yet defined.

> TODO (team): fill in the sections below as soon as they're decided. Claude must not invent
> answers to anything marked TODO — ask instead.

- **What it is:** TODO — one-paragraph description of the product.
- **Who it's for:** TODO — target users.
- **v0.1 scope:** TODO — the smallest thing we ship first.
- **Out of scope for v0.1:** TODO.

## 2. Team

| Who | Role / areas owned |
|-----|--------------------|
| Rahul (`Rahul-Gaikar`, repo owner) | TODO |
| TODO (collaborator) | TODO |

## 3. Tech stack

TODO — record each choice with a one-line reason in the decision log (§7).

- Platform: **native iOS**, minimum iOS 17.0, iPhone + iPad (template default — revisit).
- Language / framework: **Swift 6** (strict concurrency) + **SwiftUI**.
- Project generation: **XcodeGen** — `project.yml` is the source of truth; `Hourglass.xcodeproj` is generated and git-ignored.
- Tests: **Swift Testing** (`HourglassTests` target, hosted in the app).
- Lint / format: **swift-format** (ships with Xcode 16+; config in `.swift-format`).
- CI: **GitHub Actions** on `macos-15` — lint, generate, build, test on every push.
- Package manager: **Swift Package Manager** (declared in `project.yml` when needed).
- Database: TODO (SwiftData proposed for on-device storage).
- Auth / backend: TODO (none proposed for v0.1).
- Distribution: TestFlight → App Store. Needs an Apple Developer account; bundle ID prefix `app.hourglass` is a placeholder (TODO: confirm).

**Layout**
```
project.yml            # XcodeGen spec (targets, settings, schemes)
Hourglass/App/         # app entry point and root view
Hourglass/Resources/   # asset catalog
HourglassTests/        # unit tests (Swift Testing)
.github/workflows/     # CI
```

## 4. Commands

Keep this list accurate; Claude uses it to verify work. All require macOS with Xcode 16+.

```bash
# install:   brew install xcodegen
# generate:  xcodegen generate            # after every pull or project.yml edit
# dev:       open Hourglass.xcodeproj     # then Run (⌘R) on a simulator
# lint:      xcrun swift-format lint --strict --recursive Hourglass HourglassTests
# format:    xcrun swift-format format --in-place --recursive Hourglass HourglassTests
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

- 2026-11-19 — Generate the Xcode project with XcodeGen and don't commit `.xcodeproj` — avoids `project.pbxproj` merge conflicts with two people pushing to `main`.
- 2026-11-19 — Native iOS with SwiftUI + Swift 6, min iOS 17 — native feel, least code, SwiftData available on 17+.
- 2026-11-19 — Work directly on `main`; shared CLAUDE.md as the single source of project context — keep collaboration simple for a two-person team.

## 8. Gotchas / notes

- Never edit `Hourglass.xcodeproj` settings by hand — they're lost on the next `xcodegen generate`. Change `project.yml` instead. New files under `Hourglass/` are picked up automatically after regenerating.
- Claude cloud sessions run on Linux: they can write Swift but can't build or run it. CI (macOS runner) is the check for that work.
- Signing: set `DEVELOPMENT_TEAM` in `project.yml` once we have the team ID (it isn't a secret).
