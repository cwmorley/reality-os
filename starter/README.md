# Reality OS starter (Windows, v0.1)

A starter vault for one person on Windows: a folder of plain Markdown notes that Claude and ChatGPT both work in, under the same five rules. Obsidian is how you read it. Git keeps a history of every committed change to your notes, so any of them can be undone. (Git can't undo things that leave your computer, like a sent email; that's why rule 4 says the AI asks every time.)

What it's designed to do after the first hour (these are the things it is being tested on; see S1 to S5 in [VALIDATION.md](../VALIDATION.md)):

- Both apps start every session from the same files about your work, projects and rules.
- Neither app changes your notes without showing you the change first, apart from four small logging actions listed in rule 2.
- When you correct one of them, the correction can become a rule, in your wording, that both apps follow from then on.

This is a starting point, not the full Reality OS protocol in the rest of this repository. It keeps four habits from it (read before writing, show before changing, label what's known, keep a trail) and leaves the multi-agent machinery out.

## What you need

- Windows 10 or 11.
- A paid Claude plan (Pro or higher) for the Code tab in the Claude desktop app.
- A ChatGPT account. As of November 2026, OpenAI says every ChatGPT plan includes Codex, the part of the ChatGPT app that works on folders on your computer; how much you can use it depends on the plan.
- About an hour and a quarter.

## The first hour

### 1. Run the installer (about 10 minutes)

Open PowerShell (Start menu, type PowerShell) and paste this one line:

```powershell
irm https://raw.githubusercontent.com/cwmorley/reality-os/main/starter/install.ps1 | iex
```

It installs Git, Obsidian, the Claude desktop app and the ChatGPT desktop app (skipping any you already have), downloads the kit to `C:\Users\<you>\RealityOS-kit`, makes your vault at `C:\Users\<you>\Vault` (outside OneDrive), turns on an hourly automatic backup, and adds the vault to Obsidian. Windows may ask once or twice whether to let an installer make changes; say yes. If Git hasn't been told your name and email yet, it asks once; they stay on your computer.

It ends with a checklist. Every line should say PASS, except one WARN saying setup isn't finished yet. That's expected. You can [read the installer](./install.ps1) before running it, and running it again is safe: it never overwrites your vault.

Then open the Claude app and the ChatGPT app once each and sign in.

Prefer to do it by hand? See [Installing by hand](#installing-by-hand) below.

### 2. Set it up with Claude (about 30 to 40 minutes)

1. In the Claude desktop app, click the **Code** tab.
2. In the environment selector choose **Local** (on your computer, not the cloud), then **Open folder…** and pick `C:\Users\<you>\Vault`. If Claude asks whether you trust this folder, say yes; that's what lets the vault's settings take effect.
3. Leave the permission mode on its default (**Manual**), which asks before every edit. The vault already allows Claude to run Git and its two check scripts without asking, so the prompts you see are about your notes. Even small logging edits show a prompt; approve them.
4. Type: `Read _system/SETUP.md and follow it.`

Claude asks eight short questions about your work, one at a time. Each answer turns into a change that Claude shows you in an approval prompt; approving it there is all you need to do.

### 3. Open it in Obsidian

Open Obsidian. Your vault is already there; `Home.md` is the front page. To insert the templates from inside Obsidian, turn on the Templates core plugin in Settings.

### 4. Check that ChatGPT shares the same memory (about 10 minutes)

1. In the ChatGPT desktop app, open the vault folder (Ctrl+O).
2. Choose **Ask for approval** below the message box.
3. Paste: `Read AGENTS.md. In five bullets, tell me what you know about me and my work. Then suggest one improvement to my top project.`

If it describes your work correctly, both apps read the same memory. ChatGPT shows you each change in chat and waits for your yes (rule 2). Its sandbox treats the `.git` folder as read-only by default, so expect it to ask permission each time it commits; if it can't commit at all, let Claude commit at **Wrap up**. The **Second opinion** prompt in `Prompts.md` is the reason to have both: one app reviews what the other did.

### 5. Do one real task

Ask either app for one thing you actually need today. If it gets something wrong, say what you wanted instead and "log this as a correction." That's how the vault learns your rules.

## Back it up to the cloud (do this in your first week)

The vault already saves itself every hour on your computer: a scheduled task commits anything left unsaved (including edits you make yourself in Obsidian) as `auto: snapshot`. To also keep a copy in the cloud, so it survives a dead laptop and Claude on the web or your phone can open it:

1. On github.com (free account), create a new **private**, empty repository, for example `my-vault`. Don't add a README.
2. In PowerShell, paste, with your repository's address:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Vault\_system\Enable-Backup.ps1" -Remote https://github.com/<you>/my-vault.git
   ```

   A GitHub sign-in opens in your browser once. After that the hourly backup also pushes to GitHub, with no prompts.

Why GitHub and not OneDrive: the vault's history lives in a hidden `.git` folder, and sync apps like OneDrive can corrupt it mid-sync. GitHub stores that history properly. If you use a work computer, check you're allowed to keep work notes in a private GitHub repository first.

The backup never pushes anything that looks like a password or API key; if it finds one in a note, it stops and `Test-Vault.ps1` tells you which note. Keep keys in the app or service they belong to, never in notes. To turn the backup off: `Enable-Backup.ps1 -Disable`.

## Installing by hand

1. Install the Claude desktop app (claude.com/download), the ChatGPT desktop app (Microsoft Store) and Obsidian (obsidian.md).
2. In PowerShell: `winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements`, then close PowerShell. Restart the Claude or ChatGPT app if it was open, so it finds Git.
3. In a new PowerShell window:

   ```powershell
   git clone https://github.com/cwmorley/reality-os "$HOME\RealityOS-kit"
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\RealityOS-kit\starter\tools\New-Vault.ps1"
   ```

4. Turn on the automatic backup: `powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Vault\_system\Enable-Backup.ps1"`
5. In Obsidian, choose **Open folder as vault** and pick `C:\Users\<you>\Vault`. Then carry on from step 2 of the first hour.

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
- No API keys. Both apps run on their own subscriptions; nothing in the kit calls an API.
- No syncing between two computers or into a phone app. The GitHub backup is a one-way copy.
- No personal-life templates.
