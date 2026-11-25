# Reality OS starter (Windows, v0.1.1)

A starter vault for one person on Windows: a folder of plain Markdown notes that Claude and ChatGPT both work in, under the same five rules. Obsidian is how you read it. Git keeps a history of every change to your notes, so any change can be undone, and an hourly backup saves the vault and can copy it to a private GitHub repository. Git can't undo things that leave your computer, such as a sent email, which is why rule 4 has the AI ask every time.

What it's designed to do (these are what it's being tested on; see rows S1 to S7 in [VALIDATION.md](../VALIDATION.md)):

- Both apps start every session from the same files about your work, projects and rules.
- Neither app changes your notes without showing you the change first, apart from four small logging edits listed in rule 2.
- When you correct one of them, the correction can become a rule, in your wording, that both apps follow from then on.
- Drafts you'll send as yourself come out in your voice, learned from your own writing.

This is a starting point, not the full Reality OS protocol in the rest of this repository. It keeps four habits from it (read before writing, show before changing, label what's known, keep a trail) and leaves the multi-agent machinery out.

## What you need

- Windows 10 or 11, and permission to install software.
- A paid Claude plan (Pro or higher) for the Code tab in the Claude desktop app.
- A ChatGPT account. As of November 2026, OpenAI says every ChatGPT plan includes Codex, the part of the ChatGPT app that works on folders on your computer; how much you can use it depends on the plan.
- Optional: a free GitHub account, for the cloud backup.
- About an hour and a quarter.

If you're on a work computer, check that you're allowed to put work notes into these apps (and into GitHub, for the backup) before you start.

## The first hour

### 1. Run the installer (about 10 minutes)

Open PowerShell (Start menu, type PowerShell) and paste this one line:

```powershell
irm https://raw.githubusercontent.com/cwmorley/reality-os/main/starter/install.ps1 | iex
```

It does five things:

1. Installs Git, Obsidian, the Claude desktop app and the ChatGPT desktop app, skipping any you already have.
2. Downloads the kit to `C:\Users\<you>\RealityOS-kit`.
3. Makes your vault at `C:\Users\<you>\Vault`, outside OneDrive.
4. Turns on the hourly backup.
5. Adds the vault to Obsidian.

Windows may ask once or twice whether to let an installer make changes; say yes. If Git hasn't been told your name and email yet, it asks once, and they stay on your computer.

The installer ends with a checklist. Every line should say PASS, apart from two expected WARN lines: setup isn't finished yet, and the backup hasn't run yet. You can [read the installer](./install.ps1) before running it. Running it again is safe, because it never overwrites your vault.

Then open the Claude app and the ChatGPT app once each and sign in.

Prefer to do it by hand? See [Installing by hand](#installing-by-hand).

### 2. Set it up with Claude (about 30 to 40 minutes)

1. In the Claude desktop app, click the **Code** tab.
2. In the environment selector, choose **Local** (your computer, not the cloud). Then choose **Open folder…** and pick `C:\Users\<you>\Vault`. If Claude asks whether you trust this folder, say yes; the vault's settings only take effect once you do.
3. Leave the permission mode on its default, **Manual**, which asks before every edit. The vault already lets Claude run Git and its check scripts without asking, so the prompts you see are about your notes. Even the small logging edits show a prompt; approve them.
4. Type: `Read _system/SETUP.md and follow it.`

Claude asks eight short questions about your work, one at a time. First it offers a head start: if another AI already knows things about your work, or you keep work files in folders, Claude can use those to fill in some answers for you to confirm. Each answer becomes a change that Claude shows you in an approval prompt. Approving it there is all you need to do.

### 3. Open it in Obsidian

Open Obsidian. Your vault is already there, and `Home.md` is the front page. To insert templates from inside Obsidian, turn on the Templates core plugin in Settings.

### 4. Check that ChatGPT shares the same memory (about 10 minutes)

1. In the ChatGPT desktop app, open the vault folder (Ctrl+O).
2. Choose **Ask for approval** below the message box.
3. Paste: `Read AGENTS.md. In five bullets, tell me what you know about me and my work. Then suggest one improvement to my top project.`

If it describes your work correctly, both apps are reading the same memory. ChatGPT shows you each change in chat and waits for your yes (rule 2). Its sandbox treats the `.git` folder as read-only by default, so expect it to ask permission each time it commits. If it can't commit at all, the hourly backup saves its changes, or Claude commits them at **Wrap up**.

### 5. Do one real task

Ask either app for one thing you actually need today. If it gets something wrong, say what you wanted instead and "log this as a correction." That's how the vault learns your rules.

## Every day after that

The prompts are in `Prompts.md` in your vault. These do most of the work:

- **Start my day:** the AI reads your open loops and yesterday's notes and tells you the one thing to do first.
- **Wrap up:** the AI logs what changed, carries unfinished work into `Open Loops.md`, and commits.
- **Learn my voice:** do this the first time you want something drafted as you. You paste 3 to 5 things you wrote yourself, and both apps then draft in your voice from `Voice.md`. When you rewrite one of their drafts, they offer to update it.
- **Second opinion:** one app reviews what the other did.
- **Weekly review:** once a week.

## Back it up to the cloud (do this in your first week)

Your vault already saves itself every hour on your computer. A scheduled task commits anything left unsaved, including edits you make yourself in Obsidian, as `auto: snapshot`. To also keep a copy in the cloud, so it survives a dead laptop:

1. On github.com, create a new **private**, empty repository, for example `my-vault`. Don't add a README.
2. In PowerShell, paste this, with your repository's address:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Vault\_system\Enable-Backup.ps1" -Remote https://github.com/<you>/my-vault.git
   ```

   A GitHub sign-in opens in your browser this once. After that, the hourly backup also pushes to GitHub without asking.

**Why GitHub and not OneDrive:** the vault's history lives in a hidden `.git` folder, and sync apps like OneDrive can corrupt it mid-sync. GitHub stores that history properly.

The backup never saves or pushes anything that looks like a password or API key. If it finds one in a note, it stops, and `Test-Vault.ps1` tells you which note. Keep keys in the app or service they belong to, never in notes. To turn the backup off, run `Enable-Backup.ps1 -Disable`.

## What's in your vault

| Note or folder | What it's for |
|---|---|
| `Home.md` | Front page: active projects and this week |
| `Inbox.md` | Anything you want captured, unsorted |
| `Open Loops.md` | Everything unfinished, waiting or promised |
| `Daily/` | One note per day, with a log of what changed |
| `Projects/`, `Decisions/`, `Meetings/`, `People/`, `Notes/` | Your work, sorted |
| `About.md` | Who you are at work, your goals, your tools |
| `Voice.md` | How you write, so drafts sound like you |
| `AGENTS.md` | The rules both apps follow, and your standing rules |
| `Prompts.md` | The prompts you copy into either app |
| `_system/` | Setup, the corrections process, and the check and backup scripts |
| `_proposals/` | Each app's drafts and reviews, outside your notes |

## Installing by hand

1. Install the Claude desktop app (claude.com/download), the ChatGPT desktop app (Microsoft Store) and Obsidian (obsidian.md).
2. In PowerShell, run `winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements`, then close PowerShell. If the Claude or ChatGPT app was open, restart it so it finds Git.
3. In a new PowerShell window:

   ```powershell
   git clone https://github.com/cwmorley/reality-os "$HOME\RealityOS-kit"
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\RealityOS-kit\starter\tools\New-Vault.ps1"
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Vault\_system\Enable-Backup.ps1"
   ```

4. In Obsidian, choose **Open folder as vault** and pick `C:\Users\<you>\Vault`. Then carry on from step 2 of the first hour.

## If something goes wrong

- **Check the vault:** run `powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Vault\_system\Test-Vault.ps1"`. Each FAIL line says what to do.
- **Undo the last change:** ask either app to revert its last commit, or run `git -C "$HOME\Vault" revert --no-edit HEAD`.
- **"Running scripts is disabled on this system":** run the script with `powershell -NoProfile -ExecutionPolicy Bypass -File ...`, as shown above. That applies to that one command only; your system setting doesn't change.
- **The Code tab asks for Git:** install Git (step 2 of Installing by hand) and restart the Claude app.
- **ChatGPT can't commit:** the hourly backup saves its changes anyway, or Claude commits them at **Wrap up**. If Test-Vault reports *dubious ownership*, run the `safe.directory` command it prints.
- **The cloud backup stopped:** if Test-Vault says the last push didn't go through, run `git -C "$HOME\Vault" push` once. If GitHub wants you to sign in again, a browser window opens.

## How you'll know it's working

- You used it on at least 10 of your first 14 days. `_system\Show-Usage.ps1` counts this from the Git history and leaves out the automatic backups.
- At day 7 and day 14, you can name two things it did that you'd otherwise have done by hand, or not at all.

If either fails, the fix is simpler onboarding, not more features.

## Not in this version

- No extra write gate beyond each app's own approval prompt. Git is the undo.
- No API keys. Both apps run on their own subscriptions, and nothing in the kit calls an API.
- No syncing between two computers or into a phone app. The GitHub backup is a one-way copy.
- No personal-life templates.
