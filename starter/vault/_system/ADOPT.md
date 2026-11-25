# Adopting an existing vault (ALPHA, for the AI to follow)

This vault existed before Reality OS. The owner's notes, folders and format come first. Your job is to learn how this vault is organized, map Reality OS onto it, and add the rules, without moving, renaming or rewriting their notes. It takes about 30 to 45 minutes. Get approval as AGENTS.md rule 2 says, and run every command below exactly as written, from the vault folder.

The snapshot commit `adopt: before Reality OS` holds the vault as it was before Reality OS, so any of this can be undone.

## 0. Check

Run:

```
powershell -NoProfile -ExecutionPolicy Bypass -File _system/Test-Vault.ps1
```

WARN lines about adoption not being finished, AGENTS.md rules, CLAUDE.md or the backup are expected now. If any line says FAIL, stop and tell the owner what it says. Run `date +%F` (or `Get-Date -Format yyyy-MM-dd`) and use that date below.

## 1. Say what's about to happen

In four lines: you'll look at how the vault is organized without changing anything, show what you found, agree with them which notes do which job, and then add the Reality OS rules in their format. You won't move, rename or rewrite their notes, and every change is shown before it's made.

## 2. Survey (read only)

1. List the folders, two levels deep, and count the notes in each.
2. Read `.obsidian/daily-notes.json` and `.obsidian/templates.json` if they exist, every file in the templates folder, and any existing `AGENTS.md`, `CLAUDE.md` or README.
3. Read only the frontmatter and the first 30 lines of up to 12 notes: the 3 newest, the 3 oldest, and the rest spread across the biggest folders. Before reading in any folder that looks personal (a journal, health, money, family), ask the owner whether you may, and skip it if they don't answer yes.
4. Write `_proposals/claude/Vault survey.md` with:
   - each top folder and what it seems to be for;
   - the note formats you found: frontmatter fields (with how many of the sampled notes use each), heading order, link style (`[[wiki links]]` or `[markdown](links)`), date format, tags;
   - where the format varies (for example handwritten notes versus AI-written ones), with one example path for each variant;
   - notes that already do the job of a front page, an inbox, an open-loops or task list, and an about-me note;
   - anything that conflicts with the Reality OS rules.

   Label each finding FACT (with the path) or INFERENCE. Commit it with `claude: adopt - survey`.

## 3. Agree the map

Show a short summary of the survey, then ask, one at a time:

1. Which note is your front page? Which is your inbox? Which is your list of open or promised things? Which describes you and your work? For each, use their existing note, or offer to create one (the structures are below).
2. Where do daily notes go, and what's the filename format?
3. Which folder holds templates?
4. Which folders hold work you'd want me to file into?
5. Where the format varies: which version is the one new notes should follow?

Write the answers into `_system/vault.json` (keys `home`, `inbox`, `openLoops`, `about`, `daily`, `templates`, `folders`; paths are relative to the vault, with forward slashes). Show the change, then commit.

If you create a note they didn't have, use these structures:

- Front page: a title, `## Active projects` (links only), `## This week`.
- Inbox: a title and one line saying it's for unsorted captures.
- Open loops: a title, a line saying "one line each: what, who, and a date only if one was given", then `## Mine to do`, `## Waiting on someone`, `## Promised to someone`.
- About: `## Me`, `## Goals for the next 90 days`, `## Tools and accounts`.

## 4. The rules

1. **AGENTS.md.**
   - If Adopt-Vault created it, rewrite only its "At the start of every session" and "Where things go" sections so they name this vault's real notes and folders, and the four exemptions in rule 2 so they name the real daily-notes folder, inbox and corrections file.
   - If the owner already had an AGENTS.md, merge instead. Keep all of their content, and add the Reality OS sections from `_proposals/claude/AGENTS.reality-os.md`, with the five starter rules worded exactly as there. Show the whole result before saving.
2. **CLAUDE.md.** If `_proposals/claude/CLAUDE.reality-os.md` exists, the owner had their own file. Show them the one line it adds (`@AGENTS.md`) and save it only if they approve.
3. **`.claude/settings.json`.** If `_proposals/claude/settings.reality-os.json` exists, merge its `allow` list into theirs, show the result, and save it only if they approve.
4. **House style.** Replace the House style section in AGENTS.md with the format they chose in step 3: frontmatter fields, heading order, link style, date format and tags, in a few lines. New notes follow it. Existing notes are not reformatted, unless the owner asks with the **Tidy a folder** prompt.
5. **How to work with me** and **Never share.** Always ask these two (SETUP.md questions 5 and 6), even if the vault seems to answer them, because they are rules.
6. If they have no about-me note, ask SETUP.md questions 1, 2 and 4 for it.

Commit after each item with `claude: adopt - <short name>`.

## 5. Finish

1. In `_system/vault.json`, set `"adoption": "done"`. Show the change and commit.
2. Run `git status --short` and `git log -5 --oneline` and show both.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File _system/Test-Vault.ps1`. Every line should say PASS, except perhaps a WARN about the backup. Show the result.
4. Tell them what comes next:
   - **Start my day** and **Wrap up** in the prompts note, from tomorrow.
   - **Learn my voice**, the first time they want something drafted as themselves.
   - Connecting the cloud backup (the kit README's "Back it up to the cloud").
   - Opening the vault in the ChatGPT app (Ctrl+O, Ask for approval) so both apps share it.

## Never, during adoption

- Move, rename or delete a note, or rewrite its body.
- Change frontmatter on existing notes.
- Read a folder that looks personal without a yes.
- Copy note contents into the survey beyond the short examples it needs.
