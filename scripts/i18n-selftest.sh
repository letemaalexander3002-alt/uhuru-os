#!/bin/bash
# Uhuru OS v19.0: majaribio ya lugha bila ISO (yanaendeshwa na GitHub Actions: .github/workflows/i18n-check.yml, na Termux).
# Matumizi: bash scripts/i18n-selftest.sh      (kutoka mzizi wa repo)
set -u
REPO=${REPO:-$(cd "$(dirname "$0")/.." && pwd)}
B="$REPO/config/includes.chroot"
LIB="$B/usr/local/lib/uhuru/wizard-i18n.sh"
LUGHA="$B/usr/local/bin/uhuru-lugha"
SETLOC="$B/usr/local/sbin/uhuru-set-locale"
XHOOK="$B/etc/X11/Xsession.d/45uhuru-lang"
HOOK="$REPO/config/hooks/live/9999-uhuru-i18n.hook.chroot"
WIZ="$B/usr/local/bin/uhuru-setup"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ok=0; fail=0
check() { if [ "$2" = 0 ]; then ok=$((ok+1)); else fail=$((fail+1)); echo "  FAIL: $1"; fi; }
eq() { [ "$2" = "$3" ]; check "$1 (tarajio '$3', imepatikana '$2')" $?; }

echo "1) Syntax"
for f in "$LIB" "$LUGHA" "$WIZ"; do bash -n "$f" 2>"$T/e"; check "bash -n $(basename "$f")" $?; done
for f in "$SETLOC" "$HOOK"; do sh -n "$f" 2>"$T/e"; check "sh -n $(basename "$f")" $?; done
if command -v dash >/dev/null 2>&1; then dash -n "$XHOOK"; check "dash -n 45uhuru-lang" $?; else sh -n "$XHOOK"; check "sh -n 45uhuru-lang" $?; fi
[ -x "$LUGHA" ] && [ -x "$SETLOC" ]; check "uhuru-lugha na uhuru-set-locale vina ruhusa ya kuendeshwa" $?
[ -x "$HOOK" ]; check "hook 9999 ina ruhusa ya kuendeshwa" $?

