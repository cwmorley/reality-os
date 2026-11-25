# How to work in this vault

This vault is my working memory. Two AI apps work in it: Claude (the Code tab in the Claude desktop app) and ChatGPT (the ChatGPT desktop app). Both read this file, and the same rules apply to both. If you are reading this, these rules apply to you.

## At the start of every session

Read this file, `Home.md`, `Open Loops.md`, the newest note in `Daily/`, and the output of `git log -10 --oneline`. The Git log shows what the other app changed since you were last here. Then read every note you are about to change.

## Starter rules

1. **Read first.** Before acting, read this file and every note you're about to change. If you haven't read it this session, you don't know it.
2. **Show before you change.** Before you change any note outside `_proposals/<your app>/`, tell me what you'll change and why, and make the change only after I say yes. When your app shows me the change in its own approval prompt, my approving it there is the yes; don't ask twice. Four things need no approval: creating today's Daily note from its template, appending one line to it, appending to `Inbox.md`, and adding an entry to `_system/Corrections.md`. After each change, commit it to Git with a one-line message that starts with your app's name (`claude:` or `chatgpt:`). If you can't commit, say so; don't skip it silently.
3. **Label what you know.** Mark claims FACT (with its source), INFERENCE or GUESS. Never invent names, numbers, quotes or results. Repeating an old claim is not new evidence.
4. **Ask before anything leaves this machine or costs money.** Sending, posting, submitting, buying or deleting: ask me every time, even if I said yes before.
5. **Leave a trail.** Before ending a session in which you changed files, add a line to today's Daily note saying what changed, put anything unfinished in `Open Loops.md`, and commit. Decided is not done.

## Standing rules

These come from my corrections, in my exact wording. There are at most 10. They are added only through `_system/Corrections.md`.

_None yet._

## When I correct you

Follow `_system/Corrections.md`. Do not turn a correction into a rule yourself.

## Where things go

| What | Where |
|---|---|
| Anything I want captured and haven't sorted | `Inbox.md` |
| Today's work log, one line per change | `Daily/YYYY-MM-DD.md` (from `Templates/Daily.md`) |
| Anything unfinished, waiting or promised | `Open Loops.md` |
| A piece of work with an outcome | `Projects/<name>.md` (from `Templates/Project.md`) |
| A decision and why | `Decisions/YYYY-MM-DD - <title>.md` |
| A meeting or call | `Meetings/YYYY-MM-DD - <who>.md` |
| A work contact | `People/<name>.md` |
| Everything else | `Notes/` |
| Your drafts, reviews and scratch work | `_proposals/claude/` or `_proposals/chatgpt/` (no approval needed) |

## Two apps, one vault

- The other app may have changed things since your last session. Trust the files and the Git log, not your memory of a past chat.
- When I ask for a second opinion on the other app's work, review it as if you hadn't seen it before. Say what is wrong or missing first. Put the review in your `_proposals/` folder; don't edit the other app's work.
- The two apps agreeing is not evidence that something is true.

## How to work with me

_Filled in during setup._

## Never share

_Filled in during setup. Nothing listed here goes into anything that leaves this machine._
