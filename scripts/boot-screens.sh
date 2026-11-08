#!/bin/bash
# Uhuru OS — washa ISO kwenye QEMU, piga picha za skrini, na (kwenye KVM) pitia wizard na login kiotomatiki.
# Akaunti ya majaribio: tester / uhurutest1.   Matumizi: boot-screens.sh <iso> <out-dir>
ISO=${1:?iso}; OUT=${2:?out-dir}
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
MON=/tmp/qemu-mon.sock; rm -f "$MON"
ACCEL=tcg; [ -w /dev/kvm ] && ACCEL=kvm
echo "QEMU accel: $ACCEL"
qemu-system-x86_64 -accel "$ACCEL" -m 3072 -smp 2 -cpu max -cdrom "$ISO" -boot d \
    -vga std -display none -monitor unix:"$MON",server,nowait \
    -serial file:"$OUT/serial.log" -netdev user,id=n0 -device e1000,netdev=n0 &
QPID=$!
mon()   { printf '%s\n' "$1" | socat - UNIX-CONNECT:"$MON" >/dev/null 2>&1; }
alive() { kill -0 "$QPID" 2>/dev/null; }
shot()  { mon "screendump $OUT/$1.ppm"; sleep 2
          if [ -s "$OUT/$1.ppm" ]; then convert "$OUT/$1.ppm" -resize 1024x -quality 80 "$OUT/$1.jpg" && echo "picha: $1.jpg"; fi
          rm -f "$OUT/$1.ppm"; }
key()   { mon "sendkey $1"; sleep 0.4; }
typestr() { local s=$1 i c; for ((i=0;i<${#s};i++)); do c=${s:$i:1}; case "$c" in -) key minus ;; ' ') key spc ;; *) key "$c" ;; esac; done; }
# Mwangaza wa eneo dogo la katikati (dialog ni nyepesi, desktop ni nyeusi): 0..1
center_light() {
    mon "screendump $OUT/probe.ppm"; sleep 1.5
    [ -s "$OUT/probe.ppm" ] || { echo 0; return; }
    convert "$OUT/probe.ppm" -gravity center -crop 16%x6%+0+0 +repage -colorspace Gray -format '%[fx:mean]' info: 2>/dev/null || echo 0
}
wait_light() {   # wait_light <sekunde-za-juu>: 0 ikiona dialog, 1 ikikosa
    local max=$1 t0=$SECONDS v
    while [ $((SECONDS-t0)) -lt "$max" ]; do
        alive || return 1
        v=$(center_light); awk -v v="$v" 'BEGIN{exit !(v>0.6)}' && return 0
        sleep 2
    done
    return 1
}

START=$SECONDS
at() { while [ $((SECONDS-START)) -lt "$1" ]; do sleep 1; done; }
at 10; mon "sendkey ret"                         # chagua entry ya kwanza kwenye boot menu

if [ "$ACCEL" = kvm ]; then
    at 45; shot 01-boot
    if wait_light 150; then
        shot 02-wizard-karibu;            key ret; sleep 3
        wait_light 20; shot 03-wizard-saa;           key ret; sleep 3
        wait_light 20; shot 04-wizard-jina-kompyuta; key ret; sleep 3
        wait_light 20; shot 05-wizard-wifi;          key esc; sleep 3
        wait_light 20; shot 06-wizard-jina-kamili;   typestr tester; key ret; sleep 3
        wait_light 20; shot 07-wizard-username;      typestr tester; key ret; sleep 3
        wait_light 20; shot 08-wizard-password;      typestr uhurutest1; key ret; sleep 3
        wait_light 20; shot 09-wizard-rudia;         typestr uhurutest1; key ret; sleep 3
        wait_light 20; shot 10-wizard-onyesha;       key esc; sleep 3
        wait_light 20; shot 11-wizard-autologin;     key esc
        sleep 15                                      # lightdm inaanza upya
        if wait_light 90; then
            shot 12-login-screen
            typestr uhurutest1; key ret
            sleep 45; shot 13-baada-ya-login
            key ctrl-alt-t; sleep 8; shot 14-terminal
            typestr "uhuru-selftest uhurutest1"; key ret
            sleep 15; shot 15-selftest
        else
            shot 12-login-screen-HAIKUONEKANA
        fi
    else
        shot 02-wizard-HAIKUONEKANA
    fi
else
    # TCG ni polepole sana: picha tu, bila kuendesha wizard
    for t in 120 300 600 900 1200; do
        at "$t"; alive || break
        shot "tcg-$t"
    done
fi
mon "quit"; sleep 2; kill "$QPID" 2>/dev/null
tail -n 25 "$OUT/serial.log" > "$OUT/serial-tail.txt" 2>/dev/null
exit 0
