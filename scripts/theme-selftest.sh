#!/bin/bash
# Uhuru OS v19.1: majaribio ya urembo bila ISO (GitHub Actions: .github/workflows/theme-check.yml, na Termux).
# Matumizi: bash scripts/theme-selftest.sh      (kutoka mzizi wa repo). Inahitaji: bash, python3, awk, sed, cmp.
set -u
REPO=${REPO:-$(cd "$(dirname "$0")/.." && pwd)}
B="$REPO/config/includes.chroot"
HOOK="$REPO/config/hooks/live/9999-uhuru-theme.hook.chroot"
DEFS="$B/etc/uhuru/theme.defaults"
TOOL="$B/usr/local/lib/uhuru/uhuru-theme-tool"
MW="$B/usr/local/bin/uhuru-mwonekano"
WPDIR="$B/usr/share/backgrounds/uhuru"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ok=0; fail=0
check() { if [ "$2" = 0 ]; then ok=$((ok+1)); else fail=$((fail+1)); echo "  FAIL: $1"; fi; }
eq() { [ "$2" = "$3" ]; check "$1 (tarajio '$3', imepatikana '$2')" $?; }
has() { grep -qF -- "$3" "$2"; check "$1" $?; }
hasnt() { ! grep -qF -- "$3" "$2"; check "$1" $?; }
tree_sum() { (cd "$1" && find . -type f -o -type l | sort | while read -r f; do if [ -L "$f" ]; then echo "L $f $(readlink "$f")"; else echo "F $f $(cksum < "$f")"; fi; done); }

# 0) mazingira: XML ya Python lazima ifanye kazi (Termux: pkg upgrade -y && pkg install -y --reinstall libexpat python)
if ! python3 -c "import xml.parsers.expat, xml.etree.ElementTree" 2>"$T/xmlenv"; then
    echo "KOSA LA MAZINGIRA (si la mradi): python3 haiwezi kusoma XML (expat imevunjika)."
    echo "  Rekebisha:  pkg update -y && pkg upgrade -y && pkg install -y --reinstall libexpat python"
    tail -n 2 "$T/xmlenv" | sed 's/^/  /'
    exit 3
fi

echo "1) Syntax na ruhusa"
bash -n "$MW"; check "bash -n uhuru-mwonekano" $?
sh -n "$HOOK"; check "sh -n hook 9999-uhuru-theme" $?
if command -v dash >/dev/null 2>&1; then dash -n "$HOOK"; check "dash -n hook (sh ya Debian)" $?; fi
sh -c ". '$DEFS'" ; check "theme.defaults inapakiwa na sh bila kosa" $?
python3 -m py_compile "$TOOL" 2>"$T/pyerr"; check "uhuru-theme-tool: python compile" $?
find "$REPO" -name __pycache__ -path "*uhuru*" -exec rm -rf {} + 2>/dev/null
[ -x "$MW" ] && [ -x "$TOOL" ] && [ -x "$HOOK" ]; check "uhuru-mwonekano, uhuru-theme-tool na hook vina ruhusa ya kuendeshwa" $?
tail -n 1 "$HOOK" | grep -q '^exit 0$'; check "hook inaisha kwa exit 0" $?
! grep -qE '^\s*set -e' "$HOOK"; check "hook haitumii 'set -e' (haivunji build)" $?
for k in UHURU_DEFAULT_MODE UHURU_GTK_LIGHT UHURU_GTK_DARK UHURU_ICONS_LIGHT UHURU_ICONS_DARK UHURU_ICONS_FALLBACK UHURU_GREETER_GTK UHURU_GREETER_ICONS UHURU_FONT UHURU_GREETER_FONT UHURU_INSTALL_THEME UHURU_INSTALL_ICONS; do
    grep -q "^$k=" "$DEFS"; check "theme.defaults ina $k" $?
