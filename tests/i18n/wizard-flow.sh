#!/bin/bash
# Uhuru OS v19.0: jaribio la mtiririko wa wizard (uhuru-setup) bila ISO wala skrini.
# Linathibitisha:
#   A) Njia ya CI (/run/uhuru-ci ipo): wizard mpya inafanya EXACTLY kile wizard ya v18 inachofanya (dirisha zilezile, maandishi yale yale,
#      majina ya hatua yale yale, data ile ile kwa uhuru-create-user). Hii inalinda e2e.
#   B) Si CI, Kiswahili: dirisha moja la lugha tu limeongezwa; mengine hayajabadilika.
#   C) Si CI, English na Français: maandishi yote yamefasiriwa (hakuna neno la Kiswahili lililobaki), uhuru-set-locale imeitwa,
#      na data kwa uhuru-create-user ni ile ile (nenosiri halijaguswa).
# Matumizi: REPO=/njia/ya/repo bash tests/i18n/wizard-flow.sh
set -u
REPO=${REPO:-$(cd "$(dirname "$0")/../.." && pwd)}
NEW="$REPO/config/includes.chroot/usr/local/bin/uhuru-setup"
LIB="$REPO/config/includes.chroot/usr/local/lib/uhuru/wizard-i18n.sh"
OLD="$REPO/tests/i18n/uhuru-setup.v18.baseline"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ok=0; fail=0
check() { if [ "$2" = 0 ]; then ok=$((ok+1)); else fail=$((fail+1)); echo "  FAIL: $1"; fi; }

mkdir -p "$T/bin"
cat > "$T/bin/zenity" <<'ZEOF'
#!/bin/bash
# zenity bandia: inaandika kila dirisha (kila hoja mstari mmoja) na inajibu kama mtumiaji
{ for a in "$@"; do printf '%s\n' "$a"; done; echo "====="; } >> "$ZLOG"
{ cat "$STEPFILE" 2>/dev/null; echo; } >> "$STEPLOG"   # jina la hatua wakati dirisha linapoonyeshwa
case " $* " in *" --list "*)
    case "$*" in *"Choose your language"*) cat "$LANGPICK"; echo; exit 0 ;; esac
    echo "Africa/Dar_es_Salaam"; exit 0 ;;
esac
for a in "$@"; do case "$a" in
    --entry) n=$(cat "$ECOUNT" 2>/dev/null || echo 0); n=$((n+1)); echo $n > "$ECOUNT"
             case $n in 1) echo "pc-test" ;; 2) echo "Mtu Mmoja" ;; *) echo "mtu1" ;; esac; exit 0 ;;
    --password) echo 'Abcdef12!'; exit 0 ;;
    --question) exit 1 ;;
esac; done
exit 0
ZEOF
cat > "$T/bin/sudo" <<'SEOF'
#!/bin/bash
echo "sudo $*" >> "$SLOG"
case "$*" in *uhuru-create-user*) cat > "$CREATEIN" ;; esac
exit 0
SEOF
printf '#!/bin/sh\nprintf "en_US.utf8\\nsw_TZ.utf8\\nfr_FR.utf8\\n"\n' > "$T/bin/locale"
chmod +x "$T/bin/"*
echo "quiet splash boot=live username=mtumiaji" > "$T/cmdline"

# nakala za wizard zenye njia za mfumo zimebadilishwa kuwa njia za majaribio
prep() { sed -e "s#/proc/cmdline#$T/cmdline#g" -e "s#/var/lib/uhuru-setup.done#$T/done#g" -e "s#/run/uhuru-ci#$T/ci#g" \
             -e "s#/run/uhuru-setup.step#$T/step#g" -e "s#/usr/local/lib/uhuru/wizard-i18n.sh#$LIB#g" -e "s#/tmp/uhuru-create-user.log#$T/cu.log#g" "$1" > "$2"; }
prep "$OLD" "$T/old.sh"; prep "$NEW" "$T/new.sh"

run() {  # run SCRIPT CI(1|0) LANGPICK  -> $T/out/{zlog,steps,slog,createin}
    local script=$1 ci=$2 pick=$3
    rm -rf "$T/out"; mkdir -p "$T/out"; rm -f "$T/ci" "$T/step" "$T/done" "$T/ecount"
    # kwenye CI halisi: /run/uhuru-ci na /run/uhuru-setup.step zote zipo; nje ya CI hakuna hata moja
    [ "$ci" = 1 ] && { : > "$T/ci"; : > "$T/step"; }
    echo "$pick" > "$T/langpick"
    STEPFILE="$T/step" STEPLOG="$T/out/steps" ZLOG="$T/out/zlog" SLOG="$T/out/slog" CREATEIN="$T/out/createin" ECOUNT="$T/ecount" LANGPICK="$T/langpick" \
        PATH="$T/bin:$PATH" bash "$script" >"$T/out/stdout" 2>"$T/out/stderr"
    echo $? > "$T/out/rc"
}
snap() { rm -rf "$T/$1"; cp -r "$T/out" "$T/$1"; }

# nambari za dirisha: dirisha la kwanza la mtiririko (lugha) huondolewa kwa kulinganisha
first_dialog_lines() { awk 'BEGIN{n=0} /^=====$/{n++; if(n==1){print NR; exit}}' "$1"; }

