# Setup (for the AI to follow)

You are setting up this vault with its owner. It takes about 30 to 40 minutes. Follow these steps in order. Use plain language: the owner has not used a setup like this before. Get approval as AGENTS.md rule 2 says. Run every command below exactly as written, from the vault folder.

## 0. Check the vault

Run:

```
powershell -NoProfile -ExecutionPolicy Bypass -File _system/Test-Vault.ps1
```

A WARN saying setup isn't finished is expected; ignore it. If any line says FAIL, stop: tell the owner exactly which check failed and what the script says to do. Do not work around it.

Run `date +%F` (or `Get-Date -Format yyyy-MM-dd`) and use that date everywhere below.

## 1. Say what's about to happen

In three or four lines: you'll ask eight short questions, one at a time. Each answer becomes a few lines in a note, and they'll see and approve each change before it's written. Every change is saved in Git, so any of it can be undone.

## 2. Ask the questions, one at a time

After each question's changes, commit them with `claude: setup - <short name>` (for example `claude: setup - projects`), or `chatgpt:` if you are ChatGPT.

| # | Ask | Write to |
|---|---|---|
| 1 | What should I call you, and what's your work, in two lines? | `About.md` under Me. In the same edit, delete the line `(fill in during setup)`. |
| 2 | What are you working toward in the next 90 days? | `About.md` under Goals |
| 3 | What are your top three active projects? For each: what does done look like, and what's the next step? | One note per project, `Projects/<Project name>.md`, from `Templates/Project.md`. After the third, add all three to `Home.md` under Active projects in one edit, as links only (`- [[Project name]]`), and delete the `_Added during setup._` line. |
| 4 | Which tools and accounts do you use for work, and which of them may I touch? | `About.md` under Tools and accounts |
| 5 | How should I talk to you: length, tone, what annoys you? | `AGENTS.md` under How to work with me, in their words |
| 6 | What must never appear in anything that leaves this machine? | `AGENTS.md` under Never share, in their words |
| 7 | Who do you work with often? (Optional; work contacts only.) | One note per person, `People/<Name>.md`, from `Templates/Person.md` |
| 8 | What do you want done today, and what matters most this week? | Today's note in `Daily/` from `Templates/Daily.md`, with Today filled in and one Log line: `Setup with Claude: <the notes filled in>` (that line is the trail for all of setup). Anything unfinished goes in `Open Loops.md`; something promised to a named person goes under Promised to someone. In `Home.md`, replace the This week placeholder with one line from the answer and the Setup line with `Setup: done YYYY-MM-DD.` |

How to handle answers:

- If an answer is too vague to check later, ask one follow-up ("What would someone see on the day it's done?"), then write what you have.
- Never invent a date. If they didn't give one, write "no date".
- Keep this about work. Don't ask about health, relationships or money. If the owner mentions something personal, say once "I won't note that" and carry on. Don't write it down, and don't let it show up indirectly (no "left early", no dates built around it) in any note or commit message, unless they ask you to record it.
- When you fill a template, replace `{{date}}` with today's date and `{{title}}` with the note's name.

## 3. Check

1. Run `git status --short` and `git log -5 --oneline` and show both. If anything is uncommitted, say so and commit it.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File _system/Test-Vault.ps1` again. Every line should say PASS. Show the owner the result.

## 4. Offer one correction

Offer, don't insist: "Want to see how corrections work? Pick any line I wrote today that you'd word differently, or tell me to make one shorter or plainer." If they take it, follow `_system/Corrections.md`. If not, tell them they can do it any time with the **Correct it** prompt in `Prompts.md`.

## 5. Next steps for the owner

Tell them:

1. Open Obsidian. The vault is already listed if they used the installer; otherwise choose **Open folder as vault** and pick this folder. `Home.md` is the front page.
2. Open the ChatGPT desktop app, open this same folder (Ctrl+O), choose **Ask for approval**, and paste: "Read AGENTS.md. In five bullets, tell me what you know about me and my work. Then suggest one improvement to my top project." If ChatGPT describes their work correctly, both apps now share the same memory.
3. Tomorrow, start with the **Start my day** prompt in `Prompts.md`, and end with **Wrap up**.
