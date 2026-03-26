# Installing Focus for OpenCode

## Installation

Add Focus to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["focus@git+https://github.com/user/focus.git"]
}
```

Restart OpenCode. The plugin auto-installs and registers the skill.

Verify by asking: "Tell me about Focus"

## Usage

Use OpenCode's native `skill` tool:

```
use skill tool to list skills
use skill tool to load focus
```

## Updating

Focus updates automatically when you restart OpenCode.

To pin a specific version:

```json
{
  "plugin": ["focus@git+https://github.com/user/focus.git#v1.0.0"]
}
```

## Uninstalling

Remove the `focus` entry from the `plugin` array in `opencode.json`.
