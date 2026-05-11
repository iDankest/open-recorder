#!/bin/zsh

set -euo pipefail

dmg_path="${1:-}"
sign_identity="${CODE_SIGN_IDENTITY:-}"
apple_id="${APPLE_ID:-}"
apple_password="${APPLE_APP_SPECIFIC_PASSWORD:-}"
apple_team_id="${APPLE_TEAM_ID:-}"

die() {
	print -u2 -- "Error: $*"
	exit 1
}

[[ -n "$dmg_path" && -f "$dmg_path" ]] || die "Usage: zsh scripts/notarize-macos-dmg.zsh PATH_TO_DMG"
[[ -n "$sign_identity" ]] || die "Missing CODE_SIGN_IDENTITY."
[[ -n "$apple_id" ]] || die "Missing APPLE_ID secret."
[[ -n "$apple_password" ]] || die "Missing APPLE_APP_SPECIFIC_PASSWORD secret."
[[ -n "$apple_team_id" ]] || die "Missing APPLE_TEAM_ID secret."

codesign --force --timestamp --sign "$sign_identity" "$dmg_path"

xcrun notarytool submit "$dmg_path" \
	--apple-id "$apple_id" \
	--password "$apple_password" \
	--team-id "$apple_team_id" \
	--wait

xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"
spctl -a -vv -t open --context context:primary-signature "$dmg_path"

print -- "Signed, notarized, and stapled $dmg_path"