done
for p in at-spi2-core arc-theme papirus-icon-theme; do has "hook inataja $p" "$HOOK" "$p"; done
# hakuna siri/token kwenye faili za v19.1
! grep -rIEq --exclude=theme-selftest.sh '(ghp_|github_pat_|BEGIN [A-Z ]*PRIVATE KEY|sk-[A-Za-z0-9]{20,})' "$B" "$HOOK" "$REPO/scripts" 2>/dev/null; check "hakuna siri/token kwenye faili za v19.1" $?

echo "2) uhuru-theme-tool: xsettings na xfwm4"
X="$T/x/xsettings.xml"
python3 "$TOOL" xsettings "$X" --gtk Arc --icons Papirus --font "Noto Sans 10"; check "xsettings: faili jipya linaundwa" $?
xmllint --noout "$X" 2>/dev/null || python3 -c "import xml.dom.minidom,sys; xml.dom.minidom.parse('$X')"; check "xsettings: XML ni sahihi" $?
has "xsettings: ThemeName=Arc" "$X" 'name="ThemeName" type="string" value="Arc"'
has "xsettings: IconThemeName=Papirus" "$X" 'name="IconThemeName" type="string" value="Papirus"'
has "xsettings: FontName" "$X" 'name="FontName" type="string" value="Noto Sans 10"'
cat > "$T/xs2.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Adwaita"/>
    <property name="EnableEventSounds" type="bool" value="false"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="int" value="96"/>
  </property>
</channel>
XML
python3 "$TOOL" xsettings "$T/xs2.xml" --gtk Arc-Dark --icons Papirus-Dark --font "Noto Sans 10"; check "xsettings: faili lililopo linasasishwa" $?
has "xsettings: ThemeName imebadilika" "$T/xs2.xml" 'value="Arc-Dark"'
hasnt "xsettings: Adwaita imeondoka" "$T/xs2.xml" 'value="Adwaita"'
has "xsettings: mpangilio mwingine (EnableEventSounds) umehifadhiwa" "$T/xs2.xml" 'EnableEventSounds'
has "xsettings: mpangilio mwingine (Xft/DPI) umehifadhiwa" "$T/xs2.xml" 'name="DPI" type="int" value="96"'
n1=$(cksum < "$T/xs2.xml"); python3 "$TOOL" xsettings "$T/xs2.xml" --gtk Arc-Dark --icons Papirus-Dark --font "Noto Sans 10"; eq "xsettings: idempotent (kurudia hakubadilishi)" "$(cksum < "$T/xs2.xml")" "$n1"
[ "$(grep -c 'name="ThemeName"' "$T/xs2.xml")" = 1 ]; check "xsettings: hakuna nakala ya ThemeName" $?
printf 'takataka <<<' > "$T/bad.xml"; python3 "$TOOL" xsettings "$T/bad.xml" --gtk Arc --icons Papirus; check "xsettings: faili bovu linajengwa upya bila kuanguka" $?
has "xsettings: faili bovu limerekebishwa" "$T/bad.xml" 'value="Arc"'
python3 "$TOOL" xfwm4 "$T/x/xfwm4.xml" --theme Arc; check "xfwm4: faili jipya" $?
has "xfwm4: general/theme=Arc" "$T/x/xfwm4.xml" 'name="theme" type="string" value="Arc"'
python3 "$TOOL" xfwm4 "$T/x/xfwm4.xml" --theme Arc-Dark; has "xfwm4: theme inabadilika" "$T/x/xfwm4.xml" 'value="Arc-Dark"'
python3 "$TOOL" bogus >/dev/null 2>&1; eq "amri isiyojulikana inatoka kwa msimbo 2" "$?" 2

