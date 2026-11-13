#!/bin/sh
# Install capsula-led on a jailbroken VK Капсула 2019.
#
# The root filesystem is squashfs + overlayfs (upperdir=/data/overlay/upper),
# so the binary and the init script are written straight into the upper layer:
# writing through the merged path (/usr/bin/...) can be lost on reboot.
#
# rcS expands /etc/init.d/S??* before the overlay is mounted, so a new S*
# script never runs on its own. Autostart is therefore added to the overlay
# copy of the stock voice-agent.sh wrapper, which is executed after the overlay
# is up.
#
# Usage: sh install.sh
set -eu

here=$(cd "$(dirname "$0")" && pwd)
bin=${1:-$here/capsula-led}
init_src=$here/etc/S98capsula-led
[ -f "$init_src" ] || init_src=$here/S98capsula-led

upper=/data/overlay/upper
wrap=$upper/usr/bin/voice-agent.sh
hook='( sleep 10; /etc/init.d/S98capsula-led start ) >/dev/null 2>&1 &'

[ -f "$bin" ] || { echo "binary not found: $bin (run ./build.sh first)" >&2; exit 1; }
[ -f "$init_src" ] || { echo "init script not found: $init_src" >&2; exit 1; }
[ "$(grep '^Uid:' /proc/self/status | cut -f2)" = 0 ] || { echo "run as root on the capsule" >&2; exit 1; }
[ -e /dev/led_multi_ctrl ] || { echo "/dev/led_multi_ctrl is missing: not a 2019 Capsule?" >&2; exit 1; }
[ -d "$upper" ] || { echo "$upper is missing: overlayfs is not mounted" >&2; exit 1; }

echo "== files"
mkdir -p "$upper/usr/bin" "$upper/etc/init.d"
cp -f "$bin" "$upper/usr/bin/capsula-led"
cp -f "$init_src" "$upper/etc/init.d/S98capsula-led"
chmod 0755 "$upper/usr/bin/capsula-led" "$upper/etc/init.d/S98capsula-led"
echo "  $upper/usr/bin/capsula-led"
echo "  $upper/etc/init.d/S98capsula-led"

echo "== autostart hook"
if [ ! -f "$wrap" ]; then
    mkdir -p "$(dirname "$wrap")"
    cp /usr/bin/voice-agent.sh "$wrap"
fi
if grep -q 'S98capsula-led' "$wrap"; then
    echo "  already present in $wrap"
else
    : > "$wrap.new"
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            "exec voice-agent"*) printf '%s\n\n' "$hook" >> "$wrap.new" ;;
        esac
        printf '%s\n' "$line" >> "$wrap.new"
    done < "$wrap"
    mv -f "$wrap.new" "$wrap"
    chmod 0755 "$wrap"
    echo "  added to $wrap"
fi
sync

echo "== starting"
/etc/init.d/S98capsula-led start
sleep 2
if pgrep -f '/usr/bin/capsula-led daemon' > /dev/null 2>&1; then
    echo "capsula-led: running"
else
    echo "capsula-led: NOT running (see: capsula-led clock 20)" >&2
    exit 1
fi

echo
echo "Clock should be on the ring now. It steps aside while Marusya speaks and"
echo "comes back about a second after the answer."
echo "Autostart is checked after one reboot: reboot, then"
echo "  logread | grep capsula-led"
echo INSTALL_PASS
