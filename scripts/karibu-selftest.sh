#!/bin/bash
# Uhuru OS v19.2: majaribio ya Karibu Uhuru na pakiti za programu bila ISO wala skrini (zenity, apt na xfconf ni bandia).
# Matumizi: bash scripts/karibu-selftest.sh      (kutoka mzizi wa repo). Hiari: UHURU_ISO_PACKAGES=<filesystem.packages> kukagua pakiti hazirudii vilivyomo kwenye ISO.
set -u
REPO=${REPO:-$(cd "$(dirname "$0")/.." && pwd)}
B="$REPO/config/includes.chroot"
KARIBU="$B/usr/local/bin/uhuru-karibu"
VERD="$REPO/scripts/e2e-verdict.sh"
PAKITI="$B/usr/local/bin/uhuru-pakiti"
PACKS="$B/usr/share/uhuru/packs"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ok=0; fail=0
check() { if [ "$2" = 0 ]; then ok=$((ok+1)); else fail=$((fail+1)); echo "  FAIL: $1"; fi; }
has() { grep -qF -- "$3" "$2" 2>/dev/null; check "$1" $?; }
hasnt() { ! grep -qF -- "$3" "$2" 2>/dev/null; check "$1" $?; }
eq() { [ "$2" = "$3" ]; check "$1 (tarajio '$3', imepatikana '$2')" $?; }

echo "1) Syntax, ruhusa na faili"
bash -n "$KARIBU"; check "bash -n uhuru-karibu" $?
bash -n "$PAKITI"; check "bash -n uhuru-pakiti" $?
[ -x "$KARIBU" ] && [ -x "$PAKITI" ]; check "uhuru-karibu na uhuru-pakiti vina ruhusa ya kuendeshwa" $?
for f in "$B/etc/xdg/autostart/uhuru-karibu.desktop" "$B/usr/share/applications/uhuru-karibu.desktop"; do
    n=$(basename "$(dirname "$f")")/$(basename "$f")
    has "$n: Exec ya uhuru-karibu" "$f" "/usr/local/bin/uhuru-karibu"
    has "$n: ina Comment= (kwa Comment[xx])" "$f" "Comment="
    has "$n: Name[en] na Name[fr]" "$f" "Name[fr]="
    [ -n "$(sed -n 's/^Icon=//p' "$f")" ]; check "$n: ina Icon" $?
    if command -v desktop-file-validate >/dev/null 2>&1; then desktop-file-validate "$f" >"$T/dfv" 2>&1; check "desktop-file-validate: $n" $?; sed 's/^/    dfv: /' "$T/dfv" | head -n 6; fi
