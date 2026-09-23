# time-left — Agent Instructions

## Project

PrivacyLens — macOS SwiftUI app that shows every installed app's privacy
permissions (TCC) in one searchable list, with deep links into
System Settings → Privacy & Security. Swift sources in `PrivacyLens/`,
build/package scripts in `Scripts/`.

## Workflow Rules

- 🚫 **Never enter act mode or build/modify anything without explicit user permission**
- 📋 Always present a plan first and wait for the user's approval before making any edits or running state-changing commands
- 🔍 Free to explore/read/search the codebase at any time (research only, no changes)

## Default Skills

Always use these skills:

- **Superpowers** → Start with **brainstorming** for any new feature or non-trivial task
- **Ponytail** → Always choose the simplest solution that works (`/ponytail` lite | full | ultra)
- **i-have-adhd** → Always reply in a clear, action-first style (on until "stop adhd mode")
- **apple-design** → Use for any UI / frontend / visual work

### Superpowers skills (auto-select per task)

- `brainstorming` — before new features / non-trivial work
- `writing-plans` / `executing-plans` — planning and batch execution
- `test-driven-development` — tests first for new logic
- `systematic-debugging` — root-cause debugging
- `verification-before-completion` — prove it's fixed before claiming done

### Ponytail commands

- `/ponytail-review` — review diff for over-engineering to delete
- `/ponytail-audit` — audit whole repo, not just diff
- `/ponytail-debt` — ledger of deferred shortcuts
- `/ponytail-help` — command reference

## Skills Installation

Skills live in `.agents/skills/` (gitignored — not committed). Fresh clone? Reinstall with:

```bash
npx skills add obra/superpowers -y
npx skills add DietrichGebert/ponytail -y
npx skills add ayghri/i-have-adhd -y
```

## Preferred commands

**New features:**
`/brainstorming /ponytail /i-have-adhd`

**UI work:**
`/brainstorming /ponytail /apple-design /i-have-adhd`

**Simple tasks:**
`/ponytail /i-have-adhd`

## Response style

- Always include some emoji in responses
- Keep answers clear and easy to scan
- Action first: lead with the next action, number multi-step work, no preamble
