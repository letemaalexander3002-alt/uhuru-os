# Karibu Uhuru na pakiti za programu (v19.2)

## Karibu Uhuru (`uhuru-karibu`)
Ziara ya mara ya kwanza inayotumia `zenity` (hakuna utegemezi mpya, hakuna ongezeko la ISO linaloonekana). Hatua:
karibu → lugha (`uhuru-lugha --set`) → mwonekano Light/Dark (`uhuru-mwonekano`) na wallpaper → mtandao (hiari) → pakiti za programu →
usalama (`uhuru-protect --check`) → Duka la LGT na Uhuru Share → maliza. Kila hatua inaweza kurukwa.

Inaanza yenyewe (autostart) ukiingia kwa akaunti yako ya kwanza. **Haionekani**: kwa akaunti ya live `mtumiaji` (wizard ya usajili ndiyo
inayoongoza hapo), kwenye CI (`/run/uhuru-ci`, `/run/uhuru-setup.step`; hivyo e2e haibadiliki), ikishakamilika (`~/.config/uhuru/karibu.done`),
na bila skrini au `zenity`. "Baadaye" kwenye dirisha la kwanza halihifadhi kukamilika. Kufungua tena: menyu **Karibu Uhuru** (`uhuru-karibu --again`).

Wallpaper ukichagua moja, mzunguko wa wallpapers unazimwa (`~/.config/uhuru/no-wallpaper-rotate`) na ule unaoendelea unasimamishwa; ukichagua
"Zibadilike zenyewe" unarudi.

## Pakiti (`uhuru-pakiti`, faili `usr/share/uhuru/packs/*.pack`)
| Pakiti | Vifurushi (Debian 12) |
|---|---|
| ofisi | thunderbird pdfarranger xournalpp gnucash simple-scan keepassxc |
| shule | gcompris-qt klavaro tuxmath tuxtype stellarium |
| wasanidi | geany golang-go default-jdk-headless |

Ni **nyongeza zinazosakinishwa kwa mtandao** (`apt-get install --no-install-recommends`); hakuna kifurushi chake kilichomo kwenye ISO (ukubwa wa ISO haubadiliki).
Kifurushi kisichopatikana kwenye hazina kinarukwa na kuripotiwa, hakizuii vingine. Kwenye live session programu hupotea ukizima kompyuta (Karibu inaonya).
Kuongeza pakiti mpya: weka faili `jina.pack` (funguo: id, jina_sw/en/fr, maelezo_sw/en/fr, vifurushi); `uhuru-pakiti --check` inaikagua.

Msimbo wa `uhuru-pakiti install`: 0 sawa, 2 pakiti haijulikani, 3 hakuna mtandao, 4 hakuna kinachopatikana, 5 apt imeshindwa, 6 pkexec haipo.

## Mipaka (isiyothibitishwa na CI)
- Mwonekano wa madirisha ya Karibu kwenye desktop halisi, na kusakinisha pakiti kwa mtandao halisi: angalia kwenye VM (`uhuru-karibu --again`).
- Pakiti bado hazionekani kama kadi ndani ya Duka la LGT (Duka linaelewa kifurushi kimoja kwa kadi); zinapatikana kupitia Karibu Uhuru na `uhuru-pakiti`.
- Usambazaji wa pakiti nje ya mtandao kupitia Uhuru Share: bado haujafanywa.
- Tafsiri za en/fr ziliandikwa na msaidizi wa AI: zikaguliwe na mzungumzaji wa asili.

## Marekebisho ya telemetry (kutoka v19.1)
Mstari wa `UHURU-P7` ulibandikana ndani ya mstari wa `UHURU-DIAG` kwenye serial (waandishi wawili wa nyuma kwa wakati mmoja, n=2), na hukumu ikaupoteza.
`emit()` sasa inatumia `flock` (kila ujumbe unaandikwa mzima), na `e2e-verdict.sh` inatenganisha mistari iliyobandikana. Jaribio: `scripts/telemetry-selftest.sh`.

## Onyesho `--demo` na picha za CI (v19.2.1)
`uhuru-karibu --demo` inaonyesha madirisha yote 8 kwa mpangilio; kila moja linajifunga lenyewe baada ya sekunde 15 (`UHURU_KARIBU_DEMO_SECS`) na **hakuna kinachobadilishwa**
(si lugha, si mwonekano, si wallpaper, hakuna kinachosakinishwa, wala Duka/Kituo cha Ulinzi hakifunguliwi, wala faili la kukamilika halindikwi). Inaonyeshwa hata kwa akaunti ya live na kwenye CI.

CI (`scripts/boot-screens.sh`, kazi `karibu_screens`) inaiendesha baada ya picha 24 ndani ya session ya `tester`. Usawazishaji ni `step=karibu-N-jina` ya telemetry
(faili la hatua la CI, kama wizard), si muda wala funguo, kwa hiyo picha inapigwa dirisha linapoonekana: `25-karibu-karibu` ... `32-karibu-mwisho` (karibu, lugha, mwonekano,
wallpaper, pakiti, usalama, ziara, mwisho). `e2e-verdict.sh` inaongeza ukaguzi mmoja (madirisha 8), na `scripts/v1921-postcheck.sh` inahakikisha picha 8 zipo.
Picha hizi ziko kwenye ripoti ndogo (`screens/`), kwa hiyo unaweza kuziona kabla ya kupakua ISO.

Kikomo: demo inaonyesha mwonekano wa madirisha, si kwamba kubadili lugha/wallpaper/kusakinisha kunafanya kazi kwenye mfumo halisi (hayo yanajaribiwa na `scripts/karibu-selftest.sh` kwa zana bandia).
Hatua ya mtandao (Wi-Fi) haionyeshwi kwenye demo.

## Marekebisho ya v19.2.2 (kutoka picha halisi za CI)
Picha za CI zilionyesha kasoro mbili ambazo majaribio ya zana bandia hayakuziona:
1. **Dirisha la pakiti:** safu ya "Zilizopo" na sehemu ya maelezo vilikatika kulia. Sasa idadi iko kabla ya maelezo, dirisha ni pana (720), na maelezo ni mafupi (si zaidi ya herufi 58).
2. **Usalama:** mstari wa Hali ulionyesha "vipengele , vizuri , ..." tupu. Muundo halisi wa `uhuru-protect --check` ni `PROTECT-OK n=10 ok=7 warn=1 ...` (nafasi), si koma (koma zilikuwa kwenye mstari wa telemetry tu). Parser sasa inasoma zote mbili, na mstari wa Hali haionyeshwi kabisa kama namba hazipo.

Pia: `NO_AT_BRIDGE=1` kwa Karibu (huzuia onyo la "accessibility bus" kwenye kila dirisha), na `Xsession.d/45uhuru-atspi-clean` inaondoa mali ya `AT_SPI_BUS` iliyoachwa na greeter (uid 104).
Hiyo ya mwisho ni **nadharia** (kosa linataja `/run/user/104/at-spi/bus_0`, wakati `tester` ni uid 1001); `postcheck` itaonyesha kama onyo la AT-SPI limeisha.
