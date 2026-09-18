# Uhuru OS — Awamu ya 2: Msingi wa Kiufundi

Lengo la awamu hii (kama Hati ya Mahitaji, Sehemu 5.1 inavyosema — MH-1 hadi MH-3):
kuthibitisha kuwa mfumo unaboot na kufanya kazi juu ya Debian + XFCE + Calamares,
**bila branding bado**. Branding (jina, wallpaper, icons, tafsiri) ni Awamu ya 3.

## 1. Mahitaji Kabla ya Kuanza

Huwezi kujenga ISO hii kwenye Termux/simu — inahitaji **mashine au seva yenye
Debian 12 (bookworm) au Ubuntu iliyosanikishwa**, siyo Windows/macOS moja kwa moja.
Chaguo rahisi zaidi:

- **VPS ya bei nafuu** (DigitalOcean, Hetzner, Contabo) yenye Debian 12, RAM 4GB+,
  diski 20GB+ ya nafasi huru — hii ndiyo njia ninayopendekeza zaidi kwako kwa sasa.
- Au kompyuta ya kimwili/VM yenye Debian 12 iliyosanikishwa.

Vipimo vya chini: RAM 4GB (build inatumia RAM nyingi), diski huru 15-20GB,
mtandao mzuri (itapakua ~1-2GB ya packages).

## 2. Kusanikisha Zana

```bash
sudo apt update
sudo apt install -y live-build live-boot live-config git zip
```

## 3. Kupakua na Kuandaa Faili Hizi

Pakua faili ulizopewa (zip hii), kisha:

```bash
mkdir -p ~/uhuru-os && cd ~/uhuru-os
unzip /path/to/uhuru-os-awamu2-livebuild.zip -d .
chmod +x auto/config auto/clean jenga.sh
```

## 4. Kujenga ISO

Njia rahisi (skripti moja):

```bash
./jenga.sh
```

Au hatua kwa hatua wewe mwenyewe:

```bash
sudo lb config
sudo lb build 2>&1 | tee build.log
```

Ukishakamilika, utaona faili kama `live-image-amd64.hybrid.iso` kwenye saraka hii.
Kama build ikisimama na hitilafu, soma `build.log` — mara nyingi ni tatizo la
mtandao (package haipatikani) au nafasi ya diski.

## 5. Kujaribu ISO (Kazi yako ya QA)

**Usijaribu moja kwa moja kwenye kompyuta yako kuu.** Tumia VirtualBox:

1. Sanikisha VirtualBox kwenye kompyuta yako.
2. Tengeneza VM mpya: Type=Linux, Version=Debian (64-bit), RAM 2-4GB, disk 20GB.
3. Ambatanisha faili la `.iso` kama boot disk, anzisha (boot) VM.
4. Fuata **Orodha ya Ukaguzi wa QA** iliyoambatanishwa (`QA_CHECKLIST_AWAMU2.md`)
   na unijulishe matokeo — tukikubaliana ISO inaboot vizuri, tunaendelea Awamu ya 3
   (branding, tafsiri, muonekano).

## 6. Kama Hujui Kuendesha Seva ya Linux

Hii ni sehemu inayohitaji "Linux/Systems Engineer" ya kweli (kama Hati ya Mahitaji
Sehemu 10 inavyosema). Kama huna mtu wa kufanya hili sasa hivi, niambie —
tunaweza kupanga njia mbadala (mfano: kuajiri mtu wa muda kwa kazi hii moja,
au kutumia huduma za CI kujenga ISO kiotomatiki baadaye).
