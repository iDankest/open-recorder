#!/bin/zsh

set -euo pipefail

bundle_dir="${1:-}"
apple_id="${APPLE_ID:-}"
apple_password="${APPLE_APP_SPECIFIC_PASSWORD:-}"
apple_team_id="${APPLE_TEAM_ID:-}"

die() {
	print -u2 -- "Error: $*"
	exit 1
}

[[ -n "$bundle_dir" && -d "$bundle_dir" ]] || die "Usage: zsh scripts/notarize-macos-app.zsh PATH_TO_APP"
[[ -n "$apple_id" ]] || die "Missing APPLE_ID secret."
[[ -n "$apple_password" ]] || die "Missing APPLE_APP_SPECIFIC_PASSWORD secret."
[[ -n "$apple_team_id" ]] || die "Missing APPLE_TEAM_ID secret."

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

notary_zip="$tmp_dir/$(basename "$bundle_dir").zip"
ditto -c -k --keepParent "$bundle_dir" "$notary_zip"

xcrun notarytool submit "$notary_zip" \
	--apple-id "$apple_id" \
	--password "$apple_password" \
	--team-id "$apple_team_id" \
	--wait

xcrun stapler staple "$bundle_dir"
xcrun stapler validate "$bundle_dir"
spctl -a -vv -t exec "$bundle_dir"

print -- "Notarized and stapled $bundle_dir"
