# Reality OS starter (Windows, v0.1)

A starter vault for one person on Windows: a folder of plain Markdown notes that Claude and ChatGPT both work in, under the same five rules. Obsidian is how you read it. Git keeps every change, so nothing an AI does is permanent unless you keep it.

What you get after the first hour:

- Both apps start every session already knowing your work, projects and rules, because they read the same files.
- Neither app changes a note without showing you the change first.
- When you correct one of them, the correction can become a rule, in your wording, that both apps follow from then on.

This is a starting point, not the full Reality OS protocol in the rest of this repository. It keeps four habits from it (read before writing, show before changing, label what's known, keep a trail) and leaves the multi-agent machinery out.

## What you need

- Windows 10 or 11.
- A paid Claude plan (Pro or higher) for the Code tab in the Claude desktop app.
- A ChatGPT account; every ChatGPT plan includes Codex, the part of the ChatGPT app that works on folders on your computer. How much you can use it depends on your plan.
- About an hour.

## The first hour

### 1. Install four things (about 10 minutes)

- **Claude desktop:** download from claude.com/download and sign in.
- **ChatGPT desktop:** install it from the Microsoft Store and sign in.
- **Obsidian:** download from obsidian.md.
- **Git:** open PowerShell (Start menu, type PowerShell) and paste:

  ```powershell
  winget install --id Git.Git -e
  ```

  Close PowerShell when it finishes. If the Claude or ChatGPT app was already open, restart it so it finds Git.

### 2. Get the kit and make your vault (about 5 minutes)

Open a **new** PowerShell window and paste these two lines:

```powershell
git clone https://github.com/cwmorley/reality-os "$HOME\RealityOS-kit"
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\RealityOS-kit\starter\tools\New-Vault.ps1"
```

This makes your vault at `C:\Users\<you>\Vault`, outside OneDrive. If Git hasn't been told your name and email yet, it asks once; they stay on your computer. The script ends with a checklist. Every line should say PASS, except one WARN saying setup isn't finished yet. That's expected.

### 3. Set it up with Claude (about 20 minutes)

1. Open the Claude desktop app and click the **Code** tab.
2. Choose **Select folder** and pick `C:\Users\<you>\Vault`.
3. Leave the permission mode on **Ask** so Claude asks before every edit.
4. Type: `Read _system/SETUP.md and follow it.`

Claude asks eight short questions about your work, one at a time. It shows you every change before it makes it.

### 4. Open it in Obsidian

Open Obsidian, choose **Open folder as vault**, and pick the same folder. `Home.md` is the front page.

### 5. Check that ChatGPT shares the same memory (about 5 minutes)

1. Open the ChatGPT desktop app and open the same folder as a project.
2. Choose **Ask for approval**.
3. Paste: `Read AGENTS.md. In five bullets, tell me what you know about me and my work. Then suggest one improvement to my top project.`

If it describes your work correctly, both apps now read the same memory.

### 6. Do one real task, then correct something

Ask either app for one thing you actually need today. Then correct it on purpose, even something small, and say "log this as a correction." That's how the vault learns your rules.

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

## How you'll know it's working

- You used it on at least 10 of your first 14 days. `_system\Show-Usage.ps1` counts this from the Git history.
- At day 7 and day 14, you can name two things it did that you'd otherwise have done by hand, or not at all.

If either fails, the fix is simpler onboarding, not more features.

## What's not in v0.1

- No extra write gate beyond each app's own approval prompt. Git is the undo.
- No automatic commits. If the apps forget to commit, the fallback is the Obsidian Git plugin on a timer.
- No sync, mobile, or personal-life templates.
