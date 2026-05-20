#!/bin/zsh

set -euo pipefail

dmg_path="${1:-}"
sign_identity="${CODE_SIGN_IDENTITY:-}"
signing_keychain="${OPEN_RECORDER_SIGNING_KEYCHAIN:-}"
apple_id="${APPLE_ID:-}"
apple_password="${APPLE_APP_SPECIFIC_PASSWORD:-}"
apple_team_id="${APPLE_TEAM_ID:-}"
notary_max_attempts="${NOTARYTOOL_MAX_ATTEMPTS:-3}"
notary_retry_delay_seconds="${NOTARYTOOL_RETRY_DELAY_SECONDS:-15}"

die() {
	print -u2 -- "Error: $*"
	exit 1
}

submit_for_notarization() {
	local file_path="$1"
	local attempt=1
	local delay_seconds="$notary_retry_delay_seconds"
	local exit_status=0

	while (( attempt <= notary_max_attempts )); do
		print -- "Submitting $(basename "$file_path") for notarization (attempt ${attempt}/${notary_max_attempts})"
		if xcrun notarytool submit "$file_path" \
			--apple-id "$apple_id" \
			--password "$apple_password" \
			--team-id "$apple_team_id" \
			--wait; then
			return 0
		fi

		exit_status=$?
		if (( attempt == notary_max_attempts )); then
			print -u2 -- "Notarization failed after ${notary_max_attempts} attempts."
			return "$exit_status"
		fi

		print -u2 -- "Notarization attempt ${attempt}/${notary_max_attempts} failed; retrying in ${delay_seconds}s."
		sleep "$delay_seconds"
		attempt=$(( attempt + 1 ))
		delay_seconds=$(( delay_seconds * 2 ))
	done
}

[[ -n "$dmg_path" && -f "$dmg_path" ]] || die "Usage: zsh scripts/notarize-macos-production-dmg.zsh PATH_TO_DMG"
[[ -n "$sign_identity" ]] || die "Missing CODE_SIGN_IDENTITY."
[[ -n "$apple_id" ]] || die "Missing APPLE_ID secret."
[[ -n "$apple_password" ]] || die "Missing APPLE_APP_SPECIFIC_PASSWORD secret."
[[ -n "$apple_team_id" ]] || die "Missing APPLE_TEAM_ID secret."
[[ "$notary_max_attempts" == <-> && "$notary_max_attempts" -ge 1 ]] || die "NOTARYTOOL_MAX_ATTEMPTS must be a positive integer."
[[ "$notary_retry_delay_seconds" == <-> ]] || die "NOTARYTOOL_RETRY_DELAY_SECONDS must be a non-negative integer."

codesign_args=(--force --timestamp --sign "$sign_identity")
if [[ -n "$signing_keychain" ]]; then
	codesign_args+=(--keychain "$signing_keychain")
fi
codesign "${codesign_args[@]}" "$dmg_path"

submit_for_notarization "$dmg_path"

xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"
spctl -a -vv -t open --context context:primary-signature "$dmg_path"

print -- "Signed, notarized, and stapled $dmg_path"