echo "3) uhuru-theme-tool: greeter (conf halisi ya ISO v19.0)"
cat > "$T/g.conf" <<'CONF'
[greeter]
background=/usr/share/backgrounds/uhuru-os/login-current.png
user-background=false
clock-format=%a %d %b, %H:%M
indicators=~host;~spacer;~clock;~spacer;~language;~session;~a11y;~power
position=50%,center 50%,center
font-name=Sans 11
CONF
python3 "$TOOL" greeter "$T/g.conf" --gtk Arc-Dark --icons Papirus-Dark --font "Noto Sans 11"; check "greeter: inaendeshwa" $?
has "greeter: theme-name" "$T/g.conf" "theme-name=Arc-Dark"
has "greeter: icon-theme-name" "$T/g.conf" "icon-theme-name=Papirus-Dark"
has "greeter: font-name inabadilishwa" "$T/g.conf" "font-name=Noto Sans 11"
hasnt "greeter: 'Sans 11' ya zamani imeondoka" "$T/g.conf" "font-name=Sans 11"
has "greeter: background haijaguswa" "$T/g.conf" "background=/usr/share/backgrounds/uhuru-os/login-current.png"
has "greeter: indicators hazijaguswa" "$T/g.conf" "indicators=~host;~spacer;~clock;~spacer;~language;~session;~a11y;~power"
has "greeter: position haijaguswa" "$T/g.conf" "position=50%,center 50%,center"
has "greeter: clock-format haijaguswa" "$T/g.conf" "clock-format=%a %d %b, %H:%M"
n1=$(cksum < "$T/g.conf"); python3 "$TOOL" greeter "$T/g.conf" --gtk Arc-Dark --icons Papirus-Dark --font "Noto Sans 11"; eq "greeter: idempotent" "$(cksum < "$T/g.conf")" "$n1"
[ "$(grep -c '^theme-name=' "$T/g.conf")" = 1 ]; check "greeter: theme-name mara moja tu" $?
printf '[greeter]\n#theme-name=Old\ntheme-name=A\ntheme-name=B\n[other]\nfoo=1\n' > "$T/g2.conf"
python3 "$TOOL" greeter "$T/g2.conf" --gtk Arc-Dark --icons Papirus-Dark --font "Noto Sans 11"
[ "$(grep -c '^theme-name=' "$T/g2.conf")" = 1 ]; check "greeter: nakala mbili za theme-name zinakuwa moja" $?
has "greeter: maoni yamehifadhiwa" "$T/g2.conf" "#theme-name=Old"
has "greeter: sehemu nyingine ([other]) haijaguswa" "$T/g2.conf" "foo=1"
awk '/^\[other\]/{o=1} o&&/icon-theme-name/{bad=1} END{exit bad}' "$T/g2.conf"; check "greeter: funguo mpya zimeingia ndani ya [greeter], si [other]" $?
python3 "$TOOL" greeter "$T/none/new.conf" --gtk Arc-Dark; has "greeter: faili lisilokuwepo linaundwa" "$T/none/new.conf" "theme-name=Arc-Dark"

