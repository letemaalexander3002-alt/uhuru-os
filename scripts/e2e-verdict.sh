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
# ---- Awamu ya 4: taskbar, Start menu, LGT Store (v14.0) ----
P4=$(slogc | grep '^UHURU-P4 ' | tail -n 40)
P4LAST=$(printf '%s\n' "$P4" | tail -n 1)
p4() { printf '%s\n' "$P4" | grep -Eq "$1"; }
if [ -z "$P4" ]; then
    fail "awamu ya 4: hakuna ripoti ya UHURU-P4 (uhuru-store au telemetry haikufanya kazi)"
else
    if p4 'cfg=ok launcher=ok icons=ok'; then echo "CHECK PASS: e2e: awamu ya 4: taskbar, Start menu na faili za LGT Store zipo kwenye ISO"; else fail "awamu ya 4: faili za taskbar/Start menu/LGT Store hazijakamilika ($P4LAST)"; fi
    if p4 'store=CHECK-OK'; then echo "CHECK PASS: e2e: awamu ya 4: orodha ya LGT Store na GTK ni sahihi"; else fail "awamu ya 4: uhuru-store --check imeshindwa ($P4LAST)"; fi
    if p4 'gui=SMOKE-OK'; then echo "CHECK PASS: e2e: awamu ya 4: dirisha la LGT Store linajengwa ndani ya session"; else fail "awamu ya 4: LGT Store haifunguki ndani ya session ($(printf '%s\n' "$P4" | grep -o 'gui=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p4 'whisker=[1-9]'; then echo "CHECK PASS: e2e: awamu ya 4: Start menu (Whisker) inakimbia kwenye taskbar"; else fail "awamu ya 4: Start menu (Whisker) haikimbii; angalia picha 02-desktop na 15-baada-ya-login"; fi
fi
# ---- Awamu ya 5: offline-first, Uhuru Share, zram, ukaguzi wa vifaa (v15.0) ----
P5=$(slogc | grep '^UHURU-P5 ' | tail -n 40)
P5LAST=$(printf '%s\n' "$P5" | tail -n 1)
p5() { printf '%s\n' "$P5" | grep -Eq "$1"; }
if [ -z "$P5" ]; then
    fail "awamu ya 5: hakuna ripoti ya UHURU-P5 (uhuru-share au telemetry haikufanya kazi)"
else
    if p5 'files=ok'; then echo "CHECK PASS: e2e: awamu ya 5: Uhuru Share, uhuru-hwcheck na huduma ya zram zipo kwenye ISO"; else fail "awamu ya 5: faili hazijakamilika ($P5LAST)"; fi
    if p5 'conf=ok'; then echo "CHECK PASS: e2e: awamu ya 5: mipangilio ya offline-first (apt timeout, boot haisubiri mtandao)"; else fail "awamu ya 5: mipangilio ya offline haijakamilika ($P5LAST)"; fi
    if p5 'share=SELFTEST-OK'; then echo "CHECK PASS: e2e: awamu ya 5: Uhuru Share (kifurushi, ukaguzi, LAN, ulinzi wa faili) inapita jaribio la ndani"; else fail "awamu ya 5: uhuru-share --selftest imeshindwa ($(printf '%s\n' "$P5" | grep -o 'share=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p5 'hw=HW-OK'; then echo "CHECK PASS: e2e: awamu ya 5: uhuru-hwcheck inaripoti vifaa"; else fail "awamu ya 5: uhuru-hwcheck imeshindwa ($(printf '%s\n' "$P5" | grep -o 'hw=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p5 'gui=SMOKE-OK'; then echo "CHECK PASS: e2e: awamu ya 5: dirisha la Uhuru Share linajengwa ndani ya session"; else fail "awamu ya 5: Uhuru Share haifunguki ndani ya session ($(printf '%s\n' "$P5" | grep -o 'gui=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    echo "CHECK INFO: e2e: awamu ya 5: RAM ya jaribio na zram ($(printf '%s\n' "$P5LAST" | grep -o 'mem=[0-9]* avail=[0-9]* zram=[a-z]*'))"
fi
# ---- Awamu ya 5.1: locale, folda za mtumiaji, arifa (v15.1) ----
P51=$(slogc | grep '^UHURU-P51 ' | tail -n 40)
P51N=$(printf '%s\n' "$P51" | grep -E 'locerr=[0-9]+' | tail -n 1)
p51() { printf '%s\n' "$P51" | grep -Eq "$1"; }
p51n() { printf '%s\n' "$P51N" | grep -Eq "$1"; }
if [ -z "$P51" ]; then
    fail "awamu ya 5.1: hakuna ripoti ya UHURU-P51 (telemetry haikufanya kazi)"
else
    if p51 'en=ok sw=ok'; then echo "CHECK PASS: e2e: awamu ya 5.1: locale en_US.UTF-8 na sw_TZ.UTF-8 zimetengenezwa"; else fail "awamu ya 5.1: locale hazijatengenezwa ($(printf '%s\n' "$P51" | tail -n 1))"; fi
    if p51 'loc=ok' && p51n 'locerr=0 '; then echo "CHECK PASS: e2e: awamu ya 5.1: locale ya session inatumika, hakuna onyo la 'Locale not supported'"; else fail "awamu ya 5.1: locale ya session ina tatizo ($(printf '%s\n' "$P51N" | cut -c1-120))"; fi
    if p51 'xdg=ok' && p51n 'xdgwarn=0 '; then echo "CHECK PASS: e2e: awamu ya 5.1: folda za mtumiaji (XDG) zipo, hakuna onyo la Download dir"; else fail "awamu ya 5.1: folda za mtumiaji zina tatizo ($(printf '%s\n' "$P51N" | cut -c1-120))"; fi
    if p51 'notifyd=ok' && p51 'notify=ok'; then echo "CHECK PASS: e2e: awamu ya 5.1: huduma ya arifa (xfce4-notifyd) inajibu kwenye session"; else fail "awamu ya 5.1: arifa hazifanyi kazi ($(printf '%s\n' "$P51" | grep -o 'notify=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    echo "CHECK INFO: e2e: awamu ya 5.1: lugha ya session ($(printf '%s\n' "$P51N" | grep -o 'lang=[^ ]*'))"
fi
# ---- Jaribio la RAM 2GB (lengo la chini la Uhuru OS) ----
RAMT=$(printf '%s\n' "$P5" | grep -o ' mem=[0-9]*' | tail -n 1 | tr -dc '0-9')
RAMA=$(printf '%s\n' "$P5" | grep -o ' avail=[0-9]*' | tail -n 1 | tr -dc '0-9')
if [ -z "$RAMT" ] || [ "$RAMT" -le 0 ]; then
    fail "RAM 2GB: hakuna ripoti ya RAM kutoka UHURU-P5"
elif [ "$RAMT" -gt 2100 ]; then
    echo "CHECK INFO: e2e: RAM ya jaribio ni ${RAMT}MB (si profile ya 2GB)"
elif [ "${RAMA:-0}" -lt 300 ]; then
    fail "RAM 2GB: RAM wazi ni ${RAMA:-0}MB tu kati ya ${RAMT}MB (inatakiwa angalau 300MB wakati desktop, Store na Share vimefunguliwa)"
else
    echo "CHECK PASS: e2e: RAM 2GB: desktop, LGT Store na Uhuru Share vinafanya kazi kwenye ${RAMT}MB (wazi ${RAMA}MB)"
fi
if [ "$FAILS" -eq 0 ]; then echo "CHECK PASS: e2e: HATUA ZOTE (boot -> autologin -> wizard -> usajili -> login mpya) ZIMEPITA"; fi
details
exit 0
