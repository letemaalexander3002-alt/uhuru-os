#!/bin/bash
# Uhuru OS — washa ISO kwenye QEMU, pitia login/wizard/login kiotomatiki (KVM), na piga picha za kila hatua.
# Usawazishaji unatumia TELEMETRY ya mfumo (UHURU-STATE kwenye serial), siyo mwangaza wa picha.
# Akaunti ya majaribio: tester / uhurutest1.   Matumizi: boot-screens.sh <iso> <out-dir>
# v13.9: (1) telemetry ikisimama (n haiongezeki) jaribio linasimama na kusema "stale", halichapi funguo kwa upofu,
#        (2) funguo za login zinatumwa TU baada ya kuthibitisha kuwa login screen (greeter) ipo kweli.
ISO=${1:-}; OUT=${2:-.}
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
MON=/tmp/qemu-mon.sock
STALE_AFTER=${UHURU_STALE_AFTER:-75}      # sekunde ambazo n ya telemetry isipoongezeka = telemetry imesimama

mon()   { printf '%s\n' "$1" | socat - UNIX-CONNECT:"$MON" >/dev/null 2>&1; }
alive() { kill -0 "$QPID" 2>/dev/null; }
note()  { echo "$*" | tee -a "$OUT/e2e.log"; }
shot()  { mon "screendump $OUT/$1.ppm"; sleep 2
          if [ -s "$OUT/$1.ppm" ]; then convert "$OUT/$1.ppm" -resize 1024x -quality 80 "$OUT/$1.jpg" && echo "picha: $1.jpg"; fi
          rm -f "$OUT/$1.ppm"; }