echo "2) Maktaba ya tafsiri"
# shellcheck disable=SC1090
. "$LIB"
prev=999999; sorted=0
for k in "${UWZ_PH_KEYS[@]}"; do [ "${#k}" -le "$prev" ] || sorted=1; prev=${#k}; done
check "vipande vimepangwa kutoka virefu kwenda vifupi" $sorted
miss=0; for k in "${UWZ_PH_KEYS[@]}"; do [ -n "${UWZ_PH_en[$k]:-}" ] && [ -n "${UWZ_PH_fr[$k]:-}" ] || { miss=1; echo "   tafsiri tupu: $k"; }; done
check "kila kipande kina tafsiri ya en na fr" $miss
miss=0; for k in "${!UWZ_EX_en[@]}"; do [ -n "${UWZ_EX_en[$k]}" ] && [ -n "${UWZ_EX_fr[$k]}" ] || { miss=1; echo "   tafsiri tupu: $k"; }; done
check "kila ulinganifu kamili una tafsiri ya en na fr" $miss
# kila kipande kimo kwenye wizard (hakuna ufunguo uliokufa) -- wizard inayo maandishi ya Kiswahili ya v18
SRC="$WIZ"; [ -f "$REPO/tests/i18n/uhuru-setup.v18.baseline" ] && SRC="$REPO/tests/i18n/uhuru-setup.v18.baseline"
dead=0; for k in "${UWZ_PH_KEYS[@]}"; do grep -qF -- "$k" "$SRC" || { dead=1; echo "   ufunguo haupo kwenye wizard: $k"; }; done
check "hakuna ufunguo uliokufa (kila kipande kipo kwenye uhuru-setup)" $dead
for k in "${!UWZ_EX_en[@]}"; do grep -qF -- "$k" "$SRC" || { dead=1; echo "   ulinganifu haupo kwenye wizard: $k"; }; done
check "hakuna ulinganifu uliokufa" $dead

# kutafsiri: sw/tupu hakubadilishi; hoja za ajabu hazivunji
UWZ_LANG=sw; eq "sw: haibadilishi" "$(uwz_tr '--text=Jina lako kamili:')" "--text=Jina lako kamili:"
UWZ_LANG=""; eq "tupu: haibadilishi" "$(uwz_tr 'Weka jina lako.')" "Weka jina lako."
UWZ_LANG=en; eq "en: kipande" "$(uwz_tr '--text=Jina lako kamili:')" "--text=Your full name:"
UWZ_LANG=fr; eq "fr: kipande" "$(uwz_tr '--text=Jina lako kamili:')" "--text=Votre nom complet :"
UWZ_LANG=fr; eq "fr: kichwa" "$(uwz_tr 'Uhuru OS - Karibu')" "Uhuru OS - Bienvenue"
UWZ_LANG=en; eq "en: kitufe (ulinganifu kamili)" "$(uwz_tr '--ok-label=Anza')" "--ok-label=Start"
UWZ_LANG=en; eq "en: 'Anza' ndani ya neno lingine haibadilishwi" "$(uwz_tr '--text=Anzania')" "--text=Anzania"
UWZ_LANG=en; eq "en: nambari ndani ya sentensi (herufi 12)" "$(uwz_tr '--text=Password yako ina herufi 12.')" "--text=Your password length (characters): 12."
for lng in en fr; do
    UWZ_LANG=$lng; errs=0
    for a in "" "@" "*" "]" "[" "[x]" '$(date)' '`id`' "a b c" "--x=" "--=" $'line1\nline2' "'quote'" '"dq"' '&' '\n' '--text=Password yako ni:\n\nAb&1\n\nIkumbuke au iandike mahali salama.'; do
        out=$(uwz_tr "$a" 2>"$T/err"); [ ! -s "$T/err" ] || { errs=1; echo "   stderr kwa hoja '$a': $(cat "$T/err")"; }
    done
    check "$lng: hoja za ajabu hazizalishi hitilafu" $errs
done
UWZ_LANG=en; out=$(uwz_tr '--text=Password yako ni:\n\nAb&1$x\n\nIkumbuke au iandike mahali salama.')
eq "en: nenosiri lenye '&' na '\$' halijaguswa" "$out" '--text=Your password is:\n\nAb&1$x\n\nRemember it or write it down in a safe place.'
eq "uwz_locale sw" "$(uwz_locale sw)" "sw_TZ.UTF-8"; uwz_locale xx >/dev/null 2>&1; check "uwz_locale lugha isiyojulikani inakataliwa" $((1 - $([ $? -ne 0 ] && echo 1 || echo 0)))

# maandishi YOTE ya wizard (pamoja na yale ya makosa ambayo harness haiyafikii) yanatafsiriwa kikamilifu
python3 - "$SRC" > "$T/strings.txt" <<'PYEOF'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
out = []
for m in re.finditer(r'--(text|ok-label|cancel-label)="((?:[^"\\]|\\.)*)"', s):
    v = m.group(2).replace("\\\\", "\\")           # \\n kwenye bash ya ndani ya "..." = \n halisi
    v = re.sub(r'\$\{[^}]*\}|\$[A-Za-z_]+', "X", v)
    out.append("--%s=%s" % (m.group(1), v))
for m in re.finditer(r'"([A-Z][a-zA-Z ]+)" \\\n', s):
    out.append(m.group(1))
print("\n".join(sorted(set(out))))
PYEOF
n=$(wc -l < "$T/strings.txt"); [ "$n" -ge 30 ]; check "maandishi ya wizard yametolewa ($n)" $?
MARK='yako|lako|jina |chagua|kuingia|akaunti|herufi|ndogo|unataka|baadaye|tutafanya|karibu|imeshindikana|imetengenezwa|iandike|ikumbuke|kompyuta|mtandao|\beneo\b|hazilingani|jaribu tena|weka |\bsi sahihi|\bmno\b|fupi'
for lng in en fr; do
    UWZ_LANG=$lng; left=0
    while IFS= read -r line; do
        tr=$(uwz_tr "$line")
        if printf '%s' "$tr" | grep -qiE "$MARK"; then left=1; echo "   $lng bado Kiswahili: $line  =>  $tr"; fi
    done < "$T/strings.txt"
    check "$lng: kila maandishi ya wizard yamefasiriwa (hakuna neno la Kiswahili)" $left
done

echo "3) uhuru-set-locale"
F="$T/locale"; export UHURU_LOCALE_FILE="$F" UHURU_LOCALE_NOGEN=1
printf 'LANG=en_US.UTF-8\nLC_TIME=sw_TZ.UTF-8\nLANGUAGE=en\n' > "$F"
"$SETLOC" fr >/dev/null; eq "fr: LANG" "$(sed -n 's/^LANG=//p' "$F")" "fr_FR.UTF-8"
eq "fr: LANGUAGE" "$(sed -n 's/^LANGUAGE=//p' "$F")" "fr_FR:fr:en_US:en"
eq "mistari mingine inabaki (LC_TIME)" "$(sed -n 's/^LC_TIME=//p' "$F")" "sw_TZ.UTF-8"
eq "LANG ipo mara moja tu" "$(grep -c '^LANG=' "$F")" "1"
"$SETLOC" sw >/dev/null; eq "sw: LANG" "$(sed -n 's/^LANG=//p' "$F")" "sw_TZ.UTF-8"; eq "sw: LANGUAGE" "$(sed -n 's/^LANGUAGE=//p' "$F")" "sw_TZ:sw:en_US:en"
"$SETLOC" en >/dev/null; eq "en: LANG" "$(sed -n 's/^LANG=//p' "$F")" "en_US.UTF-8"
cp "$F" "$T/before"; "$SETLOC" en >/dev/null; cmp -s "$F" "$T/before"; check "kurudia kunatoa faili lile lile (idempotent)" $?
"$SETLOC" xx >/dev/null 2>&1; eq "code isiyojulikani inakataliwa (exit 2)" "$?" "2"
"$SETLOC" "sw; rm -rf /" >/dev/null 2>&1; eq "code yenye amri inakataliwa" "$?" "2"
cmp -s "$F" "$T/before"; check "faili halibadiliki baada ya kukataliwa" $?
rm -f "$F"; "$SETLOC" fr >/dev/null; eq "faili jipya linaundwa" "$(cat "$F")" "$(printf 'LANG=fr_FR.UTF-8\nLANGUAGE=fr_FR:fr:en_US:en')"
unset UHURU_LOCALE_NOGEN
if [ "$(id -u)" != 0 ]; then unset UHURU_LOCALE_FILE; "$SETLOC" fr >/dev/null 2>&1; eq "bila root (na bila override) inakataliwa (exit 4)" "$?" "4"; fi
export UHURU_LOCALE_FILE="$F"

echo "4) uhuru-lugha"
export UHURU_LANG_HOME="$T/home"; mkdir -p "$UHURU_LANG_HOME"; export UHURU_LOCALE_FILE="$T/loc2" UHURU_LOCALE_NOGEN=1 UHURU_SET_LOCALE="$SETLOC"
eq "--get bila chochote = Kiswahili" "$("$LUGHA" --get)" "sw"
printf 'LANG=fr_FR.UTF-8\n' > "$UHURU_LOCALE_FILE"; eq "--get inafuata lugha ya mfumo" "$("$LUGHA" --get)" "fr"
"$LUGHA" --set en >/dev/null 2>&1; eq "--set en: faili la mtumiaji" "$(cat "$UHURU_LANG_HOME/.config/uhuru/lang")" "en"
eq "--get: mtumiaji anashinda mfumo" "$("$LUGHA" --get)" "en"
"$LUGHA" --set xx >/dev/null 2>&1; eq "--set code isiyojulikani (exit 2)" "$?" "2"
eq "faili halikubadilika baada ya kukataliwa" "$(cat "$UHURU_LANG_HOME/.config/uhuru/lang")" "en"
printf '../../etc/passwd\n' > "$UHURU_LANG_HOME/.config/uhuru/lang"; eq "--get: faili lenye takataka linarudi kwa lugha ya mfumo" "$("$LUGHA" --get)" "fr"
printf 'sw\n' > "$UHURU_LANG_HOME/.config/uhuru/lang"; eq "--get sw kutoka faili" "$("$LUGHA" --get)" "sw"
"$LUGHA" --system sw >/dev/null; eq "--system sw inaandika faili la mfumo" "$(sed -n 's/^LANG=//p' "$UHURU_LOCALE_FILE")" "sw_TZ.UTF-8"
"$LUGHA" --system zz >/dev/null 2>&1; eq "--system code mbaya (exit 2)" "$?" "2"
eq "--list ina lugha 3" "$("$LUGHA" --list | wc -l | tr -d ' ')" "3"
"$LUGHA" --check > "$T/check.txt" 2>&1; eq "--check inaisha vizuri" "$?" "0"; grep -q '^UHURU-I18N jumla ' "$T/check.txt"; check "--check inachapisha muhtasari" $?
"$LUGHA" --bogus >/dev/null 2>&1; eq "chaguo lisilojulikana (exit 2)" "$?" "2"
unset UHURU_LANG_HOME UHURU_LOCALE_FILE UHURU_LOCALE_NOGEN UHURU_SET_LOCALE

echo "5) Xsession (dash): lugha ya akaunti"
mkdir -p "$T/xbin"
mkshim() { printf '#!/bin/sh\nprintf "%s"\n' "$1" > "$T/xbin/locale"; chmod +x "$T/xbin/locale"; }
runx() {  # runx PREF-CONTENT -> "LANG|LANGUAGE"
    local h="$T/xhome"; rm -rf "$h"; mkdir -p "$h/.config/uhuru"
    [ -n "$1" ] && printf '%s\n' "$1" > "$h/.config/uhuru/lang"
    env -i PATH="$T/xbin:/usr/bin:/bin" HOME="$h" LANG=sw_TZ.UTF-8 LANGUAGE=sw_TZ:sw sh -c ". '$XHOOK'; printf '%s|%s' \"\$LANG\" \"\$LANGUAGE\""
}
SH=sh; command -v dash >/dev/null 2>&1 && SH=dash
mkshim 'en_US.utf8\nsw_TZ.utf8\nfr_FR.utf8\n'
eq "pref fr" "$(runx fr)" "fr_FR.UTF-8|fr_FR:fr:en_US:en"
eq "pref en" "$(runx en)" "en_US.UTF-8|en_US:en"
eq "pref sw" "$(runx sw)" "sw_TZ.UTF-8|sw_TZ:sw:en_US:en"
eq "bila faili: hakuna mabadiliko" "$(runx '')" "sw_TZ.UTF-8|sw_TZ:sw"
eq "takataka: hakuna mabadiliko" "$(runx '../../x; id')" "sw_TZ.UTF-8|sw_TZ:sw"
eq "lugha isiyojulikani: hakuna mabadiliko" "$(runx de)" "sw_TZ.UTF-8|sw_TZ:sw"
mkshim 'en_US.utf8\nsw_TZ.utf8\n'
eq "pref fr lakini locale haipo: hakuna mabadiliko" "$(runx fr)" "sw_TZ.UTF-8|sw_TZ:sw"
# vigezo vya hook havibaki kwenye mazingira ya session
env -i PATH="$T/xbin:/usr/bin:/bin" HOME="$T/xhome" sh -c ". '$XHOOK'; env | grep -c '^uhuru_' || true" > "$T/envleft"; eq "hakuna vigezo vya uhuru_ vilivyobaki" "$(tr -d '\n ' < "$T/envleft")" "0"

echo "6) Hook ya build na faili la menyu"
grep -q 'exit 0' "$HOOK"; check "hook 9999 inaisha na exit 0 (haivunji build)" $?
grep -qE 'hunspell-sw' "$HOOK"; check "hook inaweka hunspell-sw" $?
if command -v desktop-file-validate >/dev/null 2>&1; then desktop-file-validate "$B/usr/share/applications/uhuru-lugha.desktop"; check "uhuru-lugha.desktop ni sahihi" $?; fi
if [ -f "$REPO/tests/i18n/wizard-flow.sh" ]; then
    echo "7) Mtiririko wa wizard"
    REPO="$REPO" bash "$REPO/tests/i18n/wizard-flow.sh"; check "wizard-flow" $?
fi

echo
echo "i18n-selftest: $ok OK, $fail FAIL"
[ "$fail" = 0 ]
