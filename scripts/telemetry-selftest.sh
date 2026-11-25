#!/bin/bash
# Uhuru OS v19.2: majaribio ya telemetry ya CI bila ISO: (1) emit() haibandikani chini ya waandishi wengi, (2) hukumu inasoma mistari iliyobandikana.
# Matumizi: bash scripts/telemetry-selftest.sh      (kutoka mzizi wa repo). Inahitaji: bash, flock, tee, timeout, sed.
set -u
REPO=${REPO:-$(cd "$(dirname "$0")/.." && pwd)}
TEL="$REPO/config/includes.chroot/usr/local/sbin/uhuru-ci-telemetry"
VERD="$REPO/scripts/e2e-verdict.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ok=0; fail=0
check() { if [ "$2" = 0 ]; then ok=$((ok+1)); else fail=$((fail+1)); echo "  FAIL: $1"; fi; }

echo "1) emit(): mistari haibandikani"
awk '/^emit\(\) \{/{f=1} f{print} f&&/^}/{exit}' "$TEL" > "$T/emit.sh"
[ -s "$T/emit.sh" ]; check "emit() imepatikana kwenye uhuru-ci-telemetry" $?
if command -v flock >/dev/null 2>&1; then
    SERIAL="$T/serial.log"; RUNDIR="$T"; : > "$SERIAL"
    # shellcheck disable=SC1090
    . "$T/emit.sh"
    big=$(for i in $(seq 1 3000); do printf 'UHURU-DIAG lightdm.log: [+%ss] DEBUG: mstari mrefu wa jaribio %s xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n' "$i" "$i"; done)
    for r in 1 2 3; do
        emit "$big" &
        for i in $(seq 1 25); do emit "UHURU-P7 inst=INSTALLER-OK n=$r.$i" & done
        wait
    done
    bad=$(grep -vcE '^(UHURU-DIAG lightdm\.log: \[\+[0-9]+s\] DEBUG: mstari mrefu wa jaribio [0-9]+ x+|UHURU-P7 inst=INSTALLER-OK n=[0-9]+\.[0-9]+)$' "$SERIAL")
    [ "$bad" = 0 ]; check "emit(): mistari yote imekamilika chini ya waandishi 26 kwa wakati mmoja (iliyoharibika: $bad)" $?
    [ "$(grep -c '^UHURU-P7 ' "$SERIAL")" = 75 ]; check "emit(): ujumbe wote 75 wa P7 umefika" $?
    [ "$(grep -c '^UHURU-DIAG ' "$SERIAL")" = 9000 ]; check "emit(): mistari yote 9000 ya DIAG imefika" $?
    # /run isipoandikika: bado inaandika (njia mbadala)
    SERIAL="$T/serial2.log"; RUNDIR="$T/hakuna/kabisa"; : > "$SERIAL"
    emit "UHURU-P7 njia-mbadala"; grep -q '^UHURU-P7 njia-mbadala$' "$SERIAL"; check "emit(): RUNDIR isipoandikika inaandika bila kufungia" $?
    [ "$(grep -c . "$SERIAL")" = 1 ]; check "emit(): njia mbadala haiandiki mara mbili" $?
else
    echo "  (flock haipo: majaribio ya emit yameruka; kwenye ISO ya Debian ipo kwenye util-linux)"
fi

echo "2) e2e-verdict: mistari iliyobandikana"
mkdir -p "$T/s"
printf 'QEMU accel: kvm\nE2E telemetry=ok\n' > "$T/s/e2e.log"
printf 'UHURU-DIAG lightdmUHURU-P7 inst=INSTALLER-OK,modules=34 pkgmiss=none fb=ok acct=ok ts=yes\nUHURU-STATE n=1 x=y\n' > "$T/s/serial.log"
out=$(bash "$VERD" "$T/s" 2>&1)
printf '%s\n' "$out" | grep -q 'CHECK PASS: e2e: awamu ya 7: kisakinishi'; check "verdict: P7 iliyobandikana inasomwa (inst=INSTALLER-OK)" $?
printf '%s\n' "$out" | grep -q 'CHECK FAIL: e2e: awamu ya 7: hakuna ripoti'; [ $? -ne 0 ]; check "verdict: hakuna FAIL ya 'hakuna ripoti ya P7'" $?
printf 'UHURU-STATE n=1 x=y\n' > "$T/s/serial.log"
out=$(bash "$VERD" "$T/s" 2>&1)
printf '%s\n' "$out" | grep -q 'CHECK FAIL: e2e: awamu ya 7: hakuna ripoti'; check "verdict: P7 ikikosekana kweli bado ni FAIL (hukumu haijalegezwa)" $?