key()   { mon "sendkey $1"; sleep 0.4; }
typestr() { local s=$1 i c; for ((i=0;i<${#s};i++)); do c=${s:$i:1}; case "$c" in -) key minus ;; ' ') key spc ;; *) key "$c" ;; esac; done; }
slog()       { tr -d '\r' 2>/dev/null < "$OUT/serial.log"; }
last_state() { slog | grep '^UHURU-STATE' | tail -1; }

TN_LAST=""; TN_T=$SECONDS
# wait_first: subiri mstari wa kwanza wa UHURU-STATE (sekunde 240). 0 ukionekana, 1 ukikosa.
wait_first() {
    local t0=$SECONDS
    while [ $((SECONDS-t0)) -lt 240 ]; do
        alive || return 1
        [ -n "$(last_state)" ] && { TN_T=$SECONDS; return 0; }
        sleep 2
    done
    return 1
}
# wait_state <regex> <sekunde-za-juu>:
#   0 = hali inaonekana kwenye UHURU-STATE ya mwisho (na telemetry iko hai)
#   1 = muda umeisha bila hali hiyo (telemetry hai)
#   2 = telemetry imesimama (n haiongezeki kwa STALE_AFTER) - matokeo hayawezi kuaminika
wait_state() {
    local re=$1 max=$2 t0=$SECONDS st n
    while [ $((SECONDS-t0)) -lt "$max" ]; do
        alive || return 1
        st=$(last_state)
        n=$(printf '%s' "$st" | sed -n 's/^UHURU-STATE n=\([0-9]*\) .*/\1/p')
        if [ "$n" != "$TN_LAST" ]; then TN_LAST=$n; TN_T=$SECONDS; fi
        [ $((SECONDS-TN_T)) -ge "$STALE_AFTER" ] && return 2
        printf '%s' "$st" | grep -Eq "$re" && return 0
        sleep 2
    done
    return 1
}
# Kuingia kwenye login screen. Kwanza thibitisha kuwa greeter ipo kweli (usiandike funguo kwenye dirisha lingine).
#  A: andika password moja kwa moja.  B: chagua yote kwenye kisanduku, andika jina, Enter, kisha password.
# Inarudisha: 0 imefanikiwa, 1 imeshindikana, 2 telemetry imesimama.
greeter_login() {   # greeter_login <jina> <password> <regex-ya-mafanikio> <lebo>
    # v13.13 njia B kwanza: login screen ya Uhuru OS inaonyesha kisanduku cha jina (hakuna orodha ya watumiaji).
    local u=$1 p=$2 ok=$3 tag=$4 rc
    wait_state 'greeter=[1-9]' 60; rc=$?
    [ $rc -eq 2 ] && return 2
    if [ $rc -ne 0 ]; then note "E2E greeter-visible=no ($tag)"; shot "login-$tag-greeter-HAIKUONEKANA"; return 1; fi
    sleep 3
    key ctrl-a; typestr "$u"; key ret; sleep 4; typestr "$p"; key ret
    wait_state "$ok" 45; rc=$?
    [ $rc -eq 2 ] && return 2
    if [ $rc -eq 0 ]; then note "E2E greeter-method=jina-kisha-password ($tag)"; return 0; fi
    shot "login-$tag-njia-B-imeshindikana"
    # Akiba: greeter inasubiri password ya mtumiaji aliyechaguliwa tayari (au ya jina lililokwisha andikwa)
    sleep 4; key ctrl-a; typestr "$p"; key ret
    wait_state "$ok" 30; rc=$?
    [ $rc -eq 2 ] && return 2
    if [ $rc -eq 0 ]; then note "E2E greeter-method=password-pekee ($tag)"; return 0; fi
    shot "login-$tag-njia-A-imeshindikana"
    return 1
}
LIVE_UP='(sessions|xfceuser)=[^ ]*mtumiaji'
TESTER_UP='(sessions|xfceuser)=[^ ]*tester'

START=$SECONDS
at() { while [ $((SECONDS-START)) -lt "$1" ]; do sleep 1; done; }

# v13.11: jaribio la wizard linaongozwa na hatua (step=) kutoka telemetry, si na muda.
a_ret()  { key ret; }
a_esc()  { key esc; }
a_text() { key ctrl-a; typestr "$1"; key ret; }
# v13.12: dirisha la tz (radiolist) halina cursor, kwa hiyo Enter haifanyi kitu. Njia zinabadilika kila jaribio (WIZ_TRY).
a_tz()   { case "${WIZ_TRY:-1}" in 1) key esc ;; 2) key down; key ret ;; *) key alt-o ;; esac; }
a_auto() { case "${WIZ_TRY:-1}" in 1) key esc ;; *) key ret ;; esac; }
# wiz <hatua-sasa> <regex-ya-hatua-inayofuata> <kitendo> [hoja]: subiri hatua itokee, piga picha, tuma funguo,
# thibitisha wizard imesogea; ikikwama rudia hadi mara 3. Inarudisha 0 sawa, 1 imekwama, 2 telemetry imesimama.
wiz() {
    local cur=$1 nxt=$2 try rc; shift 2
    wait_state " step=$cur " 60; rc=$?
    [ $rc -eq 2 ] && return 2
    if [ $rc -ne 0 ]; then note "E2E wizard-step=$cur haikuonekana"; shot "wizard-$cur-HAIKUONEKANA"; return 1; fi
    sleep 1; shot "wizard-$cur"
    for try in 1 2 3; do
        WIZ_TRY=$try; "$@"
        wait_state " step=$nxt " 25; rc=$?
        [ $rc -eq 2 ] && return 2
        if [ $rc -eq 0 ]; then note "E2E wizard-step=$cur ok (jaribio $try)"; return 0; fi
        note "E2E wizard-step=$cur imekwama (jaribio $try)"
    done
    shot "wizard-$cur-IMEKWAMA"; return 1
}

