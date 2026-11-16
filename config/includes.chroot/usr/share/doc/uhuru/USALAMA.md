# Uhuru OS - Taarifa ya Usalama na Faragha

Hati hii inaeleza kwa uwazi kinachofanyika kwenye kompyuta yako. Unaweza kukikagua mwenyewe.

## Ulinzi uliowashwa kwa msingi
| Kipengele | Kinachofanyika | Amri ya kuangalia |
|---|---|---|
| Ngome ya moto (nftables) | Hakuna kinachoingia bila ruhusa; majibu ya miunganisho yako yanaruhusiwa | `uhuru-firewall status` |
| Wasifu wa ngome | **umma** (chaguo-msingi) au **nyumbani** (kwa Uhuru Share kupitia LAN) | `pkexec uhuru-firewall nyumbani` |
| AppArmor | Programu zinafungwa kwenye mipaka yake | `aa-status` |
| Kernel iliyoimarishwa | Siri za kernel zimefichwa; mtandao unalindwa | `sysctl kernel.kptr_restrict` |
| Faragha ya Wi-Fi | MAC haifuatiliki; anwani za IPv6 za muda | `/etc/NetworkManager/conf.d/90-uhuru-privacy.conf` |
| Sasisho za usalama | Zinapakuliwa kiotomatiki kwenye mfumo ULIOSAKINISHWA (si kwenye live) | `/etc/apt/apt.conf.d/52uhuru-security-updates` |
| Uhuru Flash Safe | Kila flash inakaguliwa kwa virus vya "shortcut", autorun na faili zinazojificha | `uhuru-usbscan --all` |
| Usimbaji wa diski | LUKS - unachaguliwa wakati wa kusakinisha | `lsblk` (aina `crypt`) |
| Secure Boot | Inaungwa mkono kwenye mfumo uliosakinishwa kwa UEFI (shim na grub zilizosainiwa) | `mokutil --sb-state` |

## Uhuru Flash Safe
- Haifuti chochote bila kukuuliza. "Safisha" inahamisha faili hatari kwenye `~/Uhuru-Quarantine` na kufunua folda zilizofichwa.
- Inafanya kazi bila hifadhidata wala mtandao. ClamAV (hiari) inahitaji kupakua hifadhidata mara moja: `uhuru-usbscan --update`.

## Faragha
- **Hakuna telemetry kwa mtumiaji.** Kompyuta yako haitumi taarifa zozote kwa Letema Group Tech wala mtu mwingine.
- Huduma ya ukaguzi ya CI (`uhuru-ci-telemetry`) inaamka **tu** kwenye mashine pepe ya majaribio ya CI (inayotambuliwa kwa serial maalum ya QEMU) na haifanyi chochote kwenye kompyuta halisi.
- LGT Store inasoma orodha ya programu ya mbali (GitHub) kusasisha katalogi; haitumi data yako.

## Uwazi wa mfumo
- Orodha kamili ya vifurushi: `/usr/share/uhuru/SBOM-packages.txt`
- Toleo: `/usr/share/uhuru/RELEASE`
- Saini za kidijitali: `uhuru-sign keygen | sign | verify` (ed25519) kwa vifurushi vya Uhuru Share.

## Tunachokukumbusha
- Usimbaji wa diski hauwezi kuwashwa baada ya kusakinisha; uchague wakati wa usakinishaji.
- Kwenye mtandao wa umma (cafe, shule) acha ngome kwenye wasifu wa **umma**.
- Sasisha antivirus (ClamAV) ukiwa na mtandao mzuri kabla ya kuitegemea.
