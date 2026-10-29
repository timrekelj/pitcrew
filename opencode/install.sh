#!/usr/bin/env bash
# Installs the pitcrew skills, commands and agents into OpenCode's global config.
# Copies files (not symlinks) so OpenCode uses optimized versions independent of this repo.
# Re-run after updating skills, commands or agents.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

mkdir -p "$config/skills" "$config/commands" "$config/agents"

copy_dir() {
  local src="$1" dest="$2"
  if [ -d "$src" ]; then
    for item in "$src"/*/; do
      [ -d "$item" ] || continue
      local name="$(basename "$item")"
      rm -rf "$dest/$name"
      cp -R "$item" "$dest/$name"
      echo "copied $dest/$name"
    done
  fi
}

copy_file() {
  local src="$1" dest="$2"
  if [ -f "$src" ]; then
    cp "$src" "$dest"
    echo "copied $dest"
  fi
}

# Skills (copy directories with SKILL.md)
copy_dir "$repo/opencode/skills" "$config/skills"

# Commands (copy .md files)
if [ -d "$repo/opencode/commands" ]; then
  for file in "$repo"/opencode/commands/*.md; do
    [ -f "$file" ] || continue
    copy_file "$file" "$config/commands/$(basename "$file")"
  done
fi

# Agents (copy .md files)
if [ -d "$repo/opencode/agents" ]; then
  for file in "$repo"/opencode/agents/*.md; do
    [ -f "$file" ] || continue
    copy_file "$file" "$config/agents/$(basename "$file")"
  done
fi

echo ""
echo "Done. OpenCode will pick up the changes automatically (or run /reload)."
echo ""
echo "Optional: add these to your global ~/.config/opencode/opencode.json:"
echo "  - permissions for git, npm, go, gh, supabase commands"
echo "  - \"formatter\": true"
echo "  - \"experimental\": { \"todo\": true, \"background_compaction\": true }"
echo ""
echo "Project template: opencode/templates/project-opencode.json"
