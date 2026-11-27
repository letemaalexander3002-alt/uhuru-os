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

## Marekebisho ya v19.2.3 (kutoka picha ya 30 ya CI na picha ya 24 ya v19.1)
- **"Hatari 1" ya uongo:** Karibu ilionyesha "vizuri 6, tahadhari 1, hatari 1" ingawa telemetry (root) ilisema `ok=7, bad=0`. Chanzo ni `uhuru-protect`: orodha ya profile za AppArmor
  (`/sys/kernel/security/apparmor/profiles`) inasomeka na root pekee, na huduma ya `apparmor` ni `inactive` kwenye live. Mtumiaji wa kawaida alipata AppArmor nyekundu na bango "Kuna hatari" kwenye Kituo cha Ulinzi (kasoro ya zamani, iliyoonekana pia kwenye picha 24 ya v19.1).
  Sasa, bila ruhusa ya kusoma na kukiwa na kernel iliyowashwa na profile zilizopo kwenye diski, kipengele ni `ok` chenye maelezo kwamba hali kamili ya kupakiwa inaonekana kwa msimamizi tu. Kernel ikizimwa, au profile zikikosekana kwenye diski, bado ni `bad`. Tabia ya root na ya huduma `active` haijabadilika.
- **CI sasa inaona kile anachokiona mtumiaji:** telemetry P9 inaongeza `uprot=` (`uhuru-protect --check` kama mtumiaji wa kawaida), na `e2e-verdict.sh` inaikagua (FAIL kama `bad>0`). Regex za P9 pia zimebanwa zisivuke mipaka ya sehemu (zamani `.*` ingeweza kupita kwa sababu ya sehemu nyingine ya mstari).
- **`postcheck`:** onyo la AT-SPI sasa linahesabu makosa halisi ("Couldn't connect to accessibility bus"), si mistari ya kawaida ya journal ya `org.a11y.Bus`.

## Marekebisho ya v19.2.4 (CI ya v19.2.3 ilikataa kwa haki)
Ukaguzi mpya wa mtumiaji wa kawaida (`uprot=`) ulishindwa kwenye CI ya v19.2.3: `aa=bad` bado ilionekana kwa `tester`. Chanzo: marekebisho ya v19.2.3 yalidhani faili
`/sys/kernel/security/apparmor/profiles` lipo lakini halisomeki. Kwa kweli folda `/sys/kernel/security` ni 0700 ya root, kwa hiyo mtumiaji wa kawaida hawezi hata kuona faili,
`os.path.exists()` inarudisha `False`, na tawi la marekebisho likarukwa. Jaribio la v19.2.3 lilifanya mfano usio sahihi (faili lipo ila halisomeki), kwa hiyo lilipita.
Sasa fallback inatumika kwa mtumiaji asiye root (`os.geteuid() != 0`) ambaye hawezi kusoma faili (kwa sababu yoyote), kukiwa na kernel iliyowashwa na profile kwenye diski; root bila faili bado ni `bad`.
Hukumu pia imerekebishwa: P9 za mwanzo (`uprot=none`, kabla ya session ya mtumiaji) hazihesabiwi, na ujumbe wa FAIL unaonyesha matokeo halisi ya `uhuru-protect`.

## Marekebisho ya v19.2.5 (CI ya v19.2.4 ilikataa tena)
`aa=bad` ilibaki kwa mtumiaji wa kawaida baada ya v19.2.4 (picha 30: "hatari 1"). Uamuzi wa v19.2.4 ulitegemea kuwepo kwa faili za kawaida kwenye `/etc/apparmor.d`
na hatukuwa na ushahidi kwamba zipo kwenye ISO. Sasa uamuzi umetengwa (`aa_facts()` + `aa_decide()`): mtumiaji asiye root asiyeweza kusoma orodha ya kernel anapata `ok`
kama kernel imewashwa na AppArmor imewekwa (kifurushi `apparmor` AU profile kwenye diski); bila hivyo bado ni `bad`. Root anapimwa kikamilifu kama zamani.
`uhuru-protect --aa-debug` inachapisha ukweli wote (`AA-DEBUG euid=.. on=.. act=.. prof=.. readable=.. disk=.. pkg=.. decision=.. via=..`), na telemetry P9 inaubeba kama `uaa=`:
CI inaonyesha sasa KWA NINI uamuzi ni ok/bad kwa mtumiaji halisi, si kubahatisha. Majaribio yanatumia ruhusa halisi za mfumo wa faili (mtumiaji `nobody`, `/sys/kernel/security` 0700).
Maoni ya harness: picha 23/24 za CI ya v19.2.4 zinaonyesha herufi zilizodondoka kwenye amri zilizotumwa kwa QEMU ("uhuinstaller", "huru-protect"); hiyo ni tatizo la zamani la kutuma funguo, si la Karibu.

## Marekebisho ya v19.2.6 (ukweli halisi kutoka `uaa=` ya CI ya v19.2.5)
`uaa=AA-DEBUG,euid=1001,on=1,act=inactive,prof=0,readable=1,disk=13,pkg=1,decision=bad`. Kwa mtumiaji wa kawaida (`tester`) faili la profile za kernel LINAONEKANA kusomeka
(`readable=1`) lakini maudhui ni tupu (`prof=0`), wakati root anaona profile 23 zimepakiwa. v19.2.4 na v19.2.5 ziliweka fallback pale `readable=0` tu, kwa hiyo hazikufanya kazi:
dhana yetu ya "halisomeki" haikuwa kweli. Sasa fallback inategemea kile mtumiaji anachoweza kuona kweli: orodha tupu (`prof=0`) kwa asiye root, kukiwa na kernel iliyowashwa na AppArmor
imewekwa (kifurushi AU profile kwenye diski). Root yenye orodha tupu na huduma `inactive` bado ni `bad`. Majaribio sasa yanajumuisha hali halisi ya CI (readable=1 + orodha tupu).
