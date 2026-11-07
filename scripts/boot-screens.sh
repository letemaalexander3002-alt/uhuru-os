#!/bin/bash
# Uhuru OS — washa ISO kwenye QEMU na piga picha za skrini. Matumizi: boot-screens.sh <iso> <out-dir>
ISO=${1:?iso}; OUT=${2:?out-dir}
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
MON=/tmp/qemu-mon.sock; rm -f "$MON"
ACCEL=tcg; [ -w /dev/kvm ] && ACCEL=kvm
echo "QEMU accel: $ACCEL"
qemu-system-x86_64 -accel "$ACCEL" -m 3072 -smp 2 -cpu max -cdrom "$ISO" -boot d \
    -vga std -display none -monitor unix:"$MON",server,nowait \
    -serial file:"$OUT/serial.log" -netdev user,id=n0 -device e1000,netdev=n0 &
QPID=$!
mon() { printf '%s\n' "$1" | socat - UNIX-CONNECT:"$MON" >/dev/null 2>&1; }

# KVM ni ya haraka; TCG ni polepole sana, kwa hiyo nyakati zinaongezwa
if [ "$ACCEL" = kvm ]; then TIMES="40 80 120 180 260 360"; else TIMES="120 300 600 900 1200"; fi

START=$SECONDS
while [ $((SECONDS-START)) -lt 10 ]; do sleep 1; done
mon "sendkey ret"                      # chagua entry ya kwanza kwenye boot menu
for t in $TIMES; do
    while [ $((SECONDS-START)) -lt "$t" ]; do sleep 2; done
    kill -0 "$QPID" 2>/dev/null || { echo "QEMU imezimika kabla ya sekunde $t"; break; }
    mon "screendump $OUT/screen-$t.ppm"; sleep 2
    if [ -s "$OUT/screen-$t.ppm" ]; then
        convert "$OUT/screen-$t.ppm" -resize 1024x -quality 80 "$OUT/screen-$t.jpg" && rm -f "$OUT/screen-$t.ppm"
        echo "picha: screen-$t.jpg"
    fi
done
mon "quit"; sleep 2; kill "$QPID" 2>/dev/null
tail -n 25 "$OUT/serial.log" > "$OUT/serial-tail.txt" 2>/dev/null
exit 0
