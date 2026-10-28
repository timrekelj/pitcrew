#!/usr/bin/env bash
# Links the pitcrew skills and slash commands into OpenCode's global config.
# Re-run after adding or renaming a skill; a `git pull` in this repo is enough otherwise.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

mkdir -p "$config/skills" "$config/commands"

link() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "skip $dest (exists and is not a symlink)" >&2
    return
  fi
  ln -sfn "$src" "$dest"
  echo "linked $dest"
}

for dir in "$repo"/skills/*/; do
  name="$(basename "$dir")"
  link "${dir%/}" "$config/skills/$name"
done

for file in "$repo"/opencode/commands/*.md; do
  link "$file" "$config/commands/$(basename "$file")"
done

echo "Done. Restart OpenCode (opencode service restart)."
