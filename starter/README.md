# Reality OS starter (Windows, v0.1)

A starter vault for one person on Windows: a folder of plain Markdown notes that Claude and ChatGPT both work in, under the same five rules. Obsidian is how you read it. Git keeps a history of every committed change to your notes, so any of them can be undone. (Git can't undo things that leave your computer, like a sent email; that's why rule 4 says the AI asks every time.)

What it's designed to do after the first hour (these are the things it is being tested on; see S1 to S5 in [VALIDATION.md](../VALIDATION.md)):

- Claude (and later ChatGPT, if you add it) starts every session from the same files about your work, projects and rules.
- Neither app changes your notes without showing you the change first, apart from four small logging actions listed in rule 2.
- When you correct one of them, the correction can become a rule, in your wording, that both apps follow from then on.

This is a starting point, not the full Reality OS protocol in the rest of this repository. It keeps four habits from it (read before writing, show before changing, label what's known, keep a trail) and leaves the multi-agent machinery out.

## What you need

- Windows 10 or 11.
- A paid Claude plan (Pro or higher) for the Code tab in the Claude desktop app.
- A ChatGPT account, optional for the first week. As of November 2026, OpenAI says every ChatGPT plan includes Codex, the part of the ChatGPT app that works on folders on your computer; how much you can use it depends on the plan.
- About an hour and a quarter.

## The first hour

### 1. Install four things (about 10 minutes)

- **Claude desktop:** download from claude.com/download and sign in.
- **ChatGPT desktop:** install it from the Microsoft Store and sign in.
- **Obsidian:** download from obsidian.md.
- **Git:** open PowerShell (Start menu, type PowerShell) and paste:

  ```powershell
  winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
  ```

  Windows may ask whether to let the installer make changes; say yes. Close PowerShell when it finishes. If the Claude or ChatGPT app was already open, restart it so it finds Git.

### 2. Get the kit and make your vault (about 5 minutes)

Open a **new** PowerShell window and paste these two lines:

```powershell
git clone https://github.com/cwmorley/reality-os "$HOME\RealityOS-kit"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\RealityOS-kit\starter\tools\New-Vault.ps1"
```

This makes your vault at `C:\Users\<you>\Vault`, outside OneDrive. If Git hasn't been told your name and email yet, it asks once; they stay on your computer. The script ends with a checklist. Every line should say PASS, except one WARN saying setup isn't finished yet. That's expected.

### 3. Set it up with Claude (about 20 minutes)

1. Open the Claude desktop app and click the **Code** tab.
2. In the environment selector choose **Local** (on your computer, not the cloud), then **Open folder…** and pick `C:\Users\<you>\Vault`. If Claude asks whether you trust this folder, say yes; that's what lets the vault's settings take effect.
3. Leave the permission mode on its default (**Manual**), which asks before every edit. The vault already allows Claude to run Git and its two check scripts without asking, so the prompts you see are about your notes. Even small logging edits show a prompt; approve them.
4. Type: `Read _system/SETUP.md and follow it.`

Claude asks eight short questions about your work, one at a time, which takes about 30 to 40 minutes. Each answer turns into a change that Claude shows you in an approval prompt; approving it there is all you need to do.

### 4. Open it in Obsidian

Open Obsidian, choose **Open folder as vault**, and pick the same folder. `Home.md` is the front page. To insert the templates from inside Obsidian, turn on the Templates core plugin in Settings.

### 5. Do one real task

Ask Claude for one thing you actually need today. If it gets something wrong, say what you wanted instead and "log this as a correction." That's how the vault learns your rules.

## After your first week: add ChatGPT (optional)

Use Claude alone for the first week. When you want a second app on the same notes:

1. Open the ChatGPT desktop app and open the vault folder (Ctrl+O).
2. Choose **Ask for approval** below the message box.
3. Paste: `Read AGENTS.md. In five bullets, tell me what you know about me and my work. Then suggest one improvement to my top project.`

If it describes your work correctly, both apps read the same memory. ChatGPT shows you each change in chat and waits for your yes (rule 2). Its sandbox treats the `.git` folder as read-only by default, so expect it to ask permission each time it commits; if it can't commit at all, let Claude commit at **Wrap up**. The **Second opinion** prompt in `Prompts.md` is the reason to have both: one app reviews what the other did.

## Every day after that

The prompts are in `Prompts.md` in your vault. Two do most of the work:

- **Start my day:** the AI reads your open loops and yesterday's notes and tells you the one thing to do first.
- **Wrap up:** the AI logs what changed, carries unfinished work into `Open Loops.md`, and commits.

Once a week, run the **Weekly review** prompt.

## If something goes wrong

- **Check the vault:** `powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Vault\_system\Test-Vault.ps1"`. Each FAIL line says what to do.
- **Undo the last change:** ask either app to "undo your last commit," or run `git -C "$HOME\Vault" revert --no-edit HEAD`.
- **"Running scripts is disabled on this system":** run the script with `powershell -NoProfile -ExecutionPolicy Bypass -File ...` as shown above. That only affects that one command; your system setting doesn't change.
- **The Code tab asks for Git:** install Git (step 1) and restart the Claude app.
- **ChatGPT can't commit:** say so in the chat and let Claude commit at **Wrap up**, or commit yourself with `git -C "$HOME\Vault" add -A; git -C "$HOME\Vault" commit -m "manual: save"`. If Test-Vault reports *dubious ownership*, run the `safe.directory` command it prints.

## How you'll know it's working

- You used it on at least 10 of your first 14 days. `_system\Show-Usage.ps1` counts this from the Git history.
- At day 7 and day 14, you can name two things it did that you'd otherwise have done by hand, or not at all.

If either fails, the fix is simpler onboarding, not more features.

## What's not in v0.1

- No extra write gate beyond each app's own approval prompt. Git is the undo.
- No automatic commits. If the apps forget to commit, the fallback is the Obsidian Git plugin on a timer.
- No sync, mobile, or personal-life templates.