echo "4) uhuru-theme-tool: desktop-i18n"
D="$T/apps"; mkdir -p "$D"
printf '[Desktop Entry]\nType=Application\nName=Duka la LGT\nComment=Programu na vifurushi\nExec=/usr/local/bin/uhuru-store\nIcon=x\nActions=new;\n[Desktop Action new]\nName=Mpya\nExec=/usr/local/bin/uhuru-store --new\n' > "$D/uhuru-store.desktop"
printf '[Desktop Entry]\nType=Application\nName=Kituo cha Ulinzi\nExec=/usr/local/bin/uhuru-protect %%U\nName[en]=Protection\n' > "$D/uhuru-kulinda.desktop"
printf '[Desktop Entry]\nType=Application\nName=Zana\nExec=uhuru-xyz' > "$D/uhuru-xyz.desktop"
printf '[Desktop Entry]\nType=Application\nName=Firefox\nExec=firefox\n' > "$D/firefox.desktop"
cp "$B/usr/share/applications/uhuru-mwonekano.desktop" "$D/"
python3 "$TOOL" desktop-i18n "$D" --quiet; check "desktop-i18n: inaendeshwa" $?
has "desktop-i18n: Name[en] ya Duka" "$D/uhuru-store.desktop" "Name[en]=LGT Store"
has "desktop-i18n: Name[fr] ya Duka" "$D/uhuru-store.desktop" "Name[fr]=Boutique LGT"
has "desktop-i18n: Name= ya Kiswahili haijaguswa" "$D/uhuru-store.desktop" "Name=Duka la LGT"
awk '/^\[Desktop Action/{a=1} a&&/Name\[en\]/{bad=1} END{exit bad}' "$D/uhuru-store.desktop"; check "desktop-i18n: tafsiri ziko ndani ya [Desktop Entry], si [Desktop Action]" $?
has "desktop-i18n: inatambua kwa Exec= (uhuru-protect)" "$D/uhuru-kulinda.desktop" "Name[fr]=Centre de sécurité"
has "desktop-i18n: Name[en] iliyopo haibadilishwi" "$D/uhuru-kulinda.desktop" "Name[en]=Protection"
hasnt "desktop-i18n: Name[en] haiwekwi mara ya pili" "$D/uhuru-kulinda.desktop" "Name[en]=Security Center"
eq "desktop-i18n: uhuru-xyz (haijulikani) haiguswi" "$(cksum < "$D/uhuru-xyz.desktop")" "$(printf '[Desktop Entry]\nType=Application\nName=Zana\nExec=uhuru-xyz' | cksum)"
eq "desktop-i18n: firefox.desktop haiguswi" "$(cksum < "$D/firefox.desktop")" "$(printf '[Desktop Entry]\nType=Application\nName=Firefox\nExec=firefox\n' | cksum)"
has "desktop-i18n: Comment[fr] ya Duka (Comment= ipo)" "$D/uhuru-store.desktop" "Comment[fr]=Applications et paquets pour Uhuru OS"
hasnt "desktop-i18n: faili bila Comment= halipati Comment[en] (kosa la v19.1)" "$D/uhuru-kulinda.desktop" "Comment["
printf '[Desktop Entry]\nType=Application\nName=Duka\nExec=/usr/local/bin/uhuru-store\n[Desktop Action x]\nName=Sehemu\nName[en]=Part\n' > "$D/lgt-store.desktop"
python3 "$TOOL" desktop-i18n "$D/lgt-store.desktop" --quiet; check "desktop-i18n: faili lenye Name[en] ndani ya Action pekee" $?
has "desktop-i18n: Name[en] inaongezwa kwenye [Desktop Entry] hata kama Action ina yake" "$D/lgt-store.desktop" "Name[en]=LGT Store"
n1=$(for f in "$D"/*.desktop; do cksum < "$f"; done); python3 "$TOOL" desktop-i18n "$D" --quiet; eq "desktop-i18n: idempotent" "$(for f in "$D"/*.desktop; do cksum < "$f"; done)" "$n1"
python3 "$TOOL" desktop-i18n "$D" | grep -q "haijulikani=1"; check "desktop-i18n: inaripoti faili 1 isiyojulikana (uhuru-xyz)" $?
if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$D/uhuru-store.desktop" "$D/uhuru-mwonekano.desktop" "$D/uhuru-kulinda.desktop" >"$T/dfv" 2>&1; check "desktop-file-validate (faili zilizotafsiriwa)" $?
    sed 's/^/    dfv: /' "$T/dfv" | head -n 8
fi
if command -v desktop-file-validate >/dev/null 2>&1; then desktop-file-validate "$B/usr/share/applications/uhuru-mwonekano.desktop"; check "desktop-file-validate: uhuru-mwonekano.desktop" $?; fi

echo "5) uhuru-mwonekano (xfconf-query bandia)"
mkdir -p "$T/th/Arc/xfwm4" "$T/th/Arc-Dark/xfwm4" "$T/ic/Papirus" "$T/ic/Papirus-Dark" "$T/ic/Adwaita" "$T/bin"
cat > "$T/bin/xq" <<'XQ'
#!/bin/sh
echo "$*" >> "$XQ_LOG"
exit 0
XQ
chmod +x "$T/bin/xq"
mwenv() { env UHURU_THEME_DEFAULTS="$DEFS" UHURU_THEMES_DIR="$T/th" UHURU_ICONS_DIR="$T/ic" UHURU_MODE_FILE="$T/mode" UHURU_XFCONF="$T/bin/xq" XQ_LOG="$T/xq.log" HOME="$T/home" "$@"; }
: > "$T/xq.log"
mwenv "$MW" --dark >"$T/o" 2>&1; check "mwonekano --dark inafanikiwa" $?
has "mwonekano --dark: ThemeName=Arc-Dark" "$T/xq.log" "-c xsettings -p /Net/ThemeName -n -t string -s Arc-Dark"
has "mwonekano --dark: IconThemeName=Papirus-Dark" "$T/xq.log" "-c xsettings -p /Net/IconThemeName -n -t string -s Papirus-Dark"
has "mwonekano --dark: xfwm4=Arc-Dark" "$T/xq.log" "-c xfwm4 -p /general/theme -n -t string -s Arc-Dark"
eq "mwonekano: --get baada ya --dark" "$(mwenv "$MW" --get)" "dark"
: > "$T/xq.log"; mwenv "$MW" --toggle >/dev/null 2>&1
has "mwonekano --toggle: inarudi Arc (light)" "$T/xq.log" "-s Arc"
eq "mwonekano: --get baada ya --toggle" "$(mwenv "$MW" --get)" "light"
rm -f "$T/mode"; eq "mwonekano: bila faili la mtumiaji, --get ni chaguo-msingi (light)" "$(mwenv "$MW" --get)" "light"
mkdir -p "$T/th2/Arc"; : > "$T/xq.log"
env UHURU_THEME_DEFAULTS="$DEFS" UHURU_THEMES_DIR="$T/th2" UHURU_ICONS_DIR="$T/ic" UHURU_MODE_FILE="$T/mode2" UHURU_XFCONF="$T/bin/xq" XQ_LOG="$T/xq.log" "$MW" --dark >"$T/o" 2>&1; eq "mwonekano --dark bila Arc-Dark: msimbo 3" "$?" 3
[ ! -s "$T/xq.log" ]; check "mwonekano: mandhari ikikosekana, hakuna kinachobadilishwa" $?
[ ! -e "$T/mode2" ]; check "mwonekano: mandhari ikikosekana, hali haihifadhiwi" $?
env UHURU_THEME_DEFAULTS="$DEFS" UHURU_THEMES_DIR="$T/th" UHURU_ICONS_DIR="$T/nonexist" UHURU_MODE_FILE="$T/mode3" UHURU_XFCONF="$T/bin/xq" XQ_LOG="$T/xq.log" "$MW" --light >/dev/null 2>&1; check "mwonekano: Papirus ikikosekana inaendelea kwa Adwaita" $?
env UHURU_THEME_DEFAULTS="$DEFS" UHURU_THEMES_DIR="$T/th" UHURU_ICONS_DIR="$T/ic" UHURU_MODE_FILE="$T/mode4" UHURU_XFCONF="$T/bin/nope" "$MW" --light >"$T/o" 2>&1; eq "mwonekano: xfconf-query ikikosekana: msimbo 4" "$?" 4
"$MW" --bogus >/dev/null 2>&1; eq "mwonekano: hoja mbaya: msimbo 2" "$?" 2
mwenv "$MW" --list | grep -q '^dark Arc-Dark Papirus-Dark$'; check "mwonekano --list" $?
mwenv "$MW" --check | grep -q 'theme Arc: ipo'; check "mwonekano --check inaona mandhari" $?
out=$(env LANG=fr_FR.UTF-8 UHURU_THEME_DEFAULTS="$DEFS" UHURU_THEMES_DIR="$T/th2" UHURU_ICONS_DIR="$T/ic" UHURU_MODE_FILE="$T/mode5" UHURU_XFCONF="$T/bin/xq" "$MW" --dark 2>&1); case "$out" in *"n'est pas installé"*) check "mwonekano: ujumbe wa Kifaransa" 0 ;; *) check "mwonekano: ujumbe wa Kifaransa ($out)" 1 ;; esac
out=$(env LANG=en_US.UTF-8 UHURU_THEME_DEFAULTS="$DEFS" UHURU_THEMES_DIR="$T/th2" UHURU_ICONS_DIR="$T/ic" UHURU_MODE_FILE="$T/mode5" UHURU_XFCONF="$T/bin/xq" "$MW" --dark 2>&1); case "$out" in *"is not installed"*) check "mwonekano: ujumbe wa Kiingereza" 0 ;; *) check "mwonekano: ujumbe wa Kiingereza ($out)" 1 ;; esac
out=$(env LANG=sw_TZ.UTF-8 UHURU_THEME_DEFAULTS="$DEFS" UHURU_THEMES_DIR="$T/th2" UHURU_ICONS_DIR="$T/ic" UHURU_MODE_FILE="$T/mode5" UHURU_XFCONF="$T/bin/xq" "$MW" --dark 2>&1); case "$out" in *"haipo kwenye mfumo"*) check "mwonekano: ujumbe wa Kiswahili" 0 ;; *) check "mwonekano: ujumbe wa Kiswahili ($out)" 1 ;; esac

echo "6) Wallpapers za Kitanzania"
for w in kilimanjaro zanzibar tanzanite kitenge tingatinga; do
    f="$WPDIR/$w.png"
    [ -f "$f" ]; check "wallpaper $w.png ipo" $?
    dim=$(python3 - "$f" <<'PY'
import struct, sys
d = open(sys.argv[1], "rb").read(32)
ok = d[:8] == b"\x89PNG\r\n\x1a\n" and d[12:16] == b"IHDR"
print("%dx%d" % struct.unpack(">II", d[16:24]) if ok else "si-PNG")
PY
)
    eq "wallpaper $w: ukubwa wa picha" "$dim" "1920x1080"
    sz=$(wc -c < "$f"); [ "$sz" -lt 900000 ]; check "wallpaper $w: faili chini ya KB 900 (ni $sz)" $?
    has "docs/LICENSE-WALLPAPERS.md inataja $w" "$REPO/docs/LICENSE-WALLPAPERS.md" "$w"
done
tot=$(cat "$WPDIR"/*.png | wc -c); [ "$tot" -lt 3000000 ]; check "jumla ya wallpapers chini ya MB 3 (ni $tot)" $?
[ -f "$REPO/tools/gen-wallpapers.py" ]; check "tools/gen-wallpapers.py ipo (chanzo cha wallpapers)" $?
has "leseni inasema kazi ni asili ya Letema Group Tech" "$REPO/docs/LICENSE-WALLPAPERS.md" "Letema Group Tech"

echo "7) Hook kwenye mazingira ya majaribio (apt bandia, mizizi ya muda)"
mk_root() {   # mk_root DIR : mizizi yenye faili za v19.1 na faili bandia za awamu zilizopita
    local R=$1; mkdir -p "$R"
    cp -r "$B"/. "$R"/
    mkdir -p "$R/etc/lightdm" "$R/usr/share/backgrounds/uhuru-os" "$R/etc/skel/Desktop" "$R/usr/local/bin"
    cp "$T/g.conf" "$R/etc/lightdm/lightdm-gtk-greeter.conf"; sed -i 's/^font-name=.*/font-name=Sans 11/; /^theme-name=/d; /^icon-theme-name=/d' "$R/etc/lightdm/lightdm-gtk-greeter.conf"
    for i in 1 2 3 4; do : > "$R/usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper-$i.png"; done
    printf '#!/bin/sh\nls /usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper-*.png\n' > "$R/usr/local/bin/uhuru-wallpaper"
    printf '[Desktop Entry]\nType=Application\nName=Duka la LGT\nExec=/usr/local/bin/uhuru-store\n' > "$R/usr/share/applications/uhuru-store.desktop"
    cp "$R/usr/share/applications/uhuru-store.desktop" "$R/etc/skel/Desktop/uhuru-store.desktop"
}
mkdir -p "$T/stub"
for c in apt-get apt-cache localedef; do printf '#!/bin/sh\nexit 0\n' > "$T/stub/$c"; done
printf '#!/bin/sh\nexit 1\n' > "$T/stub/dpkg"; chmod +x "$T/stub"/*
run_hook() { env PATH="$T/stub:$PATH" UHURU_HOOK_ROOT="$1" sh "$HOOK" > "$1.log" 2>&1; }

# A: mandhari hazipo -> mwonekano wa awali unabaki
RA="$T/rootA"; mk_root "$RA"; run_hook "$RA"; check "hook A (bila mandhari): exit 0" $?
[ ! -e "$RA/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" ]; check "hook A: xsettings haiandikwi mandhari ikikosekana" $?
! grep -q '^theme-name=' "$RA/etc/lightdm/lightdm-gtk-greeter.conf"; check "hook A: greeter haiguswi mandhari ikikosekana" $?
has "hook A: onyo la mandhari linaonekana kwenye logi" "$RA.log" "uhuru-theme: ONYO: mandhari"
[ -f "$RA/usr/share/uhuru/theme-build.txt" ]; check "hook A: theme-build.txt imeandikwa" $?
has "hook A: theme_applied=no" "$RA/usr/share/uhuru/theme-build.txt" "theme_applied=no"

# B: mandhari zipo -> zinatumika
RB="$T/rootB"; mk_root "$RB"
mkdir -p "$RB/usr/share/themes/Arc/xfwm4" "$RB/usr/share/themes/Arc-Dark/xfwm4" "$RB/usr/share/icons/Papirus" "$RB/usr/share/icons/Papirus-Dark" "$RB/usr/share/icons/Adwaita" \
         "$RB/usr/share/icons/ePapirus" "$RB/usr/share/icons/Papirus-Light" "$RB/usr/share/themes/Arc-Solid"
run_hook "$RB"; check "hook B (mandhari zipo): exit 0" $?
XS="$RB/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
has "hook B: xsettings ThemeName=Arc" "$XS" 'name="ThemeName" type="string" value="Arc"'
has "hook B: xsettings IconThemeName=Papirus" "$XS" 'name="IconThemeName" type="string" value="Papirus"'
has "hook B: xsettings FontName" "$XS" 'value="Noto Sans 10"'
has "hook B: xfwm4 theme=Arc" "$RB/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" 'value="Arc"'
has "hook B: greeter theme-name=Arc-Dark" "$RB/etc/lightdm/lightdm-gtk-greeter.conf" "theme-name=Arc-Dark"
has "hook B: greeter icon-theme-name=Papirus-Dark" "$RB/etc/lightdm/lightdm-gtk-greeter.conf" "icon-theme-name=Papirus-Dark"
has "hook B: greeter background haijaguswa" "$RB/etc/lightdm/lightdm-gtk-greeter.conf" "background=/usr/share/backgrounds/uhuru-os/login-current.png"
[ ! -d "$RB/usr/share/icons/ePapirus" ] && [ ! -d "$RB/usr/share/icons/Papirus-Light" ] && [ ! -d "$RB/usr/share/themes/Arc-Solid" ]; check "hook B: tofauti zisizotumika zimeondolewa (ukubwa)" $?
[ -d "$RB/usr/share/icons/Papirus" ] && [ -d "$RB/usr/share/themes/Arc-Dark" ]; check "hook B: Papirus na Arc-Dark zimebaki" $?
for i in 5 6 7 8 9; do [ -L "$RB/usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper-$i.png" ] && [ -f "$RB/usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper-$i.png" ]; check "hook B: kiungo uhuru-os-wallpaper-$i.png kinafanya kazi" $?; done
[ ! -L "$RB/usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper-1.png" ]; check "hook B: wallpapers za zamani (1-4) hazijaguswa" $?
has "hook B: Name[fr] ya Duka (menyu)" "$RB/usr/share/applications/uhuru-store.desktop" "Name[fr]=Boutique LGT"
has "hook B: Name[fr] ya Duka (skel/Desktop)" "$RB/etc/skel/Desktop/uhuru-store.desktop" "Name[fr]=Boutique LGT"
has "hook B: wallpapers=5/5" "$RB/usr/share/uhuru/theme-build.txt" "wallpapers=5/5"
has "hook B: theme_applied=yes" "$RB/usr/share/uhuru/theme-build.txt" "theme_applied=yes"
has "hook B: logi inaonyesha INFO ya uhuru-wallpaper" "$RB.log" "uhuru-theme: INFO uhuru-wallpaper inatumia"
n1=$(tree_sum "$RB"); run_hook "$RB"; eq "hook B: idempotent (mara ya pili hakuna mabadiliko)" "$(tree_sum "$RB")" "$n1"

# C: skel ina xsettings tayari -> inasasishwa (isizuie mandhari mpya)
RC="$T/rootC"; mk_root "$RC"; mkdir -p "$RC/usr/share/themes/Arc/xfwm4" "$RC/usr/share/themes/Arc-Dark/xfwm4" "$RC/usr/share/icons/Papirus" "$RC/usr/share/icons/Papirus-Dark" "$RC/usr/share/icons/Adwaita"
mkdir -p "$RC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"; cp "$T/xs2.xml" "$RC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
sed -i 's/Arc-Dark/Adwaita/' "$RC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
run_hook "$RC"; has "hook C: skel xsettings inasasishwa" "$RC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" 'name="ThemeName" type="string" value="Arc"'
has "hook C: skel inahifadhi DPI ya awali" "$RC/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" 'name="DPI"'

# D: Papirus haipo, Arc ipo -> ikoni zinarudi Adwaita
RD="$T/rootD"; mk_root "$RD"; mkdir -p "$RD/usr/share/themes/Arc/xfwm4" "$RD/usr/share/themes/Arc-Dark/xfwm4" "$RD/usr/share/icons/Adwaita"
run_hook "$RD"
has "hook D: ikoni zinarudi Adwaita (desktop)" "$RD/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" 'name="IconThemeName" type="string" value="Adwaita"'
has "hook D: ikoni zinarudi Adwaita (greeter)" "$RD/etc/lightdm/lightdm-gtk-greeter.conf" "icon-theme-name=Adwaita"

# E: UHURU_DEFAULT_MODE=dark kwenye theme.defaults
RE="$T/rootE"; mk_root "$RE"; mkdir -p "$RE/usr/share/themes/Arc/xfwm4" "$RE/usr/share/themes/Arc-Dark/xfwm4" "$RE/usr/share/icons/Papirus" "$RE/usr/share/icons/Papirus-Dark"
sed -i 's/^UHURU_DEFAULT_MODE=light/UHURU_DEFAULT_MODE=dark/' "$RE/etc/uhuru/theme.defaults"; run_hook "$RE"
has "hook E: mode=dark inaweka Arc-Dark kwenye desktop" "$RE/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" 'value="Arc-Dark"'

# F: hook haipaswi kuvunja build hata bila faili la defaults wala zana
RF="$T/rootF"; mkdir -p "$RF"; run_hook "$RF"; check "hook F (mizizi tupu kabisa): exit 0" $?

echo "8) Nyaraka na workflow"
for f in docs/THEME.md docs/LICENSE-WALLPAPERS.md .github/workflows/theme-check.yml scripts/v191-postcheck.sh; do [ -f "$REPO/$f" ]; check "faili lipo: $f" $?; done
bash -n "$REPO/scripts/v191-postcheck.sh"; check "bash -n v191-postcheck.sh" $?

echo
echo "=== JUMLA: $ok OK, $fail FAIL ==="
[ "$fail" = 0 ]
