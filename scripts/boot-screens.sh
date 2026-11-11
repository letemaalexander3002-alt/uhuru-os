#!/bin/bash
# Uhuru OS — washa ISO kwenye QEMU, pitia login/wizard/login kiotomatiki (KVM), na piga picha za kila hatua.
# Usawazishaji unatumia TELEMETRY ya mfumo (UHURU-STATE kwenye serial), siyo mwangaza wa picha.
# Akaunti ya majaribio: tester / uhurutest1.   Matumizi: boot-screens.sh <iso> <out-dir>
ISO=${1:-}; OUT=${2:-.}
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
MON=/tmp/qemu-mon.sock

mon()   { printf '%s\n' "$1" | socat - UNIX-CONNECT:"$MON" >/dev/null 2>&1; }
alive() { kill -0 "$QPID" 2>/dev/null; }
note()  { echo "$*" | tee -a "$OUT/e2e.log"; }
shot()  { mon "screendump $OUT/$1.ppm"; sleep 2
          if [ -s "$OUT/$1.ppm" ]; then convert "$OUT/$1.ppm" -resize 1024x -quality 80 "$OUT/$1.jpg" && echo "picha: $1.jpg"; fi
          rm -f "$OUT/$1.ppm"; }
key()   { mon "sendkey $1"; sleep 0.4; }
typestr() { local s=$1 i c; for ((i=0;i<${#s};i++)); do c=${s:$i:1}; case "$c" in -) key minus ;; ' ') key spc ;; *) key "$c" ;; esac; done; }
slog()       { tr -d '\r' < "$OUT/serial.log" 2>/dev/null; }
last_state() { slog | grep '^UHURU-STATE' | tail -1; }
wait_state() {   # wait_state <regex> <sekunde-za-juu>: 0 ikiona hali hiyo kwenye UHURU-STATE ya mwisho, 1 ikikosa
    local re=$1 max=$2 t0=$SECONDS
    while [ $((SECONDS-t0)) -lt "$max" ]; do
        alive || return 1
        last_state | grep -Eq "$re" && return 0
        sleep 2
    done
    return 1
}
[ "${UHURU_SOURCE_ONLY:-}" = 1 ] && return 0 2>/dev/null

: "${ISO:?iso}"
rm -f "$MON" "$OUT/e2e.log"
ACCEL=tcg; [ -w /dev/kvm ] && ACCEL=kvm
note "QEMU accel: $ACCEL"
# -smbios serial=UHURU_CI huwasha telemetry ndani ya mfumo (haiathiri kompyuta halisi)
qemu-system-x86_64 -accel "$ACCEL" -m 3072 -smp 2 -cpu max -cdrom "$ISO" -boot d \
    -vga std -display none -monitor unix:"$MON",server,nowait -smbios type=1,serial=UHURU_CI \
    -serial file:"$OUT/serial.log" -netdev user,id=n0 -device e1000,netdev=n0 &
QPID=$!

START=$SECONDS
at() { while [ $((SECONDS-START)) -lt "$1" ]; do sleep 1; done; }
at 10; mon "sendkey ret"                         # chagua entry ya kwanza kwenye boot menu

if [ "$ACCEL" = kvm ]; then
    at 40; shot 01-boot
    if ! wait_state '^UHURU-STATE' 240; then
        note "E2E telemetry=missing"; shot 02-telemetry-HAIKUONEKANA
    else
        note "E2E telemetry=ok"
        # 1. Boot ya kwanza: je, mfumo unaingia desktop yenyewe?
        if wait_state 'sessions=[^ ]*mtumiaji' 150; then
            note "E2E autologin=yes"; shot 02-desktop
        else
            note "E2E autologin=no"; shot 02a-login-screen-bila-autologin
            typestr uhuru; key ret                # jina limejazwa; jaribu password ya default
            if wait_state 'sessions=[^ ]*mtumiaji' 90; then note "E2E live-login-manual=ok"
            else note "E2E live-login-manual=failed"; shot 02b-login-ya-live-imeshindikana; fi
        fi
        # 2. Wizard ya usajili
        if wait_state 'sessions=[^ ]*mtumiaji.* zenity=[1-9]' 150; then
            note "E2E wizard=seen"
            sleep 2; shot 03-wizard-karibu;            key ret; sleep 4
            shot 04-wizard-saa;                        key ret; sleep 4
            shot 05-wizard-jina-kompyuta;              key ret; sleep 4
            shot 06-wizard-wifi;                       key esc; sleep 4
            shot 07-wizard-jina-kamili;                typestr tester; key ret; sleep 4
            shot 08-wizard-username;                   typestr tester; key ret; sleep 4
            shot 09-wizard-password;                   typestr uhurutest1; key ret; sleep 4
            shot 10-wizard-rudia;                      typestr uhurutest1; key ret; sleep 4
            shot 11-wizard-onyesha;                    key esc; sleep 4
            shot 12-wizard-autologin;                  key esc
            if wait_state 'done=yes' 60; then note "E2E registered=yes"; else note "E2E registered=no"; shot 13-usajili-haukukamilika; fi
            # 3. Login screen mpya, kisha ingia na akaunti ya majaribio
            if wait_state 'sessions=lightdm, .*greeter=[1-9]' 120; then
                note "E2E greeter-after=yes"; sleep 3; shot 14-login-screen
                typestr uhurutest1; key ret
                if wait_state 'sessions=[^ ]*tester' 90; then note "E2E tester-login=yes"; else note "E2E tester-login=no"; fi
                sleep 30; shot 15-baada-ya-login
                if grep -q 'E2E tester-login=yes' "$OUT/e2e.log"; then
                    key ctrl-alt-t; sleep 8; shot 16-terminal
                    typestr "uhuru-selftest uhurutest1"; key ret
                    sleep 15; shot 17-selftest
                fi
            else
                note "E2E greeter-after=no"; shot 14-login-screen-HAIKUONEKANA
            fi
        else
            note "E2E wizard=missing"; shot 03-wizard-HAIKUONEKANA
        fi
    fi
else
    # TCG ni polepole sana: picha tu, bila kuendesha wizard
    note "E2E accel=tcg (automation imeruka)"
    for t in 120 300 600 900 1200; do at "$t"; alive || break; shot "tcg-$t"; done
fi
mon "quit"; sleep 2; kill "$QPID" 2>/dev/null
tail -n 40 "$OUT/serial.log" > "$OUT/serial-tail.txt" 2>/dev/null
exit 0
