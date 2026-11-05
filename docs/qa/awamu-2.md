# QA ya Awamu ya 2 — Msingi wa Debian + XFCE

Kila kipengee kipimwe kwenye ISO iliyotolewa na GitHub Actions. Andika PASS au FAIL na tarehe.

| # | Kipimo | Mahitaji | Matokeo |
|---|--------|----------|---------|
| 1 | Workflow ya "Build Uhuru OS ISO" imekamilika bila hitilafu | MH-1 | |
| 2 | SHA256 ya ISO inalingana (job ya boot-test) | Sehemu 6 (Upatikanaji) | |
| 3 | ISO inaboot hadi systemd ikifika "Graphical target" (boot-test) | MH-3 | |
| 4 | Ukurasa wa kuingia wa LightDM unaonekana na kuingia kwa mtumiaji wa live kunafanya kazi | MH-2 | |
| 5 | Desktop ya XFCE inafunguka kikamilifu | MH-2 | |
| 6 | Calamares inaanzishwa kutoka kwenye desktop | MH-6 (msingi wake; Kiswahili ni Awamu ya 4) | |
| 7 | Firefox, LibreOffice Writer/Calc/Impress zinafunguka | MH-11 | |
| 8 | Printa na kadi ya WiFi vinaonekana (kwenye kifaa halisi, si QEMU) | MH-4 | |
| 9 | Matumizi ya RAM baada ya boot ≤ 2GB (`free -m`) | MH-2, Sehemu 6 | |
| 10 | Boot time kwenye kifaa cha RAM 4GB/HDD ≤ sekunde 45 | Sehemu 6 | |

Vidokezo:
- Boot-test ya GitHub Actions inathibitisha tu kwamba mfumo unafika kwenye graphical target. Haithibitishi kwamba dirisha linaonekana. Vipimo 4 hadi 9 vinahitaji kuendeshwa kwa mkono.
- Vipimo 8 na 10 vinahitaji kifaa halisi cha mkono wa pili; havifanyiki kwenye GitHub Actions.
