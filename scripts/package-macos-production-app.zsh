#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
exec zsh "$repo_root/scripts/package-macos-app-shared.zsh" --production "$@"
