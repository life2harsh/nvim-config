#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
timestamp="$(date +%Y%m%d-%H%M%S)"

if ! command -v git >/dev/null 2>&1; then
  printf 'Error: git is required.\n' >&2
  exit 1
fi

if ! command -v nvim >/dev/null 2>&1; then
  printf 'Error: Neovim is required; this AstroNvim config cannot run in Vim or vi.\n' >&2
  exit 1
fi

mkdir -p -- "$(dirname -- "$config_dir")"

if [[ -L "$config_dir" && "$(readlink -f -- "$config_dir")" == "$repo_dir" ]]; then
  printf 'Already installed: %s points to this repository.\n' "$config_dir"
elif [[ "$config_dir" == "$repo_dir" ]]; then
  printf 'Already installed directly at %s.\n' "$config_dir"
else
  if [[ -e "$config_dir" || -L "$config_dir" ]]; then
    backup_dir="${config_dir}.backup-${timestamp}"
    mv -- "$config_dir" "$backup_dir"
    printf 'Backed up the existing config to %s\n' "$backup_dir"
  fi

  ln -s -- "$repo_dir" "$config_dir"
  printf 'Installed Neovim config: %s -> %s\n' "$config_dir" "$repo_dir"
fi

printf '\nStart Neovim with: nvim\n'
printf 'Plugins will be downloaded automatically on first launch.\n'
