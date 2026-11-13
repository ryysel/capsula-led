#!/bin/sh
# Remove capsula-led from a jailbroken VK Капсула 2019.
#
# Usage: sh uninstall.sh
set -eu

upper=/data/overlay/upper
wrap=$upper/usr/bin/voice-agent.sh

[ "$(grep '^Uid:' /proc/self/status | cut -f2)" = 0 ] || { echo "run as root on the capsule" >&2; exit 1; }

echo "== stopping"
/etc/init.d/S98capsula-led stop 2>/dev/null || killall -15 capsula-led 2>/dev/null || true
sleep 1

echo "== files"
rm -f "$upper/usr/bin/capsula-led" "$upper/etc/init.d/S98capsula-led"

if [ -f "$wrap" ] && grep -q 'S98capsula-led' "$wrap"; then
    : > "$wrap.new"
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            *S98capsula-led*) continue ;;
        esac
        printf '%s\n' "$line" >> "$wrap.new"
    done < "$wrap"
    # If nothing but the stock exec line is left, drop the overlay copy too.
    if grep -q 'capsula-boot' "$wrap.new"; then
        mv -f "$wrap.new" "$wrap"
        chmod 0755 "$wrap"
    else
        rm -f "$wrap.new" "$wrap"
    fi
    echo "  autostart hook removed"
fi
sync

echo "Removed. The ring stays dark until voice-agent draws on it again;"
echo "a reboot also drops the overlay copy of the wrapper for good."
echo UNINSTALL_PASS
