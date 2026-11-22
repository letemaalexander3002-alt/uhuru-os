# shellcheck shell=bash
# Uhuru OS v19.0: tafsiri za maandishi ya wizard ya usajili (uhuru-setup). Inapakiwa na uhuru-setup kwa `.` (source).
# CHANZO ni Kiswahili: ufunguo ni maandishi ya Kiswahili kama yalivyo kwenye uhuru-setup (CI inayategemea).
# Kiswahili (sw) hakitafsiriwi kamwe: ni njia ile ile ya CI (e2e) isiyobadilika.
# Lugha zinazotumika: en, fr. Ongeza lugha: ongeza safu kwenye _e na _p, na jina kwenye UWZ_LANGS.
shopt -u patsub_replacement 2>/dev/null || true   # bash 5.2: '&' kwenye mbadala ina maana maalum
UWZ_LANGS="sw en fr"
declare -gA UWZ_EX_en UWZ_EX_fr UWZ_PH_en UWZ_PH_fr
declare -ga UWZ_PH_KEYS=()
UWZ_LANG=${UWZ_LANG:-}

_e() { UWZ_EX_en["$1"]=$2; UWZ_EX_fr["$1"]=$3; }                        # ulinganifu kamili (jina la kitufe, kichwa, nchi)
_p() { UWZ_PH_en["$1"]=$2; UWZ_PH_fr["$1"]=$3; UWZ_PH_KEYS+=("$1"); }   # kipande cha sentensi (kinabadilishwa popote kilipo)

# ---- ulinganifu kamili ----
_e "Uhuru OS - Karibu"       "Uhuru OS - Welcome"        "Uhuru OS - Bienvenue"
_e "Anza"                    "Start"                     "Commencer"
_e "Ndiyo"                   "Yes"                       "Oui"
_e "Baadaye"                 "Later"                     "Plus tard"
_e "Nionyeshe"               "Show me"                   "Me l'afficher"
_e "Endelea"                 "Continue"                  "Continuer"
_e "Sawa"                    "OK"                        "OK"
_e "Hapana (inashauriwa)"    "No (recommended)"          "Non (recommandé)"
_e "Eneo"                    "Region"                    "Région"
_e "Nchi"                    "Country"                   "Pays"
_e "Zambia"                  "Zambia"                    "Zambie"
_e "Msumbiji"                "Mozambique"                "Mozambique"
_e "Afrika Kusini"           "South Africa"              "Afrique du Sud"
_e "Nigeria"                 "Nigeria"                   "Nigéria"
_e "Uingereza"               "United Kingdom"            "Royaume-Uni"
_e "Falme za Kiarabu"        "United Arab Emirates"      "Émirats arabes unis"

# ---- vipande vya sentensi ----
_p "Karibu Uhuru OS" "Welcome to Uhuru OS" "Bienvenue sur Uhuru OS"
_p "Tutafanya usanidi mfupi: eneo, jina la kompyuta, mtandao na akaunti yako." \
   "We will do a short setup: region, computer name, network and your account." \
   "Nous allons faire une courte configuration : région, nom de l'ordinateur, réseau et votre compte."
_p "Imetengenezwa na Letema Group Tech." "Made by Letema Group Tech." "Créé par Letema Group Tech."
_p "Chagua eneo lako (saa):" "Choose your region (time zone):" "Choisissez votre région (fuseau horaire) :"
_p "Jina la kompyuta hii (herufi ndogo, namba na -):" "Name of this computer (lowercase letters, numbers and -):" "Nom de cet ordinateur (minuscules, chiffres et -) :"
_p "Jina la kompyuta litumie herufi ndogo, namba na - tu (hadi 31)." \
   "The computer name may only use lowercase letters, numbers and - (up to 31)." \
   "Le nom de l'ordinateur ne peut contenir que des minuscules, des chiffres et - (31 au maximum)."
_p "Unataka kuunganisha mtandao (Wi-Fi) sasa?" "Do you want to connect to a network (Wi-Fi) now?" "Voulez-vous vous connecter à un réseau (Wi-Fi) maintenant ?"
_p "Ukimaliza, funga dirisha la mitandao." "When you are done, close the network window." "Une fois terminé, fermez la fenêtre des réseaux."
_p "Jina lako kamili:" "Your full name:" "Votre nom complet :"
_p "Weka jina lako." "Enter your name." "Saisissez votre nom."
_p "Chagua jina la kuingia (herufi ndogo, namba, - au _; angalau 3):" \
   "Choose a login name (lowercase letters, numbers, - or _; at least 3):" \
   "Choisissez un identifiant (minuscules, chiffres, - ou _ ; 3 au minimum) :"
_p "Jina la kuingia lianze kwa herufi ndogo; litumie herufi ndogo, namba, - au _ (3 hadi 31)." \
   "The login name must start with a lowercase letter and use only lowercase letters, numbers, - or _ (3 to 31)." \
   "L'identifiant doit commencer par une minuscule et n'utiliser que des minuscules, chiffres, - ou _ (3 à 31)."