echo "3) e2e-verdict: P9 (root na mtumiaji wa kawaida)"
p9line() { printf 'UHURU-P9 fw=FW-OK,x protect=%s usb=USBSCAN-OK,x sign=SIGN-OK,x watch=1 gui=SMOKE-OK aadiag=k=Y%s\n' "$1" "${2:+ uprot=$2}"; }
OKP='PROTECT-OK,n=10,ok=7,warn=1,info=2,bad=0,fw=ok,aa=ok,sysctl=ok,upd=ok,disk=info'
BADP='PROTECT-FAIL,n=10,ok=6,warn=1,info=2,bad=1,fw=ok,aa=bad,sysctl=ok,upd=ok,disk=info'
vrun() { mkdir -p "$T/p9"; printf 'QEMU accel: kvm\nE2E telemetry=ok\n' > "$T/p9/e2e.log"; { echo 'UHURU-STATE n=1 x=y'; p9line "$1" "${2:-}"; } > "$T/p9/serial.log"; bash "$VERD" "$T/p9" 2>&1; }
vrun "$OKP" "$OKP" | grep -q 'CHECK PASS: e2e: awamu ya 9: Kituo cha Ulinzi kwa mtumiaji wa kawaida hakioni hatari'; check "P9: mtumiaji wa kawaida bila hatari = PASS" $?
vrun "$OKP" "$BADP" | grep -q 'CHECK FAIL: e2e: awamu ya 9: mtumiaji wa kawaida anaona hatari'; check "P9: mtumiaji wa kawaida anaona hatari (root ok) = FAIL (kosa la v19.2.2 lingegunduliwa)" $?
vrun "$OKP" "" | grep -q 'mtumiaji wa kawaida'; [ $? -ne 0 ]; check "P9: ripoti bila uprot (ya zamani) haizalishi PASS wala FAIL ya uongo" $?
vrun "$BADP" "$OKP" | grep -q 'CHECK FAIL: e2e: awamu ya 9: Kituo cha Ulinzi kimeona hatari'; check "P9: root ina hatari lakini mtumiaji hana = bado FAIL (regex haivuki mipaka ya sehemu)" $?
vrun "$BADP" "$OKP" | grep -q 'CHECK PASS: e2e: awamu ya 9: AppArmor, kernel'; [ $? -ne 0 ]; check "P9: aa=bad ya root haipiti kwa sababu ya uprot nzuri" $?
ROOTW='PROTECT-OK,n=10,ok=6,warn=2,info=2,bad=0,fw=warn,aa=ok,sysctl=ok,upd=ok,disk=info'
vrun "$ROOTW" "$OKP" | grep -q 'CHECK PASS: e2e: awamu ya 9: AppArmor, kernel'; [ $? -ne 0 ]; check "P9: fw=warn ya root haifichwi na fw=ok ya uprot (regex haivuki mipaka ya sehemu)" $?

# kama CI halisi: P9 za mwanzo zina 'uprot=none' (hakuna session ya mtumiaji), ya mwisho ina matokeo
vmix() { mkdir -p "$T/p9"; printf 'QEMU accel: kvm\nE2E telemetry=ok\n' > "$T/p9/e2e.log"; { echo 'UHURU-STATE n=1 x=y'; p9line "$OKP" none; p9line "$OKP" none; [ -n "${1:-}" ] && p9line "$OKP" "$1"; } > "$T/p9/serial.log"; bash "$VERD" "$T/p9" 2>&1; }
vmix "$BADP" | grep -q 'CHECK FAIL: e2e: awamu ya 9: mtumiaji wa kawaida anaona hatari kwenye Kituo cha Ulinzi (uprot=PROTECT-FAIL,n=10,ok=6,warn=1,info=2,bad=1,fw=ok,aa=bad'; check "P9 mchanganyiko: 'uprot=none' mwanzoni + PROTECT-FAIL baadaye = FAIL yenye matokeo halisi (si 'none')" $?
vmix "$OKP" | grep -q 'CHECK PASS: e2e: awamu ya 9: Kituo cha Ulinzi kwa mtumiaji wa kawaida hakioni hatari'; check "P9 mchanganyiko: 'uprot=none' mwanzoni + PROTECT-OK baadaye = PASS" $?
vmix "" | grep -q 'CHECK INFO: e2e: awamu ya 9: Kituo cha Ulinzi kwa mtumiaji wa kawaida haikupimwa'; check "P9: uprot=none pekee = INFO (haikupimwa), si FAIL wala PASS ya uongo" $?
vmix "" | grep -q 'mtumiaji wa kawaida anaona hatari'; [ $? -ne 0 ]; check "P9: uprot=none pekee haileti FAIL" $?

