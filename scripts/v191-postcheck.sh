#!/bin/bash
# Uhuru OS v19.1: ukaguzi wa BAADA ya build. Unasoma faili ambazo scripts/ci-watch.sh tayari inahifadhi kwenye Downloads
# (report.txt, e2e.log, serial.log, filesystem.packages) na kulinganisha na vigezo vya kukubali vya Mpango Mkuu.
# Matumizi:  bash scripts/v191-postcheck.sh [folda]      (chaguo-msingi: ~/storage/downloads/uhuru-report-v191)
# Msimbo wa kutoka: 0 = vigezo vyote vimetimia, 1 = angalau kimoja kimeshindwa.
set -u
DIR=${1:-$HOME/storage/downloads/uhuru-report-v191}
LIMIT=${LIMIT:-2147483648}           # kikomo cha GitHub Release (byte)
MIN_RESERVE_MIB=${MIN_RESERVE_MIB:-20}
BASE_ISO=${BASE_ISO:-1992589312}     # ISO ya v19.0 (byte)
BASE_PASS=${BASE_PASS:-125}          # CHECK PASS za v19.0
BASE_AVAIL=${BASE_AVAIL:-1206}       # RAM wazi ya CHINI KABISA (MB) kwenye serial.log ya v19.0 (mem=1966); tunalinganisha chini na chini
MAX_RAM_LOSS=${MAX_RAM_LOSS:-100}    # MB
BASE_PKGS=${BASE_PKGS:-1794}
ok=0; bad=0; warn=0
P() { ok=$((ok+1)); echo "POSTCHECK PASS: $*"; }
F() { bad=$((bad+1)); echo "POSTCHECK FAIL: $*"; }
W() { warn=$((warn+1)); echo "POSTCHECK WARN: $*"; }
I() { echo "POSTCHECK INFO: $*"; }
find1() { find "$DIR" -type f -name "$1" 2>/dev/null | head -n 1; }

REPORT=$(find1 report.txt); E2E=$(find1 e2e.log); SERIAL=$(find1 serial.log); PKGS=$(find1 filesystem.packages)
echo "== v19.1 postcheck: $DIR =="
for n in REPORT E2E SERIAL PKGS; do [ -n "${!n}" ] && [ -s "${!n}" ] || { F "faili $n halipo au ni tupu ndani ya $DIR"; }; done
[ "$bad" = 0 ] || { echo "== JUMLA: $ok PASS, $bad FAIL, $warn WARN =="; exit 1; }

# 1) CI ya ISO
npass=$(grep -c '^CHECK PASS' "$REPORT"); nfail=$(grep -c '^CHECK FAIL' "$REPORT")
[ "$nfail" = 0 ] && P "report.txt: hakuna CHECK FAIL" || F "report.txt: CHECK FAIL = $nfail"
[ "$npass" -ge "$BASE_PASS" ] && P "report.txt: CHECK PASS = $npass (v19.0 ilikuwa $BASE_PASS; haipungui)" || F "report.txt: CHECK PASS = $npass, chini ya $BASE_PASS (v19.0)"
grep -q 'HATUA ZOTE (boot -> autologin -> wizard -> usajili -> login mpya) ZIMEPITA' "$REPORT" && P "e2e: HATUA ZOTE ZIMEPITA" || F "e2e: mstari wa 'HATUA ZOTE ... ZIMEPITA' haupo"

# 2) e2e.log: wizard (kanuni 1 na 2 za Mpango: hatua hazibadiliki)
steps=$(grep -c '^E2E wizard-step=.* ok (jaribio 1)$' "$E2E")
[ "$steps" = 9 ] && P "e2e.log: hatua 9 za wizard zimepita jaribio la kwanza" || F "e2e.log: hatua za wizard zilizopita jaribio la kwanza = $steps (tarajio 9)"
for k in 'E2E telemetry=ok' 'E2E autologin=yes' 'E2E wizard=seen' 'E2E registered=yes' 'E2E greeter-after=yes' 'E2E tester-login=yes'; do
    grep -qF "$k" "$E2E" && P "e2e.log: $k" || F "e2e.log: '$k' haipo"
done
I "$(grep 'greeter-method' "$E2E" | head -n 1)"