# e2e: inarudisha 0 ikimaliza (matokeo yamo kwenye e2e.log), 2 telemetry ikisimama.
e2e() {
    local rc
    at 100; shot 01b-sekunde-100
    # 1. Boot ya kwanza: je, mfumo unaingia desktop yenyewe?
    wait_state "$LIVE_UP" 150; rc=$?
    [ $rc -eq 2 ] && return 2
    if [ $rc -eq 0 ]; then
        note "E2E autologin=yes"; shot 02-desktop
    else
        note "E2E autologin=no"; shot 02a-login-screen-bila-autologin
        greeter_login mtumiaji uhuru "$LIVE_UP" live; rc=$?
        [ $rc -eq 2 ] && return 2
        if [ $rc -eq 0 ]; then note "E2E live-login-manual=ok"; else note "E2E live-login-manual=failed"; fi
    fi
    # 2. Wizard ya usajili
    wait_state "$LIVE_UP.* zenity=[1-9]" 150; rc=$?
    [ $rc -eq 2 ] && return 2
    if [ $rc -ne 0 ]; then note "E2E wizard=missing"; shot 03-wizard-HAIKUONEKANA; return 0; fi
    note "E2E wizard=seen"
    local spec cur nxt act arg
    for spec in \
        "welcome:tz:a_ret:" \
        "tz:computer:a_tz:" \
        "computer:fullname:a_ret:" \
        "fullname:username:a_text:tester" \
        "username:pass1:a_text:tester" \
        "pass1:pass2:a_text:uhurutest1" \
        "pass2:confirm:a_text:uhurutest1" \
        "confirm:autologin:a_esc:" \
        "autologin:(creating|rc-[0-9]+|final|none):a_auto:"; do
        IFS=: read -r cur nxt act arg <<< "$spec"
        wiz "$cur" "$nxt" "$act" "$arg"; rc=$?
        [ $rc -eq 2 ] && return 2
        [ $rc -ne 0 ] && break
    done
    wait_state 'done=yes' 60; rc=$?
    [ $rc -eq 2 ] && return 2
    if [ $rc -eq 0 ]; then note "E2E registered=yes"; else note "E2E registered=no"; shot 13-usajili-haukukamilika; fi
    # 3. Login screen mpya, kisha ingia na akaunti ya majaribio
    wait_state 'sessions=([^ ]*,)?lightdm, .*greeter=[1-9]' 120; rc=$?
    [ $rc -eq 2 ] && return 2
    if [ $rc -ne 0 ]; then note "E2E greeter-after=no"; shot 14-login-screen-HAIKUONEKANA; return 0; fi
    note "E2E greeter-after=yes"; sleep 3; shot 14-login-screen
    greeter_login tester uhurutest1 "$TESTER_UP" tester; rc=$?
    [ $rc -eq 2 ] && return 2
    if [ $rc -eq 0 ]; then note "E2E tester-login=yes"; else note "E2E tester-login=no"; fi
    sleep 30; shot 15-baada-ya-login
    if grep -q 'E2E tester-login=yes' "$OUT/e2e.log"; then
        key ctrl-alt-t; sleep 8; shot 16-terminal
        typestr "uhuru-selftest uhurutest1"; key ret
        sleep 15; shot 17-selftest
        key meta_l; sleep 4; shot 18-start-menu; key esc; sleep 2
        typestr "uhuru-store"; key ret; sleep 12; shot 19-lgt-store
        key meta_l; sleep 3; typestr "Uhuru Share"; sleep 3; shot 20-start-menu-share; key ret; sleep 8; shot 21-uhuru-share
    fi
    return 0
}

[ "${UHURU_SOURCE_ONLY:-}" = 1 ] && return 0 2>/dev/null
: "${ISO:?iso}"
rm -f "$MON" "$OUT/e2e.log"
ACCEL=tcg; [ -w /dev/kvm ] && ACCEL=kvm
note "QEMU accel: $ACCEL"
# -smbios serial=UHURU_CI huwasha telemetry ndani ya mfumo (haiathiri kompyuta halisi)
qemu-system-x86_64 -accel "$ACCEL" -m 2048 -smp 2 -cpu max -cdrom "$ISO" -boot d \
    -vga std -display none -monitor unix:"$MON",server,nowait -smbios type=1,serial=UHURU_CI \
    -serial file:"$OUT/serial.log" -netdev user,id=n0 -device e1000,netdev=n0 &
QPID=$!

START=$SECONDS
at 10; mon "sendkey ret"                         # chagua entry ya kwanza kwenye boot menu

if [ "$ACCEL" = kvm ]; then
    at 40; shot 01-boot
    if ! wait_first; then
        note "E2E telemetry=missing"; shot 02-telemetry-HAIKUONEKANA
    else
        note "E2E telemetry=ok"
        e2e; rc=$?
        if [ $rc -eq 2 ]; then
            note "E2E telemetry=stale n=$TN_LAST"; shot 99-telemetry-stale
        fi
    fi
else
    # TCG ni polepole sana: picha tu, bila kuendesha wizard
    note "E2E accel=tcg (automation imeruka)"
    for t in 120 300 600 900 1200; do at "$t"; alive || break; shot "tcg-$t"; done
fi
sleep 12                                          # acha telemetry iandike uchunguzi wa mwisho
mon "quit"; sleep 2; kill "$QPID" 2>/dev/null
tail -n 40 "$OUT/serial.log" > "$OUT/serial-tail.txt" 2>/dev/null
exit 0
