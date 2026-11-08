#!/bin/bash
# Soma serial.log (iliyoandikwa na uhuru-selftest) na toa CHECK lines za login kutoka mwanzo hadi mwisho.
LOG=${1:?serial.log}
B=$(tr -d '\r' < "$LOG" 2>/dev/null | sed -n '/UHURU-SELFTEST BEGIN/,/UHURU-SELFTEST END/p')
if [ -z "$B" ]; then
    echo "CHECK FAIL: e2e: ripoti ya uhuru-selftest haikupatikana (wizard/login/terminal havikufika mwisho; angalia picha za skrini)"
    exit 0
fi
echo "CHECK PASS: e2e: desktop ilifikiwa baada ya login, na uhuru-selftest ilifanya kazi"
chk() { if printf '%s\n' "$B" | grep -Eq "$1"; then echo "CHECK PASS: e2e: $2"; else echo "CHECK FAIL: e2e: $3"; fi; }
chk '^user: tester '                    "login ya akaunti mpya (tester / uhurutest1) ilifanya kazi" "aliyeingia si 'tester'"
chk '^user: .*groups=.*sudo'            "akaunti mpya iko kwenye kikundi cha sudo"                  "akaunti mpya haiko kwenye sudo"
chk '^setup.done: yes'                  "usajili umewekewa alama ya kukamilika"                     "setup.done haipo"
chk '^host: uhuru-pc '                  "jina la kompyuta lililochaguliwa limetumika"               "jina la kompyuta si uhuru-pc"
chk 'tz: Africa/Dar_es_Salaam'          "saa ni Africa/Dar_es_Salaam"                               "saa si Africa/Dar_es_Salaam"
chk '^  mtumiaji: mtumiaji L '         "akaunti ya live (mtumiaji) imefungwa"                      "akaunti ya live HAIJAFUNGWA"
chk '^light-locker: [1-9]'              "light-locker inaendeshwa baada ya usajili"                 "light-locker haiendeshwi baada ya usajili"
chk '^wallpaper-rotate: [1-9]'          "mzunguko wa wallpaper unaendeshwa"                         "mzunguko wa wallpaper haiendeshwi"
chk '^grub: grub-install-ipo'           "grub-install ipo (Calamares inaweza kusakinisha)"          "grub-install haipo"
echo "--- uhuru-selftest ---"; printf '%s\n' "$B"
exit 0
