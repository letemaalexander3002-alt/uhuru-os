#!/bin/bash
# Hukumu ya login kutoka mwanzo hadi mwisho. Inasoma <dir>/e2e.log (alama za automation) na <dir>/serial.log (telemetry).
DIR=${1:?saraka ya screens}
E="$DIR/e2e.log"; LOG="$DIR/serial.log"
if [ ! -f "$E" ]; then echo "CHECK FAIL: e2e: e2e.log haipo (boot-screens.sh haikuendeshwa?)"; exit 0; fi
has() { grep -q "$1" "$E" 2>/dev/null; }
ck()  { if has "$1"; then echo "CHECK PASS: e2e: $2"; else echo "CHECK FAIL: e2e: $3"; fi; }
if has 'accel=tcg'; then echo "CHECK INFO: e2e: runner haikuwa na KVM; automation iliruka (picha tu)"; exit 0; fi
ck 'E2E telemetry=ok'  "telemetry ya CI inafanya kazi (serial)" "telemetry haikuonekana kwenye serial (huduma haikuanza?)"
FIRST=$(tr -d '\r' < "$LOG" 2>/dev/null | grep '^UHURU-ACCOUNTS' | head -1)
if printf '%s' "$FIRST" | grep -q 'mtumiaji='; then echo "CHECK PASS: e2e: akaunti ya live (mtumiaji) iliundwa wakati wa boot"; else echo "CHECK FAIL: e2e: akaunti ya live HAIKUUNDWA wakati wa boot ($FIRST) - user-setup haipo au live-config imefeli"; fi
ck 'E2E autologin=yes' "boot ya kwanza inaingia desktop yenyewe, bila password" "boot ya kwanza ilionyesha LOGIN SCREEN (autologin haikutokea)"
if has 'E2E autologin=no'; then
    ck 'E2E live-login-manual=ok' "mtumiaji / uhuru imefanya kazi kwenye login screen" "mtumiaji / uhuru HAIFANYI KAZI kwenye login screen"
fi
ck 'E2E wizard=seen'        "wizard ya usajili imetokea baada ya login ya kwanza" "wizard HAIKUTOKEA"
ck 'E2E registered=yes'     "usajili umekamilika (setup.done)" "usajili haukukamilika"
ck 'E2E greeter-after=yes'  "login screen inaonekana baada ya usajili" "login screen haikuonekana baada ya usajili"
ck 'E2E tester-login=yes'   "login ya akaunti mpya (tester / uhurutest1) imefanya kazi" "login ya akaunti mpya IMESHINDIKANA"
ACC=$(tr -d '\r' < "$LOG" 2>/dev/null | grep '^UHURU-ACCOUNTS' | tail -1)
if printf '%s' "$ACC" | grep -q 'mtumiaji=L'; then echo "CHECK PASS: e2e: akaunti ya live (mtumiaji) imefungwa baada ya usajili"; else echo "CHECK FAIL: e2e: akaunti ya live HAIJAFUNGWA ($ACC)"; fi
if printf '%s' "$ACC" | grep -q 'tester=P'; then echo "CHECK PASS: e2e: akaunti mpya (tester) ina password halali"; else echo "CHECK FAIL: e2e: akaunti mpya haina password halali ($ACC)"; fi
echo "--- alama za automation (e2e.log) ---"; cat "$E"
echo "--- mistari ya mwisho ya UHURU-AUTH (majaribio ya kuingia) ---"
tr -d '\r' < "$LOG" 2>/dev/null | grep '^UHURU-AUTH' | tail -8 | sed 's/^/CHECK INFO: auth: /'
echo "--- hali ya mwisho ya mfumo ---"
tr -d '\r' < "$LOG" 2>/dev/null | grep '^UHURU-STATE' | tail -2 | sed 's/^/CHECK INFO: state: /'
exit 0