echo "4) telemetry: p9check inaongeza uprot= (mahali sahihi tu)"
awk '/^p9check\(\) \{/{f=1} f{print} f&&/^}/{exit}' "$TEL" > "$T/p9.sh"
[ -s "$T/p9.sh" ]; check "p9check() imepatikana" $?
grep -q 'up=\$(timeout -k 2 30 runuser -u "\$xu" -- /usr/local/bin/uhuru-protect --check' "$T/p9.sh"; check "p9check inaendesha uhuru-protect --check kama mtumiaji wa session (runuser)" $?
grep -q "uprot=%s" "$T/p9.sh"; check "p9check inaandika uprot= kwenye mstari wa P9" $?
grep -q 'uhuru-protect --aa-debug' "$T/p9.sh" && grep -q "uaa=%s" "$T/p9.sh"; check "p9check inaandika uaa= (ukweli wa AppArmor kwa mtumiaji wa session)" $?
[ "$(grep -c 'uhuru-protect --aa-debug' "$TEL")" = 1 ]; check "uaa inahesabiwa mara moja tu kwenye faili zima" $?
[ "$(grep -c 'up=\$(timeout' "$TEL")" = 1 ]; check "uprot inahesabiwa mara moja tu kwenye faili zima (si kwenye kazi nyingine kwa bahati mbaya)" $?
# endesha p9check halisi kwa zana bandia: mtumiaji wa session anaonekana, na uprot inatoka kwenye uhuru-protect inayoendeshwa KAMA MTUMIAJI huyo
mkdir -p "$T/ub"
printf '#!/bin/bash\nif [ "$1" = "-C" ]; then echo tester; else exec /bin/ps "$@"; fi\n' > "$T/ub/ps"
printf '#!/bin/bash\necho "runuser-kama:$2" >> "$T/runuser.log"; shift 3; exec "$@"\n' > "$T/ub/runuser"
chmod +x "$T/ub"/*
if [ "$(id -u)" = 0 ] && mkdir -p /var/lib 2>/dev/null && [ ! -e /var/lib/uhuru-setup.done ] && [ ! -e /usr/local/bin/uhuru-protect ]; then
    printf '#!/bin/bash\n[ "$1" = --check ] && echo "PROTECT-OK n=10 ok=7 warn=1 info=2 bad=0 fw=ok,aa=ok"\n[ "$1" = --aa-debug ] && echo "AA-DEBUG euid=1001 on=1 act=inactive prof=0 readable=0 disk=0 pkg=1 decision=ok via=userview"\nexit 0\n' > /usr/local/bin/uhuru-protect; chmod +x /usr/local/bin/uhuru-protect; : > /var/lib/uhuru-setup.done
    out=$(PATH="$T/ub:$PATH" T="$T" bash -c ". $T/p9.sh; p9check" 2>/dev/null)
    rm -f /usr/local/bin/uhuru-protect /var/lib/uhuru-setup.done
    printf '%s' "$out" | grep -q ' uprot=PROTECT-OK,n=10,ok=7,warn=1,info=2,bad=0,fw=ok,aa=ok, uaa=AA-DEBUG,euid=1001,on=1,act=inactive,prof=0,readable=0,disk=0,pkg=1,decision=ok,via=userview,$'; check "p9check halisi: uprot= ina matokeo ya uhuru-protect kama mtumiaji (imepatikana: ${out##* })" $?
    grep -q 'runuser-kama:tester' "$T/runuser.log" 2>/dev/null; check "p9check halisi: uhuru-protect --check iliendeshwa kama 'tester', si root" $?
else
    echo "  (si root au /usr/local/bin/uhuru-protect ipo: jaribio la p9check halisi limeruka)"
fi

echo
echo "=== JUMLA: $ok OK, $fail FAIL ==="
[ "$fail" = 0 ]
