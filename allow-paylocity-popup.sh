#!/bin/bash
#
# Allows pop-ups and redirects for Paylocity in Google Chrome and Microsoft Edge on macOS,
# so Time & Labor / Timesheets opens without logging users out.
#
# How it works:
#   macOS only accepts browser policies from a configuration profile. This script checks
#   whether the policy is already in place. If it isn't, it creates the profile and opens
#   it, and the user approves it in System Settings (macOS requires that step to be done
#   by hand, with an admin password).
#
# Usage:
#   bash allow-paylocity-popups.sh
#

RED=$'\033[31m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

URL='[*.]paylocity.com'
PROFILE_NAME="Allow-Paylocity-Popups.mobileconfig"
PROFILE_PATH="$HOME/Downloads/$PROFILE_NAME"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "${RED}This script is for macOS. On Windows, use Allow-PaylocityPopups.ps1.${RESET}"
    exit 1
fi

# Returns success if the given browser's managed policy already allows Paylocity pop-ups,
# either machine-wide or for this user.
policy_present() {
    local domain="$1"
    local f
    for f in "/Library/Managed Preferences/$domain" "/Library/Managed Preferences/$USER/$domain"; do
        if [[ -f "$f.plist" ]] && defaults read "$f" PopupsAllowedForUrls 2>/dev/null | grep -qF "$URL"; then
            return 0
        fi
    done
    return 1
}

missing=0
for domain in com.google.Chrome com.microsoft.Edge; do
    if policy_present "$domain"; then
        echo "Already allowed for $domain : $URL"
    else
        echo "Not yet allowed for $domain : $URL"
        missing=1
    fi
done

if [[ $missing -eq 0 ]]; then
    echo ""
    echo "${GREEN}No changes needed. Paylocity pop-ups are already allowed.${RESET}"
    exit 0
fi

cat > "$PROFILE_PATH" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadDisplayName</key>
    <string>Allow Paylocity Pop-ups</string>
    <key>PayloadDescription</key>
    <string>Allows pop-ups and redirects for paylocity.com in Google Chrome and Microsoft Edge so Timesheets opens correctly.</string>
    <key>PayloadIdentifier</key>
    <string>com.paylocity-popups.profile</string>
    <key>PayloadUUID</key>
    <string>FB36BD95-3B68-4015-999C-DBCC35A01115</string>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadScope</key>
    <string>System</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>PayloadDisplayName</key>
            <string>Google Chrome</string>
            <key>PayloadIdentifier</key>
            <string>com.paylocity-popups.chrome</string>
            <key>PayloadUUID</key>
            <string>EC92082F-73A1-40CB-B3AF-ABB23E3D7A7D</string>
            <key>PayloadType</key>
            <string>com.google.Chrome</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            <key>PopupsAllowedForUrls</key>
            <array>
                <string>[*.]paylocity.com</string>
            </array>
        </dict>
        <dict>
            <key>PayloadDisplayName</key>
            <string>Microsoft Edge</string>
            <key>PayloadIdentifier</key>
            <string>com.paylocity-popups.edge</string>
            <key>PayloadUUID</key>
            <string>FBDC287C-CF8B-4E2E-BAC2-26D70D5AF6DC</string>
            <key>PayloadType</key>
            <string>com.microsoft.Edge</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            <key>PopupsAllowedForUrls</key>
            <array>
                <string>[*.]paylocity.com</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

if ! plutil -lint -s "$PROFILE_PATH"; then
    echo "${RED}Could not create a valid profile at $PROFILE_PATH.${RESET}"
    exit 1
fi

# Opening the profile registers it with System Settings for the user to approve.
open "$PROFILE_PATH"

echo ""
echo "${RED}One more step is needed to finish:${RESET}"
echo "${RED}  1. Open System Settings and search for \"Profiles\" (or go to General > Device Management).${RESET}"
echo "${RED}  2. Double-click \"Allow Paylocity Pop-ups\", click Install, and enter your Mac password.${RESET}"
echo "${RED}  3. Restart the browser, or open chrome://policy (edge://policy for Edge) and click 'Reload policies'.${RESET}"
