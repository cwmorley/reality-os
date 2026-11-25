# Prompts

Copy one of these into Claude or ChatGPT. They work the same in both apps.

## Start my day

> Start of day. Read AGENTS.md, Home.md, Open Loops.md, the newest Daily note and `git log -10 --oneline`. Create today's Daily note from Templates/Daily.md. Then tell me in under 10 lines: what's open, what's due or overdue, and the one thing you'd do first and why.

## Capture

> Inbox: [whatever is on your mind]

Then later:

> Sort my Inbox. Move each item to the note it belongs in, following AGENTS.md, then commit.

## Wrap up

> Wrap up. Add to today's Daily note what changed today, move anything unfinished into Open Loops.md, and update the Next step on any project that moved. Then commit.

## Learn my voice

> Learn my voice. I'll paste 3 to 5 things I wrote myself, without AI: emails, messages or posts. Ask me for them one at a time. Then fill in Voice.md from them: how I write, words and phrases I use, things I never do, and how my tone changes by audience. Show me the result before you save it. Don't save the samples themselves.

## Tidy a folder

> Tidy [folder] to my house style. Change only frontmatter and headings, never the body text. Show me up to 10 notes at a time, each with its change, and apply only the ones I approve. Commit after each batch.

## Second opinion

Use this in the *other* app from the one that did the work, once you use two apps:

> Second opinion. Read what changed today (`git log --since=midnight --stat`) and the notes it touched. Tell me what's wrong, missing or overstated first, then what's good. Don't change those notes. Put your review in your _proposals folder and commit it.

## Correct it

> That's wrong: [what it did]. What I want instead: [what you want]. Log this as a correction.

## Weekly review

> Weekly review. Run `powershell -NoProfile -ExecutionPolicy Bypass -File _system/Show-Usage.ps1`, then fill a new note from Templates/Weekly Review.md. Go through Open Loops.md and _system/Corrections.md with me.
