# Installing Focus for Codex

Focus uses Codex's native skill discovery. Clone and symlink.

## Installation

1. **Clone the Focus repository:**
   ```bash
   git clone https://github.com/user/focus.git ~/.codex/focus
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/focus/skills ~/.agents/skills/focus
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\focus" "$env:USERPROFILE\.codex\focus\skills"
   ```

3. **Restart Codex** to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/focus
```

You should see a symlink pointing to your Focus skills directory.

## Updating

```bash
cd ~/.codex/focus && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/focus
rm -rf ~/.codex/focus
```