run "$T/old.sh" 1 Kiswahili; snap A
check "wizard ya zamani inamaliza kwa rc=0 (harness inafanya kazi)" "$([ "$(cat $T/A/rc)" = 0 ] && echo 0 || echo 1)"
check "uhuru-create-user ilipokea mistari 6" "$([ "$(wc -l < $T/A/createin)" = 6 ] && echo 0 || echo 1)"
check "hatua zimerekodiwa kwa mpangilio (welcome ... autologin)" "$(grep -qx welcome "$T/A/steps" && grep -qx tz "$T/A/steps" && grep -qx autologin "$T/A/steps" && echo 0 || echo 1)"

# --- A) CI: mpya == ya zamani
run "$T/new.sh" 1 Kiswahili; snap B
for f in zlog steps slog createin rc; do cmp -s "$T/A/$f" "$T/B/$f"; check "CI: $f ni sawa kabisa na v18" $?; done
check "CI: hakuna kosa la stderr" "$([ ! -s "$T/B/stderr" ] && echo 0 || { cat "$T/B/stderr"; echo 1; })"
grep -q 'Choose your language' "$T/B/zlog"; check "CI: dirisha la lugha HALIONEKANI" $((1 - $?))
grep -q 'set-locale' "$T/B/slog"; check "CI: uhuru-set-locale haitwi" $((1 - $?))

# --- CI kwa kiashiria kimoja tu (ama /run/uhuru-ci ama faili la hatua): hatua ya lugha inarukwa
for ind in ci step; do
    rm -rf "$T/out"; mkdir -p "$T/out"; rm -f "$T/ci" "$T/step" "$T/done" "$T/ecount"; : > "$T/$ind"; echo Français > "$T/langpick"
    STEPFILE="$T/step" STEPLOG="$T/out/steps" ZLOG="$T/out/zlog" SLOG="$T/out/slog" CREATEIN="$T/out/createin" ECOUNT="$T/ecount" LANGPICK="$T/langpick" \
        PATH="$T/bin:$PATH" bash "$T/new.sh" >/dev/null 2>&1
    grep -q 'Choose your language' "$T/out/zlog"; check "kiashiria '$ind' pekee kinaruka dirisha la lugha" $((1 - $?))
done

# --- B) Si CI, Kiswahili: dirisha moja la ziada tu
run "$T/new.sh" 0 Kiswahili; snap C
n=$(first_dialog_lines "$T/C/zlog")
tail -n +$((n+1)) "$T/C/zlog" > "$T/C/zlog.rest"
cmp -s "$T/A/zlog" "$T/C/zlog.rest"; check "Kiswahili: madirisha mengine yote hayajabadilika" $?
cmp -s "$T/A/createin" "$T/C/createin"; check "Kiswahili: data ya create-user haijabadilika" $?
grep -q 'set-locale' "$T/C/slog"; check "Kiswahili: hakuna mabadiliko ya locale ya mfumo" $((1 - $?))

# --- C) English / Français
MARK='yako|lako|jina |chagua|kuingia|akaunti|herufi|ndogo|unataka|baadaye|tutafanya|karibu|imeshindikana|imetengenezwa|iandike|ikumbuke|kompyuta|mtandao|\beneo\b|hazilingani|jaribu tena|weka '
for pair in "English:en" "Français:fr"; do
    pick=${pair%%:*}; code=${pair##*:}
    run "$T/new.sh" 0 "$pick"; snap D
    check "$code: wizard inamaliza rc=0" "$([ "$(cat $T/D/rc)" = 0 ] && echo 0 || echo 1)"
    n=$(first_dialog_lines "$T/D/zlog"); tail -n +$((n+1)) "$T/D/zlog" > "$T/D/zlog.rest"
    if grep -qiE "$MARK" "$T/D/zlog.rest"; then check "$code: hakuna neno la Kiswahili lililobaki" 1; grep -iE "$MARK" "$T/D/zlog.rest" | head -5; else check "$code: hakuna neno la Kiswahili lililobaki" 0; fi
    grep -q "^sudo -n /usr/local/sbin/uhuru-set-locale $code\$" "$T/D/slog"; check "$code: uhuru-set-locale $code imeitwa" $?
    cmp -s "$T/A/createin" "$T/D/createin"; check "$code: data ya create-user ni ile ile (nenosiri halijaguswa)" $?
    [ "$(grep -c '^=====$' "$T/D/zlog.rest")" = "$(grep -c '^=====$' "$T/A/zlog")" ]; check "$code: idadi ya madirisha ni ile ile" $?
    [ ! -s "$T/D/stderr" ]; check "$code: hakuna kosa la stderr" $?
done
# lugha ya Kifaransa: kichwa na vitufe vimefasiriwa
grep -q '^--title=Uhuru OS - Bienvenue$' "$T/D/zlog"; check "fr: kichwa cha dirisha kimefasiriwa" $?
grep -q '^--ok-label=Commencer$' "$T/D/zlog"; check "fr: kitufe 'Anza' kimefasiriwa" $?
grep -q 'Votre compte a été créé' "$T/D/zlog"; check "fr: ujumbe wa mwisho umefasiriwa" $?

echo "wizard-flow: $ok OK, $fail FAIL"
[ "$fail" = 0 ]
