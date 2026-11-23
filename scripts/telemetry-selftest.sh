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

echo
echo "=== JUMLA: $ok OK, $fail FAIL ==="
[ "$fail" = 0 ]
