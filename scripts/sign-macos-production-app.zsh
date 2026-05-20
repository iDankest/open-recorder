#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
OPEN_RECORDER_SIGNING_PURPOSE=production exec zsh "$repo_root/scripts/sign-macos-app-shared.zsh" "$@"