_p "Weka password (angalau herufi 8):" "Enter a password (at least 8 characters):" "Saisissez un mot de passe (8 caractères au minimum) :"
_p "Password iwe angalau herufi 8." "The password must be at least 8 characters." "Le mot de passe doit contenir au moins 8 caractères."
_p "Rudia password:" "Repeat the password:" "Répétez le mot de passe :"
_p "Password hazilingani." "The passwords do not match." "Les mots de passe ne correspondent pas."
_p "Jaribu tena." "Try again." "Réessayez."
_p "Password yako ina herufi" "Your password length (characters):" "Longueur de votre mot de passe (caractères) :"
_p "Unataka kuiona ili kuhakikisha uliandika sahihi?" "Do you want to see it to make sure you typed it correctly?" "Voulez-vous la voir pour vérifier qu'elle est correcte ?"
_p "Password yako ni:" "Your password is:" "Votre mot de passe est :"
_p "Ikumbuke au iandike mahali salama." "Remember it or write it down in a safe place." "Retenez-le ou notez-le en lieu sûr."
_p "Uingie moja kwa moja bila kuandika password kila kompyuta inapowashwa?" \
   "Log in automatically without typing a password each time the computer starts?" \
   "Se connecter automatiquement, sans mot de passe, à chaque démarrage de l'ordinateur ?"
_p "Haishauriwi kama kompyuta inatumiwa na watu wengine." "Not recommended if the computer is used by other people." "Déconseillé si l'ordinateur est utilisé par d'autres personnes."
_p "Akaunti yako imetengenezwa." "Your account has been created." "Votre compte a été créé."
_p "Jina lako la kuingia:" "Your login name:" "Votre identifiant :"
_p "Sasa utaelekezwa kwenye skrini ya kuingia. Andika jina hilo na password uliyochagua." \
   "You will now be taken to the login screen. Enter that name and the password you chose." \
   "Vous allez être redirigé vers l'écran de connexion. Saisissez cet identifiant et le mot de passe choisi."
_p "Jina la kuingia si sahihi." "The login name is not valid." "L'identifiant n'est pas valide."
_p "Jina hilo limeshatumika. Chagua jingine." "That name is already taken. Choose another." "Ce nom est déjà utilisé. Choisissez-en un autre."
_p "Password ni fupi mno." "The password is too short." "Le mot de passe est trop court."
_p "Jina la kompyuta si sahihi." "The computer name is not valid." "Le nom de l'ordinateur n'est pas valide."
_p "Eneo si sahihi. Chagua tena." "The region is not valid. Choose again." "La région n'est pas valide. Choisissez à nouveau."
_p "Imeshindikana kutengeneza akaunti" "Could not create the account" "Impossible de créer le compte"
_p "(kosa " "(error " "(erreur "

# Panga vipande kutoka virefu kwenda vifupi (kipande kirefu kibadilishwe kwanza)
mapfile -t UWZ_PH_KEYS < <(for k in "${UWZ_PH_KEYS[@]}"; do printf '%s\t%s\n' "${#k}" "$k"; done | sort -t$'\t' -k1,1nr | cut -f2-)

# uwz_locale CODE -> jina la locale (sw -> sw_TZ.UTF-8 ...); inarudisha 1 ikiwa code haijulikani
uwz_locale() {
    case "$1" in
        sw) printf 'sw_TZ.UTF-8' ;;
        en) printf 'en_US.UTF-8' ;;
        fr) printf 'fr_FR.UTF-8' ;;
        *) return 1 ;;
    esac
}
uwz_language_var() {   # mnyororo wa LANGUAGE (gettext): lugha iliyochaguliwa kisha Kiingereza
    case "$1" in
        sw) printf 'sw_TZ:sw:en_US:en' ;;
        en) printf 'en_US:en' ;;
        fr) printf 'fr_FR:fr:en_US:en' ;;
        *) return 1 ;;
    esac
}

# uwz_set CODE: weka lugha ya wizard (UWZ_LANG) na LANG/LANGUAGE ya mchakato huu (kama locale ipo)
uwz_set() {
    local loc lng
    loc=$(uwz_locale "$1") || return 1
    UWZ_LANG=$1
    if locale -a 2>/dev/null | grep -qix "$(printf '%s' "$loc" | sed 's/UTF-8/utf8/')"; then
        lng=$(uwz_language_var "$1"); export LANG="$loc" LANGUAGE="$lng"
    fi
    return 0
}

# uwz_tr ARG -> ARG iliyotafsiriwa (au ile ile ikiwa UWZ_LANG ni sw/tupu)
uwz_tr() {
    local a=$1 pre="" v k
    case "$UWZ_LANG" in en|fr) ;; *) printf '%s' "$a"; return 0 ;; esac
    case "$a" in --*=*) pre=${a%%=*}=; v=${a#*=} ;; *) v=$a ;; esac
    # maandishi matupu au '@' / '*' hayatafsiriwi (kwenye array ya bash ni funguo maalum / zinaleta "bad array subscript")
    if [[ -z $v || $v == "@" || $v == "*" ]]; then printf '%s' "$a"; return 0; fi
    local -n _ex="UWZ_EX_$UWZ_LANG" _ph="UWZ_PH_$UWZ_LANG"
    if [[ -n ${_ex[$v]+x} ]]; then
        v=${_ex[$v]}
    else
        for k in "${UWZ_PH_KEYS[@]}"; do
            [[ $v == *"$k"* ]] && v=${v//"$k"/${_ph[$k]}}
        done
    fi
    printf '%s%s' "$pre" "$v"
}
