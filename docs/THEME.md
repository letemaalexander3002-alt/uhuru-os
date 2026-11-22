# Mwonekano wa Uhuru OS (v19.1)

Lengo: mwonekano wa kitanzania na wa kisasa bila kuvunja bajeti ya ISO (angalau MiB 20 za akiba), RAM ya GB 2 (si zaidi ya MB 100 za RAM kupotea) wala e2e.

## Vilivyomo
| Kipengele | Uamuzi | Gharama |
|---|---|---|
| Mandhari ya GTK | **Arc** (Light) na **Arc-Dark** kutoka kifurushi `arc-theme` (Debian 12) | MiB chache; matoleo ya `-Solid` yanaondolewa |
| Ikoni | **Papirus** na **Papirus-Dark** kutoka `papirus-icon-theme`; `ePapirus*` na `Papirus-Light` zinaondolewa | Kubwa kuliko zote; pima kwa `v191-postcheck.sh`; ikizidi, `UHURU_INSTALL_ICONS=no` |
| Fonti | **Noto Sans** (tayari ipo, `fonts-noto-core`) | 0 |
| Wallpapers | 5 asili (Kilimanjaro, Zanzibar, tanzanite, kitenge, Tingatinga), KB ~2,100 jumla | Angalia `LICENSE-WALLPAPERS.md` |
| Skrini ya kuingia | Mandhari `Arc-Dark`, ikoni `Papirus-Dark`, fonti `Noto Sans 11`; **background, indicators na `uhuru-greeter-setup` havibadilishwi** | 0 |
| Light/Dark | `uhuru-mwonekano` (kidirisha na CLI), menyu "Mwonekano / Appearance / Apparence" | 0 |
| Tafsiri za menyu | `Name[en]`, `Name[fr]`, `Comment[...]` kwa programu za Uhuru zinazotambulika (jina la faili au `Exec=`) | 0 |
| AT-SPI | `at-spi2-core` inaondoa onyo la `org.a11y.Bus` na kusaidia visoma-skrini | KB mamia |

Chanzo kimoja cha mipangilio: `config/includes.chroot/etc/uhuru/theme.defaults`. Hook haiguswi ili kubadilisha rangi, mandhari, fonti au hali ya mwanzo.

## Usalama wa CI (kanuni za Mpango Mkuu)
- Hakuna maandishi ya Kiswahili ya wizard yaliyobadilishwa; hakuna hatua mpya ya wizard; `e2e.log` lazima iwe na hatua 9 zilezile.
- Hook inaisha kwa `exit 0`; mandhari ikikosekana (`uhuru-theme: ONYO`), mwonekano wa awali unabaki na `theme_applied=no`.
- Hook haibadilishi faili za awamu nyingine isipokuwa: `theme-name`/`icon-theme-name`/`font-name` kwenye greeter, `xsettings.xml`/`xfwm4.xml`, na mistari ya `Name[en|fr]`/`Comment[en|fr]`.

## Majaribio
- `bash scripts/theme-selftest.sh` (tuli, sekunde chache; pia kwenye GitHub: `theme-check.yml`).
- Baada ya build: `bash scripts/v191-postcheck.sh ~/storage/downloads/uhuru-report-v191` (kigezo cha ISO, vifurushi, RAM, e2e, greeter).
- Kwenye VM: `uhuru-mwonekano --check`, `cat /usr/share/uhuru/theme-build.txt`, `uhuru-lugha --check`.

## Yaliyoahirishwa kwa makusudi (yanahitaji faili ambazo hatujaona)
- Mpangilio wa paneli na Whisker (`xfce4-panel.xml` ya hook ya awamu 4).
- Mzunguko wa wallpapers: `uhuru-wallpaper` haijaonekana; v19.1 inaongeza viungo `uhuru-os-wallpaper-5..9.png` na kuchapisha kwenye logi jinsi script hiyo inavyochagua picha.
- Plymouth (uko, hatari ndogo, hakuna faida ya haraka).
- Tafsiri za ndani ya Duka, Share na Ulinzi (`uhuru-store`, `uhuru-share`, `uhuru-protect` hazijaonekana).
- Tafsiri za en/fr za menyu zimeandikwa na msaidizi wa AI: zikaguliwe na mzungumzaji wa asili.