done
has "autostart: inachelewa ili paneli ianze kwanza" "$B/etc/xdg/autostart/uhuru-karibu.desktop" "X-GNOME-Autostart-Delay="
has "theme-tool ina tafsiri za uhuru-karibu" "$B/usr/local/lib/uhuru/uhuru-theme-tool" '"uhuru-karibu"'
# kila ufunguo wa t() upo kwa lugha zote tatu
keys=$(grep -o '\$(t [a-z_]*)' "$KARIBU" | sed 's/.*(t //; s/)//' | sort -u)
miss=""; for k in $keys; do for l in sw en fr; do grep -q "^ *$k:$l)\|[ ;]$k:$l)" "$KARIBU" || miss="$miss $k:$l"; done; done
[ -z "$miss" ]; check "kila ujumbe wa Karibu upo kwa sw, en na fr (unakosekana:$miss)" $?
grep -q "gh""p_\|github""_pat_\|s""k-[A-Za-z0-9]\{20,\}" "$KARIBU" "$PAKITI" "$PACKS"/*.pack; [ $? -ne 0 ]; check "hakuna siri/token kwenye faili za v19.2" $?

XS="$B/etc/X11/Xsession.d/45uhuru-atspi-clean"
[ -f "$XS" ]; check "Xsession.d/45uhuru-atspi-clean ipo" $?
sh -n "$XS"; check "Xsession.d: syntax ya sh" $?
has "Xsession.d: inaondoa AT_SPI_BUS kwa xprop" "$XS" "xprop -root -remove AT_SPI_BUS"
! grep -qE '^[[:space:]]*(exit|return|set -e)' "$XS"; check "Xsession.d: haina exit/return/set -e (inasomwa ndani ya Xsession: ingeweza kuzuia kuingia)" $?
grep -q 'xprop' "$XS" && grep -q '|| true' "$XS"; check "Xsession.d: makosa ya xprop yanapuuzwa" $?

echo "2) uhuru-pakiti: faili za pakiti"
export UHURU_PAKITI_DIR="$PACKS"
out=$("$PAKITI" --check); case "$out" in PAKITI-OK,packs=3,pkgs=*) check "pakiti --check: $out" 0 ;; *) check "pakiti --check: $out" 1 ;; esac
for id in ofisi shule wasanidi; do [ -f "$PACKS/$id.pack" ]; check "pakiti $id.pack ipo" $?; done
for f in "$PACKS"/*.pack; do for l in sw en fr; do d=$(sed -n "s/^maelezo_$l=//p" "$f"); [ "${#d}" -le 58 ]; check "$(basename "$f") maelezo_$l ni mafupi (${#d} <= 58; hayakatiki kwenye dirisha)" $?; done; done
"$PAKITI" list | awk -F'\t' 'NF==4{n++} END{exit n==3?0:1}'; check "pakiti list: mistari 3 yenye safu 4" $?
LANG=fr_FR.UTF-8 "$PAKITI" list | grep -q '^ofisi.Bureautique'; check "pakiti list: jina la Kifaransa" $?
LANG=en_US.UTF-8 "$PAKITI" list | grep -q '^shule.School'; check "pakiti list: jina la Kiingereza" $?
printf 'id=zzz\njina_sw=Z\nvifurushi=bad;rm\n' > "$T/zzz.pack"; mkdir -p "$T/bad"; cp "$T/zzz.pack" "$T/bad/"
UHURU_PAKITI_DIR="$T/bad" "$PAKITI" --check >"$T/o" 2>&1; [ $? -ne 0 ]; check "pakiti --check inakataa pakiti mbovu (jina la kifurushi batili, funguo zinakosekana)" $?
if [ -n "${UHURU_ISO_PACKAGES:-}" ] && [ -f "${UHURU_ISO_PACKAGES}" ]; then
    dup=""; for id in ofisi shule wasanidi; do for p in $(sed -n 's/^vifurushi=//p' "$PACKS/$id.pack"); do grep -q "^$p	" "$UHURU_ISO_PACKAGES" && dup="$dup $p"; done; done
    [ -z "$dup" ]; check "pakiti hazirudii vifurushi vilivyomo kwenye ISO (vinavyorudiwa:$dup)" $?
fi

echo "3) uhuru-pakiti install (apt bandia)"
mkdir -p "$T/bin" "$T/home"
cat > "$T/bin/aptget" <<'S'
#!/bin/bash
echo "aptget $*" >> "$CALLS"
[ "${APTFAIL:-0}" = 1 ] && [ "$1" = install ] && exit 100
exit 0
S
cat > "$T/bin/aptcache" <<'S'
#!/bin/bash
# aptcache policy PKG: "xournalpp" haipo kwenye hazina ya majaribio
p=$2; if [ "$p" = xournalpp ]; then printf '%s:\n  Installed: (none)\n  Candidate: (none)\n' "$p"; else printf '%s:\n  Installed: (none)\n  Candidate: 1.0-1\n' "$p"; fi
S
cat > "$T/bin/dpkgq" <<'S'
#!/bin/bash
# dpkgq -W -f=... PKG: 'thunderbird' imesakinishwa tayari
for a; do p=$a; done; [ "$p" = thunderbird ] && printf 'ii '
exit 0
S
cat > "$T/bin/pkexec" <<'S'
#!/bin/bash
echo "pkexec $*" >> "$CALLS"; exit 0
S
cat > "$T/bin/id" <<'S'
#!/bin/bash
[ "$1" = -u ] && { echo "${FAKEUID:-0}"; exit 0; }
exec /usr/bin/id "$@"
S
chmod +x "$T/bin"/*
export CALLS="$T/calls.log"
penv() { env PATH="$T/bin:$PATH" UHURU_APT_GET="$T/bin/aptget" UHURU_APT_CACHE="$T/bin/aptcache" UHURU_DPKG_QUERY="$T/bin/dpkgq" UHURU_PKEXEC="$T/bin/pkexec" "$@"; }
: > "$CALLS"; out=$(penv UHURU_PAKITI_NET=true "$PAKITI" install ofisi 2>&1); rc=$?
eq "install ofisi: msimbo 0" "$rc" 0
has "install: apt-get update ilitumika" "$CALLS" "aptget update"
has "install: vifurushi vilivyopo vinasakinishwa" "$CALLS" "install -y --no-install-recommends -- "
grep -q "aptget install.*pdfarranger" "$CALLS"; check "install: pdfarranger imesakinishwa" $?
grep -q "aptget install.*xournalpp" "$CALLS"; [ $? -ne 0 ]; check "install: xournalpp (haipo kwenye hazina) imerukwa, haizuii vingine" $?
grep -q "aptget install.*thunderbird" "$CALLS"; [ $? -ne 0 ]; check "install: thunderbird (tayari imesakinishwa) hairudiwi" $?
case "$out" in *"missing=xournalpp"*) check "install: ripoti inataja kilichokosekana" 0 ;; *) check "install: ripoti inataja kilichokosekana ($out)" 1 ;; esac
: > "$CALLS"; out=$(penv UHURU_PAKITI_NET=false "$PAKITI" install shule 2>&1); eq "install bila mtandao: msimbo 3" "$?" 3
hasnt "install bila mtandao: apt-get haiitwi" "$CALLS" "aptget"
penv UHURU_PAKITI_NET=true "$PAKITI" install nope >/dev/null 2>&1; eq "install pakiti isiyojulikana: msimbo 2" "$?" 2
penv UHURU_PAKITI_NET=true "$PAKITI" install 'ofisi;rm' >/dev/null 2>&1; eq "install jina la hatari: msimbo 2" "$?" 2
penv UHURU_PAKITI_NET=true "$PAKITI" install >/dev/null 2>&1; eq "install bila hoja: msimbo 2" "$?" 2
: > "$CALLS"; penv UHURU_PAKITI_NET=true APTFAIL=1 "$PAKITI" install shule >/dev/null 2>&1; eq "install: apt ikishindwa msimbo 5" "$?" 5
: > "$CALLS"; penv FAKEUID=1000 UHURU_PAKITI_NET=true "$PAKITI" install shule >/dev/null 2>&1
has "install bila root: inaomba ruhusa kupitia pkexec" "$CALLS" "pkexec "
has "install bila root: pkexec inaendesha uhuru-pakiti install shule" "$CALLS" "uhuru-pakiti install shule"
out=$(penv FAKEUID=1000 UHURU_PKEXEC=hakuna-pkexec UHURU_PAKITI_NET=true "$PAKITI" install shule 2>&1); eq "install bila pkexec: msimbo 6" "$?" 6

echo "4) uhuru-karibu: stubs"
mkdir -p "$T/kb" "$T/wp"; for w in kilimanjaro zanzibar tanzanite kitenge tingatinga; do : > "$T/wp/$w.png"; done
cat > "$T/bin/zenity" <<'S'
#!/bin/bash
echo "$*" >> "$ZLOG"
echo "NOATB=${NO_AT_BRIDGE:-}" >> "${ENVLOG:-/dev/null}"
[ -n "${UHURU_KARIBU_STEP:-}" ] && { cat "$UHURU_KARIBU_STEP" 2>/dev/null; echo; } >> "${STEPLOG:-/dev/null}"
case "$*" in *--progress*) cat >/dev/null; exit 0 ;; esac
line=$(head -n 1 "$ZANS" 2>/dev/null); [ -n "$line" ] || exit 1
sed -i 1d "$ZANS"; rc=${line%%|*}; out=${line#*|}
[ -n "$out" ] && printf '%s\n' "$out"
exit "$rc"
S
chmod +x "$T/bin/zenity"
for b in uhuru-lugha uhuru-mwonekano uhuru-protect uhuru-store uhuru-share uhuru-wallpaper; do
    printf '#!/bin/bash\necho "%s $*" >> "$CALLS"\n[ "$1" = --get ] && { echo "${LUGHA_GET:-sw}"; exit 0; }\n[ "%s" = uhuru-protect ] && [ "$1" = --check ] && { echo "${PROTECT_LINE-PROTECT-OK n=10 ok=7 warn=1 info=2 bad=0 fw=ok,aa=ok,sysctl=ok}"; exit 0; }\nexit 0\n' "$b" "$b" > "$T/kb/$b"
done
cat > "$T/kb/uhuru-pakiti" <<'S'
#!/bin/bash
echo "uhuru-pakiti $*" >> "$CALLS"
case "$1" in
    list) printf 'ofisi\tOfisi\tBarua pepe na PDF\t0/6\nshule\tShule\tMichezo ya kujifunza\t0/5\nwasanidi\tWasanidi\tGeany na Go\t0/3\n' ;;
    --check) echo "PAKITI-OK,packs=3,pkgs=14" ;;
    install) exit "${PAKITI_RC:-0}" ;;
esac
exit 0
S
chmod +x "$T/kb"/*
for c in pkill pgrep setsid nm-connection-editor xq; do printf '#!/bin/bash\necho "%s $*" >> "$CALLS"\n[ "%s" = xq ] && [ "$2" = xfce4-desktop ] && [ "$3" = -l ] && echo /backdrop/screen0/monitor0/workspace0/last-image\n[ "%s" = pgrep ] && exit 1\nexit 0\n' "$c" "$c" "$c" > "$T/bin/$c"; chmod +x "$T/bin/$c"; done
export ZLOG="$T/zlog" ZANS="$T/zans" STEPLOG="$T/steplog" ENVLOG="$T/envlog"
kenv() { env PATH="$T/bin:$PATH" HOME="$T/home" DISPLAY=:0 UHURU_ZENITY="$T/bin/zenity" UHURU_KARIBU_BIN="$T/kb" UHURU_XFCONF="$T/bin/xq" \
    UHURU_KARIBU_DONE="$T/home/.config/uhuru/karibu.done" UHURU_KARIBU_CI="$T/ci1 $T/ci2" UHURU_KARIBU_LIVE=no UHURU_WALLPAPER_DIR="$T/wp" "$@"; }
reset() { rm -rf "$T/home"; mkdir -p "$T/home"; : > "$CALLS"; : > "$ZLOG"; printf '%s\n' "$@" > "$ZANS"; }
DONEF="$T/home/.config/uhuru/karibu.done"

# A) mtiririko kamili: Kiingereza, Dark, wallpaper ya Zanzibar, mtandao baadaye, pakiti 'shule', usalama endelea, ziara 'done'
reset "0|" "0|English" "0|" "0|dark" "0|zanzibar" "1|" "0|shule" "0|" "1|" "0|done" "0|"
kenv "$KARIBU"; eq "A: mtiririko kamili unamaliza kwa msimbo 0" "$?" 0
has "A: lugha ya akaunti imewekwa kuwa en" "$CALLS" "uhuru-lugha --set en"
has "A: mwonekano umewekwa Dark" "$CALLS" "uhuru-mwonekano --dark"
has "A: wallpaper ya Zanzibar imewekwa kwenye xfconf" "$CALLS" "last-image -s $T/wp/zanzibar.png"
has "A: mtindo wa picha (zoomed) umewekwa" "$CALLS" "image-style -s 5"
[ -e "$T/home/.config/uhuru/no-wallpaper-rotate" ]; check "A: mzunguko wa wallpapers umezimwa (faili la alama)" $?
has "A: mzunguko unaoendelea umesimamishwa (pkill)" "$CALLS" "pkill -u"
has "A: pakiti 'shule' imesakinishwa" "$CALLS" "uhuru-pakiti install shule"
hasnt "A: pakiti zisizochaguliwa hazisakinishwi" "$CALLS" "install ofisi"
has "A: ripoti ya usalama imesomwa" "$CALLS" "uhuru-protect --check"
[ -e "$DONEF" ]; check "A: alama ya kukamilika imeandikwa" $?
[ ! -s "$ZANS" ]; check "A: madirisha yote 11 yalitokea kwa mpangilio uliotarajiwa (majibu yote yametumika)" $?
has "A: dirisha la kwanza ni Kiswahili" "$ZLOG" "--title=Karibu Uhuru"
has "A: baada ya kuchagua English madirisha yanakuwa Kiingereza" "$ZLOG" "--title=Welcome to Uhuru"
has "A: ujumbe wa pakiti kwa Kiingereza" "$ZLOG" "Add apps by pack"
has "A: takwimu za usalama zinaonyeshwa (muundo halisi wa nafasi: 10 checks, 7 good)" "$ZLOG" "10 checks, 7 good, 1 warnings, 0 risks"
has "A: safu ya 'Installed' iko kabla ya maelezo (haikatiki kulia)" "$ZLOG" "--column=Pack --column=Installed --column=Description"
has "A: dirisha la pakiti lina upana wa kutosha" "$ZLOG" "--width=720"
has "A: mstari wa pakiti una idadi kabla ya maelezo" "$ZLOG" "FALSE ofisi Ofisi 0/6 Barua pepe na PDF"
grep -q 'NOATB=1' "$ENVLOG"; check "A: NO_AT_BRIDGE=1 inafikia zenity (hakuna onyo la accessibility bus)" $?
! grep -q 'NOATB=$' "$ENVLOG"; check "A: kila dirisha lilipata NO_AT_BRIDGE=1" $?

# A2) ripoti ya usalama: muundo wa koma bado unasomwa; mstari mbovu au tupu hauonyeshi mstari wa Hali tupu
for pl in "PROTECT-OK,n=4,ok=3,warn=1,info=0,bad=0" "PROTECT-FAIL n=4 ok=2 warn=1 info=0 bad=1"; do
    reset "0|" "1|" "1|" "1|" "1|" "1|" "1|" "1|"
    kenv PROTECT_LINE="$pl" "$KARIBU" --demo >/dev/null 2>&1
    case "$pl" in *,*) want="vipengele 4, vizuri 3, tahadhari 1, hatari 0" ;; *) want="vipengele 4, vizuri 2, tahadhari 1, hatari 1" ;; esac
    has "A2: '$pl' inasomwa" "$ZLOG" "$want"
done
for pl in "PROTECT-OK" "" "PROTECT-OK n= ok= warn= bad="; do
    reset "0|" "1|" "1|" "1|" "1|" "1|" "1|" "1|"
    kenv PROTECT_LINE="$pl" "$KARIBU" --demo >/dev/null 2>&1
    hasnt "A2: mstari mbovu '$pl' hauonyeshi 'Hali:' tupu" "$ZLOG" "Hali: vipengele ,"
    hasnt "A2: mstari mbovu '$pl' hauonyeshi 'Hali' kabisa" "$ZLOG" "Hali: vipengele"
done

# B) Baadaye kwenye dirisha la kwanza: hakuna kinachobadilika, haihifadhiwi
reset "1|"
kenv "$KARIBU"; eq "B: 'Baadaye' inatoka kwa msimbo 0" "$?" 0
[ ! -e "$DONEF" ]; check "B: 'Baadaye' haihifadhi kukamilika (itaonekana tena)" $?
grep -v -- "--get" "$CALLS" | grep -q .; [ $? -ne 0 ]; check "B: 'Baadaye' haibadilishi chochote (kusoma lugha tu kunaruhusiwa)" $?

# C) walinzi wa autostart
reset "0|"; kenv UHURU_KARIBU_LIVEUSER="$(/usr/bin/id -un)" "$KARIBU"; [ ! -s "$ZLOG" ]; check "C: akaunti ya live (mtumiaji) haionyeshi Karibu" $?
reset "0|"; : > "$T/ci1"; kenv "$KARIBU"; [ ! -s "$ZLOG" ]; check "C: kwenye CI (alama ya /run/uhuru-ci) haionyeshi dirisha lolote" $?; rm -f "$T/ci1"
reset "0|"; : > "$T/ci2"; kenv "$KARIBU"; [ ! -s "$ZLOG" ]; check "C: kwenye CI (alama ya uhuru-setup.step) haionyeshi dirisha lolote" $?; rm -f "$T/ci2"
reset "0|"; mkdir -p "$T/home/.config/uhuru"; : > "$DONEF"; kenv "$KARIBU"; [ ! -s "$ZLOG" ]; check "C: ikishakamilika haionekani tena yenyewe" $?
reset "0|"; env PATH="$T/bin:$PATH" HOME="$T/home" UHURU_ZENITY="$T/bin/zenity-haipo" UHURU_KARIBU_BIN="$T/kb" DISPLAY=:0 "$KARIBU"; eq "C: zenity ikikosekana inatoka kimya kwa msimbo 0" "$?" 0
reset "0|"; env -u DISPLAY -u WAYLAND_DISPLAY PATH="$T/bin:$PATH" HOME="$T/home" UHURU_ZENITY="$T/bin/zenity" UHURU_KARIBU_BIN="$T/kb" UHURU_KARIBU_CI="" "$KARIBU"; [ ! -s "$ZLOG" ]; check "C: bila skrini (DISPLAY) haionyeshi chochote" $?
kenv "$KARIBU" --bogus >/dev/null 2>&1; eq "C: hoja isiyojulikana: msimbo 2" "$?" 2

# D) --again inaonekana hata ikishakamilika na kwa akaunti ya live; chaguo 'zunguka' linarudisha mzunguko
reset "0|" "1|" "1|" "1|" "1|" "1|" "1|" "1|"
mkdir -p "$T/home/.config/uhuru"; : > "$DONEF"
kenv UHURU_KARIBU_LIVEUSER="$(/usr/bin/id -un)" "$KARIBU" --again; [ -s "$ZLOG" ]; check "D: --again inaonekana hata baada ya kukamilika" $?
reset "0|" "1|" "1|" "0|rotate" "1|" "1|" "1|" "0|done" "0|"
mkdir -p "$T/home/.config/uhuru"; : > "$T/home/.config/uhuru/no-wallpaper-rotate"
kenv "$KARIBU" --again
[ ! -e "$T/home/.config/uhuru/no-wallpaper-rotate" ]; check "D: 'zunguka' linaondoa alama ya kuzima mzunguko" $?
has "D: mzunguko unaanzishwa upya" "$CALLS" "setsid -f $T/kb/uhuru-wallpaper"

# E) hali ya live: inauliza kwanza; ukikataa, hakuna kinachosakinishwa
reset "0|" "1|" "1|" "1|" "1|" "0|ofisi wasanidi" "1|" "1|" "0|done" "0|"
kenv UHURU_KARIBU_LIVE=yes "$KARIBU"
has "E: onyo la live linaonyeshwa" "$ZLOG" "live"
hasnt "E: ukikataa onyo la live, pakiti hazisakinishwi" "$CALLS" "uhuru-pakiti install"
reset "0|" "1|" "1|" "1|" "1|" "0|ofisi wasanidi" "0|" "0|" "1|" "0|done" "0|"
kenv UHURU_KARIBU_LIVE=yes "$KARIBU"
[ ! -s "$ZANS" ]; check "E: mpangilio wa madirisha ni sahihi" $?
has "E: ukikubali, pakiti zote mbili zinasakinishwa" "$CALLS" "uhuru-pakiti install ofisi wasanidi"

# F) matokeo ya kusakinisha: hakuna mtandao, kushindwa, kughairi
for rc in 3 5 126; do
    reset "0|" "1|" "1|" "1|" "1|" "0|shule" "0|" "1|" "0|done" "0|"
    kenv PAKITI_RC=$rc "$KARIBU"; [ -e "$DONEF" ] && [ ! -s "$ZANS" ]; check "F: pakiti ikirudisha $rc, Karibu bado inamaliza kwa mpangilio sahihi" $?
done
reset "0|" "1|" "1|" "1|" "1|" "0|shule" "0|" "1|" "0|done" "0|"; kenv PAKITI_RC=3 "$KARIBU"; has "F: msimbo 3 unaonyesha 'Hakuna mtandao'" "$ZLOG" "Hakuna mtandao"
reset "0|" "1|" "1|" "1|" "1|" "0|shule" "0|" "1|" "0|done" "0|"; kenv PAKITI_RC=126 "$KARIBU"; has "F: msimbo 126 unaonyesha 'Umeghairi'" "$ZLOG" "Umeghairi"

# G) ziara: Duka na Share vinafunguka
reset "0|" "1|" "1|" "1|" "1|" "1|" "1|" "0|store" "0|share" "0|done" "0|"
kenv "$KARIBU"; [ ! -s "$ZANS" ]; check "G: mpangilio wa madirisha ni sahihi" $?; sleep 0.3
has "G: Duka la LGT linafunguka" "$CALLS" "uhuru-store "
has "G: Uhuru Share inafunguka kwa --gui" "$CALLS" "uhuru-share --gui"

# H) --check
out=$(kenv UHURU_ZENITY="$T/bin/zenity" "$KARIBU" --check); rc=$?
eq "H: --check inapita kwa zana zote" "$rc" 0
case "$out" in KARIBU-OK,zenity=yes,wallpapers=5,pakiti=PAKITI-OK*) check "H: --check: $out" 0 ;; *) check "H: --check: $out" 1 ;; esac
rm -f "$T/wp/tingatinga.png"; kenv "$KARIBU" --check >/dev/null 2>&1; eq "H: wallpaper ikikosekana --check inashindwa" "$?" 1


echo "5) uhuru-karibu --demo: onyesho bila madhara (kwa picha za CI)"
STEPFILE="$T/stepfile"
demo_reset() { reset "$@"; : > "$STEPLOG"; : > "$STEPFILE"; }
dside() {  # hakuna kitu kimebadilishwa
    hasnt "$1: lugha haibadilishwi" "$CALLS" "uhuru-lugha --set"
    hasnt "$1: mwonekano haubadilishwi" "$CALLS" "uhuru-mwonekano --"
    hasnt "$1: wallpaper haibadilishwi (xfconf)" "$CALLS" "last-image"
    hasnt "$1: mzunguko wa wallpapers haujaguswa" "$CALLS" "pkill"
    hasnt "$1: hakuna kinachosakinishwa" "$CALLS" "uhuru-pakiti install"
    ! grep -qx "uhuru-protect " "$CALLS"; check "$1: Kituo cha Ulinzi hakifunguliwi (ripoti ya --check tu)" $?
    hasnt "$1: Duka halifunguliwi" "$CALLS" "uhuru-store"
    hasnt "$1: Share haifunguliwi" "$CALLS" "uhuru-share"
    hasnt "$1: mtandao haufunguliwi" "$CALLS" "nm-connection-editor"
    [ ! -e "$DONEF" ] && [ ! -e "$T/home/.config/uhuru/no-wallpaper-rotate" ]; check "$1: hakuna faili la kukamilika wala la mzunguko" $?
}
# D1) madirisha yote yakiisha muda (rc 5): hatua 8 kwa mpangilio, kila dirisha lina --timeout
demo_reset "5|" "5|" "5|" "5|" "5|" "5|" "5|" "5|"
kenv UHURU_KARIBU_STEP="$STEPFILE" UHURU_KARIBU_DEMO_SECS=15 "$KARIBU" --demo; eq "demo: msimbo 0" "$?" 0
exp=$'karibu-1-karibu\nkaribu-2-lugha\nkaribu-3-mwonekano\nkaribu-4-wallpaper\nkaribu-5-pakiti\nkaribu-6-usalama\nkaribu-7-ziara\nkaribu-8-mwisho'
got=$(grep . "$STEPLOG"); eq "demo: hatua 8 zinaonekana kwa mpangilio (step=)" "$got" "$exp"
eq "demo: kila dirisha lina --timeout=15 (linajifunga lenyewe)" "$(grep -c -- '--timeout=15' "$ZLOG")" 8
[ ! -s "$ZANS" ]; check "demo: madirisha yote 8 yametokea" $?
eq "demo: step inarudi 'none' mwishoni" "$(cat "$STEPFILE")" none
dside "demo (muda umeisha)"
# D2) hata mtumiaji akibonyeza kila kitu, hakuna kinachobadilika
demo_reset "0|" "0|English" "0|dark" "0|zanzibar" "0|shule wasanidi" "0|" "0|store" "0|share" "0|done" "0|"
kenv UHURU_KARIBU_STEP="$STEPFILE" "$KARIBU" --demo; eq "demo (majibu yote ndiyo): msimbo 0" "$?" 0
dside "demo (majibu yote ndiyo)"
# D3) demo haizuiliwi na walinzi (live, CI, imekamilika): inaonyeshwa
demo_reset "5|" "5|" "5|" "5|" "5|" "5|" "5|" "5|"; mkdir -p "$T/home/.config/uhuru"; : > "$DONEF"; : > "$T/ci1"
kenv UHURU_KARIBU_LIVEUSER="$(/usr/bin/id -un)" UHURU_KARIBU_STEP="$STEPFILE" "$KARIBU" --demo
eq "demo kwenye CI/akaunti ya live/imekamilika: madirisha 8 yanaonekana" "$(grep -c -- "--timeout=" "$ZLOG")" 8; rm -f "$T/ci1"
# D4) hali ya kawaida HAIANDIKI faili la hatua (wizard ya CI haiguswi)
reset "1|"; : > "$STEPFILE"; kenv UHURU_KARIBU_STEP="$STEPFILE" "$KARIBU"; [ ! -s "$STEPFILE" ]; check "hali ya kawaida haiandiki faili la hatua" $?
reset "0|" "1|" "1|" "1|" "1|" "1|" "1|" "1|"; : > "$STEPFILE"; kenv UHURU_KARIBU_STEP="$STEPFILE" "$KARIBU" --again; [ ! -s "$STEPFILE" ]; check "--again haiandiki faili la hatua" $?
# D5) faili la hatua halipo (kompyuta halisi): demo bado inafanya kazi
demo_reset "5|" "5|" "5|" "5|" "5|" "5|" "5|" "5|"
kenv UHURU_KARIBU_STEP="$T/haipo/step" "$KARIBU" --demo; eq "demo bila faili la hatua: msimbo 0" "$?" 0

echo "6) harness ya picha (boot-screens.sh: karibu_screens)"
BS="$REPO/scripts/boot-screens.sh"
hsrc() {   # hsrc WAIT_MODE: inapakia harness na kubadilisha mon/key/shot/wait_state kuwa bandia
    UHURU_SOURCE_ONLY=1 . "$BS" "" "$T/hout" 2>/dev/null
    HL="$T/hlog"; : > "$HL"
    sleep() { :; }; key() { echo "key $*" >> "$HL"; }; typestr() { echo "typestr $*" >> "$HL"; }
    note() { echo "note $*" >> "$HL"; }; shot() { echo "shot $1" >> "$HL"; }
    wait_state() { echo "wait $1" >> "$HL"; case "${WAIT_MODE:-ok}" in ok) return 0 ;; miss3) case "$1" in *3-mwonekano*) return 1 ;; esac; return 0 ;; stale2) case "$1" in *2-lugha*) return 2 ;; esac; return 0 ;; esac; }
}
( hsrc; WAIT_MODE=ok; karibu_screens; echo "rc=$?" >> "$HL"
  grep -q '^key alt-f4$' "$HL" && grep -q '^typestr uhuru-karibu --demo$' "$HL" && [ "$(grep -c '^shot ' "$HL")" = 8 ] && grep -q '^shot 25-karibu-karibu$' "$HL" && grep -q '^shot 32-karibu-mwisho$' "$HL" \
    && grep -q '^note E2E karibu-steps=8$' "$HL" && grep -q '^rc=0$' "$HL"; echo $? > "$T/h1" ); eq "harness: hatua 8 zinapigwa picha 25..32 na kuandikwa kwenye e2e.log" "$(cat "$T/h1")" 0
( hsrc; WAIT_MODE=miss3; karibu_screens; echo "rc=$?" >> "$HL"
  [ "$(grep -c '^shot ' "$HL")" = 2 ] && grep -q '^note E2E karibu-missing=3-mwonekano$' "$HL" && grep -q '^note E2E karibu-steps=2$' "$HL" && grep -q '^rc=0$' "$HL"; echo $? > "$T/h2" ); eq "harness: dirisha likikosekana inasimama, inaripoti lililokosekana" "$(cat "$T/h2")" 0
( hsrc; WAIT_MODE=stale2; karibu_screens; echo "rc=$?" >> "$HL"; grep -q '^rc=2$' "$HL"; echo $? > "$T/h3" ); eq "harness: telemetry ikisimama inarudisha 2 (e2e inasema 'stale')" "$(cat "$T/h3")" 0
grep -q 'karibu_screens; rc=\$?; \[ \$rc -eq 2 \] && return 2' "$BS"; check "harness: karibu_screens inaitwa baada ya picha 24, ndani ya tester-login" $?
awk '/shot 24-kituo-cha-ulinzi/{a=NR} /karibu_screens; rc/{b=NR} /^        sleep 100$/{c=NR} END{exit (a&&b&&c&&a<b&&b<c)?0:1}' "$BS"; check "harness: mpangilio ni 24 -> Karibu -> sleep 100 (diag ya mwisho haiguswi)" $?

echo "7) e2e-verdict: ukaguzi wa Karibu"
mkdir -p "$T/v"; printf 'QEMU accel: kvm\nE2E telemetry=ok\nE2E tester-login=yes\nE2E karibu-start=yes\n' > "$T/v/e2e.log"
for k in 1-karibu 2-lugha 3-mwonekano 4-wallpaper 5-pakiti 6-usalama 7-ziara 8-mwisho; do echo "E2E karibu-shot=$k" >> "$T/v/e2e.log"; done
echo 'UHURU-STATE n=1 x=y' > "$T/v/serial.log"
bash "$VERD" "$T/v" 2>&1 | grep -q 'CHECK PASS: e2e: Karibu Uhuru inaonekana kwenye desktop halisi'; check "verdict: hatua 8 = PASS" $?
printf 'QEMU accel: kvm\nE2E telemetry=ok\nE2E tester-login=yes\nE2E karibu-start=yes\nE2E karibu-shot=1-karibu\nE2E karibu-missing=2-lugha\n' > "$T/v/e2e.log"
bash "$VERD" "$T/v" 2>&1 | grep -q 'CHECK FAIL: e2e: Karibu Uhuru: madirisha 1 tu kati ya 8 yameonekana (karibu-missing=2-lugha)'; check "verdict: hatua pungufu = FAIL yenye sababu" $?
printf 'QEMU accel: kvm\nE2E telemetry=ok\nE2E tester-login=yes\n' > "$T/v/e2e.log"
bash "$VERD" "$T/v" 2>&1 | grep -q 'Karibu Uhuru'; [ $? -ne 0 ]; check "verdict: bila 'karibu-start' (login ya tester haikutokea) hakuna ukaguzi wa Karibu" $?
echo
echo "=== JUMLA: $ok OK, $fail FAIL ==="
[ "$fail" = 0 ]
