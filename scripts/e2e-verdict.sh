#!/bin/bash
# Hukumu ya login kutoka mwanzo hadi mwisho. Inasoma <dir>/e2e.log (alama za automation) na <dir>/serial.log (telemetry).
# v13.9: telemetry ikisimama ni FAIL MOJA ya wazi ("HAIJATHIBITISHWA"), siyo FAIL nane za uongo; funguo hazichapwi kwa upofu.
DIR=${1:?saraka ya screens}
E="$DIR/e2e.log"; LOG="$DIR/serial.log"
if [ ! -f "$E" ]; then echo "CHECK FAIL: e2e: e2e.log haipo (boot-screens.sh haikuendeshwa?)"; exit 0; fi
FAILS=0
has() { grep -q "$1" "$E" 2>/dev/null; }
ck()  { if has "$1"; then echo "CHECK PASS: e2e: $2"; else echo "CHECK FAIL: e2e: $3"; FAILS=$((FAILS+1)); fi; }
fail(){ echo "CHECK FAIL: e2e: $1"; FAILS=$((FAILS+1)); }
slogc() { tr -d '\r' < "$LOG" 2>/dev/null; }
details() {
    echo "--- alama za automation (e2e.log) ---"; cat "$E"
    echo "--- njia ya kuingia iliyofanya kazi kwenye login screen ---"
    grep 'greeter-method' "$E" | sed 's/^/CHECK INFO: e2e: /'
    echo "--- UCHUNGUZI WA KINA (UHURU-DIAG, block ya mwisho) ---"
    slogc | awk '/^UHURU-DIAG-BEGIN/{buf=""} {buf=buf $0 "\n"} /^UHURU-DIAG-END/{last=buf} END{printf "%s", last}' | grep '^UHURU-DIAG ' | sed 's/^/CHECK INFO: diag: /'
    echo "--- mistari ya mwisho ya UHURU-AUTH (majaribio ya kuingia) ---"
    slogc | grep '^UHURU-AUTH' | tail -8 | sed 's/^/CHECK INFO: auth: /'
    echo "--- hali ya mwisho ya mfumo ---"
    slogc | grep '^UHURU-STATE' | tail -2 | sed 's/^/CHECK INFO: state: /'
}
if has 'accel=tcg'; then echo "CHECK INFO: e2e: runner haikuwa na KVM; automation iliruka (picha tu)"; exit 0; fi

if has 'telemetry=missing'; then
    fail "telemetry haikuonekana kwenye serial (huduma ya uhuru-ci-telemetry haikuanza?)"; details; exit 0
fi
echo "CHECK PASS: e2e: telemetry ya CI inafanya kazi (serial)"
if has 'telemetry=stale'; then
    N=$(grep -o 'telemetry=stale n=[0-9]*' "$E" | tail -1 | sed 's/.*n=//')
    fail "HAIJATHIBITISHWA: telemetry ilisimama (n ya mwisho=$N). Hii ni kasoro ya telemetry/mtihani, siyo ushahidi kuwa login imeshindwa. Tazama 99-telemetry-stale.jpg na UHURU-DIAG hapa chini"
    details; exit 0
fi

FIRST=$(slogc | grep '^UHURU-ACCOUNTS' | head -1)
if printf '%s' "$FIRST" | grep -q 'mtumiaji='; then echo "CHECK PASS: e2e: akaunti ya live (mtumiaji) iliundwa wakati wa boot"; else fail "akaunti ya live HAIKUUNDWA wakati wa boot ($FIRST) - user-setup haipo au live-config imefeli"; fi
ck 'E2E autologin=yes' "boot ya kwanza inaingia desktop yenyewe, bila password" "boot ya kwanza ilionyesha LOGIN SCREEN (autologin haikutokea)"
if has 'E2E autologin=no'; then
    if has 'greeter-visible=no'; then fail "login screen haikuonekana wala desktop baada ya boot (mfumo umekwama kabla ya session)"
    else ck 'E2E live-login-manual=ok' "mtumiaji / uhuru imefanya kazi kwenye login screen" "mtumiaji / uhuru HAIFANYI KAZI kwenye login screen"; fi
fi
ck 'E2E wizard=seen'        "wizard ya usajili imetokea baada ya login ya kwanza" "wizard HAIKUTOKEA"
if has 'E2E wizard=seen'; then
    ck 'E2E registered=yes'     "usajili umekamilika (setup.done)" "usajili haukukamilika"
    ck 'E2E greeter-after=yes'  "login screen inaonekana baada ya usajili" "login screen haikuonekana baada ya usajili"
    if has 'E2E greeter-after=yes'; then
        ck 'E2E tester-login=yes'   "login ya akaunti mpya (tester / uhurutest1) imefanya kazi" "login ya akaunti mpya IMESHINDIKANA"
    fi
    ACC=$(slogc | grep '^UHURU-ACCOUNTS' | tail -1)
    if printf '%s' "$ACC" | grep -q 'mtumiaji=L'; then echo "CHECK PASS: e2e: akaunti ya live (mtumiaji) imefungwa baada ya usajili"; else fail "akaunti ya live HAIJAFUNGWA ($ACC)"; fi
    if printf '%s' "$ACC" | grep -q 'tester=P'; then echo "CHECK PASS: e2e: akaunti mpya (tester) ina password halali"; else fail "akaunti mpya haina password halali ($ACC)"; fi
fi
if [ "$FAILS" -eq 0 ]; then echo "CHECK PASS: e2e: HATUA ZOTE (boot -> autologin -> wizard -> usajili -> login mpya) ZIMEPITA"; fi
details
exit 0
