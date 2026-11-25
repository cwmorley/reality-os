# Setup (for the AI to follow)

You are setting up this vault with its owner. It takes about 20 minutes. Follow these steps in order. Use plain language: the owner has not used a setup like this before.

## 0. Check the vault

Run:

```
powershell -NoProfile -ExecutionPolicy Bypass -File _system\Test-Vault.ps1
```

If any line says FAIL, stop. Tell the owner exactly which check failed and what the script says to do. Do not work around it.

## 1. Say what's about to happen

In three or four lines: you'll ask eight short questions, one at a time. Each answer becomes a few lines in a note. You'll show the exact text before writing anything, and nothing is written until he says yes. Every change is saved in Git, so any of it can be undone.

## 2. Ask the questions, one at a time

After each answer: show the exact text and the file it goes in, wait for yes, write it, then commit with `claude: setup - <file>` (or `chatgpt:` if you are ChatGPT).

| # | Ask | Write to |
|---|---|---|
| 1 | What should I call you, and what's your work, in two lines? | `About.md` under Me |
| 2 | What are you working toward in the next 90 days? | `About.md` under Goals |
| 3 | What are your top three active projects? For each: what does done look like, and what's the next step? | One note per project in `Projects/`, from `Templates/Project.md`, each linked from `Home.md` under Active projects |
| 4 | Which tools and accounts do you use for work, and which of them may I touch? | `About.md` under Tools and accounts |
| 5 | How should I talk to you: length, tone, what annoys you? | `AGENTS.md` under How to work with me, in his words |
| 6 | What must never appear in anything that leaves this machine? | `AGENTS.md` under Never share, in his words |
| 7 | Who do you work with often? (Optional; work contacts only.) | One note per person in `People/`, from `Templates/Person.md` |
| 8 | What do you want done today? | Today's note in `Daily/` from `Templates/Daily.md`, and anything unfinished in `Open Loops.md` |

Keep this about work. Do not ask about health, relationships or money. If he volunteers something personal, don't write it down unless he asks you to.

When you fill a template, replace `{{date}}` with today's date (YYYY-MM-DD) and `{{title}}` with the note's name.

## 3. Finish

1. Remove the line `(fill in during setup)` from `About.md`.
2. In `Home.md`, replace the Setup line with `Setup: done YYYY-MM-DD.`
3. Run `_system\Test-Vault.ps1` again. Every line should say PASS. Show him the result.
4. Commit.

## 4. One correction, on purpose

Ask him to correct something you did, even something small, so he sees how a correction becomes a rule. Follow `_system/Corrections.md`.

## 5. Next steps for him

Tell him:

1. Open Obsidian, choose **Open folder as vault**, and pick this folder. `Home.md` is the front page.
2. Open the ChatGPT desktop app, open this same folder as a project, choose **Ask for approval**, and paste: "Read AGENTS.md. In five bullets, tell me what you know about me and my work. Then suggest one improvement to my top project." If ChatGPT describes his work correctly, both apps now share the same memory.
3. Tomorrow, start with the **Start my day** prompt in `Prompts.md`, and end with **Wrap up**.