# 3) Ukubwa wa ISO
iso=$(sed -n 's/.*saizi: *\([0-9][0-9]*\) bytes.*/\1/p' "$REPORT" | head -n 1)
if [ -z "$iso" ]; then F "ukubwa wa ISO haukupatikana kwenye report.txt"; else
    reserve=$((LIMIT - iso)); rmib=$((reserve / 1048576)); delta=$((iso - BASE_ISO)); dmib=$((delta / 1048576))
    I "ISO = $iso byte; akiba hadi kikomo = $reserve byte (MiB $rmib); ongezeko dhidi ya v19.0 = $delta byte (MiB $dmib)"
    [ "$iso" -lt "$LIMIT" ] && P "ISO iko chini ya GiB 2" || F "ISO imezidi kikomo cha GitHub Release (GiB 2)"
    [ "$rmib" -ge "$MIN_RESERVE_MIB" ] && P "akiba ya ISO ni MiB $rmib (angalau $MIN_RESERVE_MIB)" || F "akiba ya ISO ni MiB $rmib tu (inahitajika angalau $MIN_RESERVE_MIB): weka UHURU_INSTALL_ICONS=no kwenye etc/uhuru/theme.defaults"
fi

# 4) Vifurushi
for p in arc-theme papirus-icon-theme at-spi2-core; do
    grep -q "^$p	" "$PKGS" && P "kifurushi $p kipo" || F "kifurushi $p HAKIPO (angalia mstari 'uhuru-theme: ONYO' kwenye logi ya build)"
done
for p in hunspell-sw hunspell-fr firefox-esr-l10n-fr libreoffice-l10n-fr; do
    grep -q "^$p	" "$PKGS" && P "kifurushi cha v19.0 $p bado kipo" || F "kifurushi cha v19.0 $p kimepotea"
done
np=$(grep -c . "$PKGS"); I "jumla ya vifurushi = $np (v19.0: $BASE_PKGS)"

# 5) RAM (kigezo: isipungue zaidi ya MB 100)
min_av=$(grep -o 'avail=[0-9]*' "$SERIAL" | cut -d= -f2 | sort -n | head -n 1)
if [ -z "$min_av" ]; then F "RAM wazi (avail=) haikupatikana kwenye serial.log"; else
    floor=$((BASE_AVAIL - MAX_RAM_LOSS))
    [ "$min_av" -ge "$floor" ] && P "RAM wazi ya chini kabisa = $min_av MB (kiwango cha chini $floor MB; v19.0 ilikuwa $BASE_AVAIL)" || F "RAM wazi = $min_av MB, chini ya $floor MB (urembo unatumia RAM nyingi)"
fi

# 6) Skrini ya kuingia (conf inachapishwa kwenye report.txt kwenye sehemu '--- greeter')
g=$(awk '/^--- greeter/{f=1;next} /^--- /{f=0} /^=====/{f=0} f' "$REPORT")
echo "$g" | grep -q '^theme-name=Arc-Dark$' && P "greeter: theme-name=Arc-Dark" || F "greeter: theme-name=Arc-Dark haipo kwenye conf ya ISO"
echo "$g" | grep -q '^icon-theme-name=' && P "greeter: icon-theme-name imewekwa" || F "greeter: icon-theme-name haipo"
echo "$g" | grep -q '^background=/usr/share/backgrounds/uhuru-os/login-current.png$' && P "greeter: background haijaguswa" || F "greeter: background imebadilika au haipo"
echo "$g" | grep -q '^indicators=.*~language' && P "greeter: indicators (pamoja na lugha) hazijaguswa" || F "greeter: indicators zimebadilika"

# 7) Onyo la AT-SPI (org.a11y.Bus): limetibiwa kwa at-spi2-core
na=$(cat "$REPORT" "$SERIAL" | grep -c 'org.a11y.Bus')
[ "$na" = 0 ] && P "hakuna onyo la AT-SPI (org.a11y.Bus)" || W "onyo la AT-SPI bado linaonekana ($na mistari); angalia 'dbus-launch'/at-spi2-core kwenye session"

# 8) Mambo ambayo CI hii haiwezi kuthibitisha (yaandikwe wazi)
I "haijathibitishwa na faili hizi: mwonekano halisi (angalia picha 02-desktop.jpg, 14-login-screen.jpg), mzunguko wa wallpapers, locale fr_FR (angalia /usr/share/uhuru/theme-build.txt kwenye VM)"
I "kwenye VM: uhuru-mwonekano --check ; uhuru-lugha --check ; ls /usr/share/backgrounds/uhuru"

echo "== JUMLA: $ok PASS, $bad FAIL, $warn WARN =="
[ "$bad" = 0 ]
