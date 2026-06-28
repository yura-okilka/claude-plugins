# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A personal Claude Code **plugin marketplace** — a catalog of independent plugins.

## Key Rules

- **The top-level README.md must be kept up to date** — each plugin's full docs live in its
  `### <plugin>` section there — whenever behavior, hooks, or install steps change. It is the
  primary user doc.
- Content is MIT-licensed. This is a personal project by Yura Okilka.
- **No personal configuration** — scripts must be generic, with no hardcoded personal
  paths, machine-specific settings, or editor preferences.
- **Self-contained** — documentation and scripts must refer only to what exists in this
  repository, not a user's personal Claude Code setup.

## Conventions

- Hook scripts use `${CLAUDE_PLUGIN_ROOT}` for path resolution when running as a plugin. The
  plugin system copies files to a cache location during install, so absolute/relative paths
  won't work.
- **Versioning** — each plugin has its own `version` in `plugins/<plugin>/.claude-plugin/plugin.json`.
  Bump independently per plugin, then push to `main` to ship. Use semver: patch for bug
  fixes, minor for new features, major for breaking changes. **Bump triggers on any change to
  bundled plugin content** — hooks, scripts, icons — not just `.claude-plugin/` files.
  Anything shipped to consumers via the plugin is a release artifact.
- **Changelog** — when bumping a plugin version, update `CHANGELOG.md` in the same change.
  Version headings use the plugin name and version
  (e.g. `## toast-notify v1.0.0 - YYYY-MM-DD`), not tags. Keep entries grouped: New Features,
  Improvements, Bug Fixes, Other.
- **PowerShell** — hooks run under `powershell.exe` (Windows PowerShell 5.1), not `pwsh` 7,
  because the WinRT toast APIs require it; the hook commands hardcode `powershell.exe`. Keep
  `.ps1` and `.vbs` files CRLF in the working tree (enforced by `.gitattributes`); do not
  normalize them to LF.

## Structure

- `.claude-plugin/marketplace.json` — marketplace catalog listing all plugins
- `plugins/` — each subdirectory is an independent plugin:
  - `plugins/toast-notify/` — Windows desktop notifications with click-to-focus
- Each plugin has its own `.claude-plugin/plugin.json` and standard subdirectories
  (`hooks/`) as needed.

## Local Plugin Development

- **Testing locally** — use `claude --plugin-dir plugins/<name>` to load a local plugin
  without publishing. Use `/reload-plugins` inside a session to pick up file changes without
  restarting.
- **Updating marketplace cache** — plugin hooks are read from
  `~/.claude/plugins/marketplaces/`, not `cache/`. When manually testing changes, copy files
  to the marketplace path.
