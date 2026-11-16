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
# ---- Awamu ya 6: Letema kama programu halisi (PWA), katalogi ya mbali na Vendor Console (v16.0) ----
P6=$(slogc | grep '^UHURU-P6 ' | tail -n 40)
p6() { printf '%s\n' "$P6" | grep -Eq "$1"; }
P6WIN=$(printf '%s\n' "$P6" | grep -o 'win=[^ ]* cls=[^ ]*' | grep -v 'win=wait\|win=running' | tail -n 1)
if [ -z "$P6" ]; then
    fail "awamu ya 6: hakuna ripoti ya UHURU-P6 (telemetry haikufanya kazi)"
else
    if p6 'files=ok conf=ok'; then echo "CHECK PASS: e2e: awamu ya 6: LGT Store, usanidi wa katalogi ya mbali (https) na zana za ukaguzi zipo kwenye ISO"; else fail "awamu ya 6: faili/usanidi haujakamilika ($(printf '%s\n' "$P6" | tail -n 1 | cut -c1-120))"; fi
    if p6 'store=P6-OK'; then echo "CHECK PASS: e2e: awamu ya 6: katalogi ya mbali inakaguliwa kwa ukali (hakuna apt/http/sindano), akiba inafanya kazi bila mtandao, njia za mkato za PWA ni sahihi"; else fail "awamu ya 6: uhuru-store --p6-check imeshindwa ($(printf '%s\n' "$P6" | grep -o 'store=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p6 'real=ok'; then echo "CHECK PASS: e2e: awamu ya 6: TraceTZ Hub na Letema Group Tech zinasakinishwa kama programu halisi (--app, profile yake, WM_CLASS) kwenye session ya mtumiaji"; else fail "awamu ya 6: PWA za Letema hazikusakinishwa kwenye session ($(printf '%s\n' "$P6" | grep -o 'real=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if printf '%s\n' "$P6WIN" | grep -q 'win=ok'; then
        echo "CHECK PASS: e2e: awamu ya 6: TraceTZ Hub inafunguka kama dirisha la programu yake (si tab ya browser)"
        if printf '%s\n' "$P6WIN" | grep -q 'lgt-tracetz'; then echo "CHECK PASS: e2e: awamu ya 6: dirisha lina WM_CLASS ya programu (taskbar inaipanga kama programu yake)"; else echo "CHECK INFO: e2e: awamu ya 6: WM_CLASS ya dirisha si lgt-tracetz ($(printf '%s\n' "$P6WIN" | grep -o 'cls=[^ ]*'))"; fi
    else
        fail "awamu ya 6: TraceTZ Hub haikufungua dirisha la programu (${P6WIN:-hakuna matokeo ya win; $(printf '%s\n' "$P6" | grep -o 'win=[^ ]*' | sort -u | tr '\n' ' ')})"
    fi
    echo "CHECK INFO: e2e: awamu ya 6: katalogi ya mbali kutoka GitHub ($(printf '%s\n' "$P6" | grep -o 'sync=[^ ]*' | tail -n 1)); SYNC-OK = repo ni ya umma na inasomeka, http_404 = repo ni private au faili halipo"
fi
# ---- Awamu ya 7: kisakinishi (Calamares), Secure Boot, LUKS (v17.1) ----
P7=$(slogc | grep '^UHURU-P7 ' | tail -n 40)
P7LAST=$(printf '%s\n' "$P7" | tail -n 1)
p7() { printf '%s\n' "$P7" | grep -Eq "$1"; }
if [ -z "$P7" ]; then
    fail "awamu ya 7: hakuna ripoti ya UHURU-P7 (uhuru-installer au telemetry haikufanya kazi)"
else
    if p7 'inst=INSTALLER-OK'; then echo "CHECK PASS: e2e: awamu ya 7: kisakinishi cha Uhuru kina muundo kamili (chapa, moduli zote, Secure Boot, LUKS, ext4/btrfs/xfs/fat)"; else fail "awamu ya 7: muundo wa kisakinishi una upungufu ($(printf '%s\n' "$P7" | grep -o 'inst=[^ ]*' | sort -u | tail -n 1))"; fi
    if p7 'pkgmiss=none'; then echo "CHECK PASS: e2e: awamu ya 7: vifurushi vya usakinishaji vipo (calamares, cryptsetup-initramfs, shim-signed, lvm2, btrfs, xfs, grub signed)"; else fail "awamu ya 7: vifurushi vinakosekana: $(printf '%s\n' "$P7" | grep -o 'pkgmiss=[^ ]*' | sort -u | tail -n 1)"; fi
    if p7 'fb=ok acct=ok'; then echo "CHECK PASS: e2e: awamu ya 7: usafi wa mara ya kwanza na orodha ya watumiaji (mfumo uliosakinishwa) vimewekwa"; else fail "awamu ya 7: firstboot/accountsservice si sawa ($P7LAST)"; fi
    echo "CHECK INFO: e2e: awamu ya 7: $(printf '%s\n' "$P7" | grep -o 'inst=[^ ]*' | tail -n 1) $(printf '%s\n' "$P7" | grep -o 'ts=[^ ]*' | tail -n 1)  (efi=no ni kawaida kwa QEMU ya BIOS ya CI)"
fi
# ---- Awamu ya 8: Uhuru Dev Edition (v17.0) ----
P8=$(slogc | grep '^UHURU-P8 ' | tail -n 40)
P8LAST=$(printf '%s\n' "$P8" | tail -n 1)
p8() { printf '%s\n' "$P8" | grep -Eq "$1"; }
if [ -z "$P8" ]; then
    fail "awamu ya 8: hakuna ripoti ya UHURU-P8 (uhuru-dev au telemetry haikufanya kazi)"
else
    if p8 'cfg=ok'; then echo "CHECK PASS: e2e: awamu ya 8: .zshrc, tmux, neovim na Uhuru Terminal (uhuru-shell) zimewekwa kwenye /etc/skel"; else fail "awamu ya 8: mipangilio ya shell/terminali haijakamilika ($P8LAST)"; fi
    if p8 'dev=DEV-OK'; then echo "CHECK PASS: e2e: awamu ya 8: zana zote za msingi za ujenzi zipo (git, gcc, node, python, live-build, n.k.)"; else fail "awamu ya 8: zana za msingi zinakosekana ($(printf '%s\n' "$P8" | grep -o 'coremissing=[^ ]*' | tail -n 1))"; fi
    if p8 'zsh=ZSH-OK,[0-9.]+,sug=1,hl=1,mkcd=1'; then echo "CHECK PASS: e2e: awamu ya 8: zsh inapakia .zshrc kwenye session ya mtumiaji (mapendekezo, rangi za syntax, aliases)"; else fail "awamu ya 8: zsh haipakii vizuri ($(printf '%s\n' "$P8" | grep -o 'zsh=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p8 'bash=BASH-OK' && p8 'shell=zsh'; then echo "CHECK PASS: e2e: awamu ya 8: bash bado inafanya kazi na Uhuru Terminal inachagua zsh"; else fail "awamu ya 8: bash au uhuru-shell ina tatizo ($P8LAST)"; fi
    OM=$(printf '%s\n' "$P8" | grep -o 'optmissing=[^ ]*' | tail -n 1)
    echo "CHECK INFO: e2e: awamu ya 8: zana za ziada zisizopatikana: ${OM#optmissing=}"
fi
# ---- Awamu ya 9: ulinzi (v17.1) ----
P9=$(slogc | grep '^UHURU-P9 ' | tail -n 40)
P9LAST=$(printf '%s\n' "$P9" | tail -n 1)
p9() { printf '%s\n' "$P9" | grep -Eq "$1"; }
if [ -z "$P9" ]; then
    fail "awamu ya 9: hakuna ripoti ya UHURU-P9 (uhuru-protect au telemetry haikufanya kazi)"
else
    if p9 'fw=FW-OK'; then echo "CHECK PASS: e2e: awamu ya 9: ngome ya moto (nftables) inafanya kazi: kila kinachoingia kinabanwa ($(printf '%s\n' "$P9" | grep -o 'fw=[^ ]*' | tail -n 1))"; else fail "awamu ya 9: ngome ya moto haifanyi kazi ($(printf '%s\n' "$P9" | grep -o 'fw=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p9 'protect=PROTECT-OK,.*,bad=0,'; then echo "CHECK PASS: e2e: awamu ya 9: Kituo cha Ulinzi hakioni kipengele chochote chenye hatari"; else fail "awamu ya 9: Kituo cha Ulinzi kimeona hatari ($(printf '%s\n' "$P9" | grep -o 'protect=[^ ]*' | sort -u | tail -n 1))"; fi
    if p9 'protect=PROTECT-OK,.*fw=ok,aa=ok,sysctl=ok,upd=ok'; then echo "CHECK PASS: e2e: awamu ya 9: AppArmor, kernel iliyoimarishwa na sasisho za usalama vimewekwa"; else fail "awamu ya 9: AppArmor/kernel/sasisho si sawa [$(printf '%s\n' "$P9" | grep -o 'aadiag=[^ ]*' | tail -n 1)] ($(printf '%s\n' "$P9" | grep -o 'protect=[^ ]*' | sort -u | tail -n 1))"; fi
    if p9 'usb=USBSCAN-OK'; then echo "CHECK PASS: e2e: awamu ya 9: Flash Safe inatambua virus vya shortcut/autorun, haikosei faili safi, na inasafisha kwa karantini"; else fail "awamu ya 9: Flash Safe selftest imeshindwa ($(printf '%s\n' "$P9" | grep -o 'usb=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p9 'watch=[1-9]'; then echo "CHECK PASS: e2e: awamu ya 9: mlinzi wa flash (uhuru-usbwatch) anakimbia kwenye session ya mtumiaji"; else fail "awamu ya 9: mlinzi wa flash hakimbii kwenye session ($P9LAST)"; fi
    if p9 'sign=SIGN-OK'; then echo "CHECK PASS: e2e: awamu ya 9: saini za kidijitali (ed25519) zinafanya kazi, na mabadiliko ya faili yanagunduliwa"; else fail "awamu ya 9: uhuru-sign imeshindwa ($(printf '%s\n' "$P9" | grep -o 'sign=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p9 'gui=SMOKE-OK'; then echo "CHECK PASS: e2e: awamu ya 9: dirisha la Kituo cha Ulinzi linajengwa ndani ya session"; else fail "awamu ya 9: Kituo cha Ulinzi hakifunguki ndani ya session ($(printf '%s\n' "$P9" | grep -o 'gui=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    echo "CHECK INFO: e2e: awamu ya 9: $(printf '%s\n' "$P9" | grep -o 'protect=[^ ]*' | tail -n 1)"
fi
if [ "$FAILS" -eq 0 ]; then echo "CHECK PASS: e2e: HATUA ZOTE (boot -> autologin -> wizard -> usajili -> login mpya) ZIMEPITA"; fi
details
exit 0
