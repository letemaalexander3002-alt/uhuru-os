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
