#!/bin/sh
# Uhuru OS v17.1 - AWAMU ZA 7, 8 NA 9 KWA PAMOJA (kisakinishi + Uhuru Dev Edition + ulinzi). Inahitaji v16.1 kwenye repo.
#
# AWAMU YA 7 - KISAKINISHI (Calamares): Calamares, grub signed, firmware na microcode zilikuwepo tayari kwenye ISO; hapa tunaongeza
#   kinachokosekana kwa usakinishaji kamili: cryptsetup-initramfs (usimbaji wa diski LUKS), shim-signed (Secure Boot), lvm2, btrfs, xfs,
#   gparted, timeshift (snapshots), accountsservice (login screen yenye orodha ya watumiaji KWENYE MFUMO ULIOSAKINISHWA tu).
#   Chapa ya Uhuru (nembo, rangi, slideshow ya Kiswahili), kisakinishi kisichohitaji mtandao, uhuru-installer (ukaguzi wa awali: diski, RAM,
#   UEFI/BIOS), huduma ya usafi wa mara ya kwanza, na kuingia kwenye vipendwa vya Start menu. Kila badiliko la Calamares linakaguliwa na
#   linarudishwa likiharibu YAML; kisakinishi kikipoteza chapa kinarudi kwenye 'debian' ili kisikwame.
#
# AWAMU YA 8 - UHURU DEV EDITION: zsh (mapendekezo, rangi, fzf, zoxide), tmux, neovim, F12 terminali ya kushuka, git/gh/node/python/gcc,
#   mnyororo wa ujenzi wa Uhuru (live-build, debootstrap, xorriso), uhuru-dev, msaada, uhuru-workspace (diski ya kudumu ya kazi), kundi la
#   "Zana za Msanidi" kwenye LGT Store.
#
# AWAMU YA 9 - ULINZI: ngome ya moto (nftables; wasifu 'umma' na 'nyumbani'), AppArmor, kernel iliyoimarishwa (sysctl), faragha ya Wi-Fi,
#   sasisho za usalama za kiotomatiki (mfumo uliosakinishwa tu), cups-browsed imefungwa, Uhuru Flash Safe (virus vya shortcut/autorun,
#   karantini, ClamAV hiari), uhuru-sign (saini ed25519), Kituo cha Ulinzi (GTK, Kiswahili), taarifa ya usalama, SBOM.
#
# CI: telemetry inaripoti UHURU-P7/P8/P9; e2e-verdict.sh inaongeza CHECK 3 (P7) + 4 (P8) + 7 (P9); picha 22, 23, 24.
# Hook mpya: 9995 (awamu 8), 9996 (awamu 7), 9997 (awamu 9). Hakuna cha awamu ya 3-6.1 kinachobadilishwa isipokuwa kuongeza.
# Endesha ndani ya ~/uhuru-os-repo:   sh apply-v17_1.sh
set -e
T=config/includes.chroot/usr/local/sbin/uhuru-ci-telemetry
V=scripts/e2e-verdict.sh
B=scripts/boot-screens.sh
INC=config/includes.chroot
[ -d config/hooks/live ] || { echo "ERROR: endesha ndani ya ~/uhuru-os-repo"; exit 1; }
[ -f config/hooks/live/9994-uhuru-phase61.hook.chroot ] || { echo "ERROR: v16.1 haipo kwenye repo."; exit 1; }
[ -f "$T" ] && grep -q '^p4check()' "$T" && grep -q '^p6check()' "$T" || { echo "ERROR: telemetry ya v16.x haipo."; exit 1; }
[ -f "$V" ] && [ -f "$B" ] || { echo "ERROR: scripts/e2e-verdict.sh au boot-screens.sh haipo."; exit 1; }
if [ -e config/hooks/live/9995-uhuru-phase8.hook.chroot ] || [ -e config/hooks/live/9996-uhuru-phase7.hook.chroot ]; then
    echo "ERROR: awamu ya 7/8/9 inaonekana tayari imewekwa (labda ulishaendesha apply-v17_0.sh)."
    echo "       Kama hujafanya 'git commit', rudisha kwanza:  git reset --hard HEAD   kisha endesha tena."
    exit 1
fi
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 inahitajika (pkg install python)."; exit 1; }
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
STAGE="$W/stage"
put() { mkdir -p "$STAGE/$(dirname "$1")"; cat > "$STAGE/$1"; }

put "$INC/etc/NetworkManager/conf.d/90-uhuru-privacy.conf" <<'UHURU_P179_EOF'
# Uhuru OS awamu ya 9: faragha ya mtandao (MAC ya Wi-Fi isiyofuatilika, anwani za IPv6 za muda)
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
ethernet.cloned-mac-address=preserve
ipv6.ip6-privacy=2
UHURU_P179_EOF

put "$INC/etc/apt/apt.conf.d/52uhuru-security-updates" <<'UHURU_P179_EOF'
// Uhuru OS awamu ya 9: sasisho za usalama za kiotomatiki (Debian Security pekee). Zinaendeshwa kwenye mfumo ULIOSAKINISHWA;
// kwenye live session zimezimwa (angalia apt-daily*.service.d) ili RAM na mtandao visitumike bila sababu.
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "false";
UHURU_P179_EOF

put "$INC/etc/sysctl.d/90-uhuru-hardening.conf" <<'UHURU_P179_EOF'
# Uhuru OS awamu ya 9: kuimarisha kernel na mtandao (haivunji vyombo, podman wala Chromium)
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
kernel.yama.ptrace_scope = 1
kernel.sysrq = 176
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_regular = 2
fs.protected_fifos = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
UHURU_P179_EOF

put "$INC/etc/systemd/system/accounts-daemon.service.d/uhuru-live.conf" <<'UHURU_P179_EOF'
# Uhuru OS: kwenye live session AccountsService haianzi (login screen inabaki na kisanduku cha jina, kama ilivyojaribiwa);
# kwenye mfumo uliosakinishwa inafanya kazi na login screen inaonyesha orodha ya watumiaji.
[Unit]
ConditionKernelCommandLine=!boot=live
UHURU_P179_EOF

put "$INC/etc/systemd/system/apt-daily-upgrade.service.d/uhuru-live.conf" <<'UHURU_P179_EOF'
# Uhuru OS: sasisho za kiotomatiki hazifanyi kazi kwenye live session (hazihifadhiwi na zinakula RAM)
[Unit]
ConditionKernelCommandLine=!boot=live
UHURU_P179_EOF

put "$INC/etc/systemd/system/apt-daily.service.d/uhuru-live.conf" <<'UHURU_P179_EOF'
# Uhuru OS: sasisho za kiotomatiki hazifanyi kazi kwenye live session (hazihifadhiwi na zinakula RAM)
[Unit]
ConditionKernelCommandLine=!boot=live
UHURU_P179_EOF

put "$INC/etc/systemd/system/uhuru-firstboot.service" <<'UHURU_P179_EOF'
[Unit]
Description=Uhuru OS: usafi wa mara ya kwanza baada ya usakinishaji
ConditionKernelCommandLine=!boot=live
ConditionPathExists=!/var/lib/uhuru-firstboot.done
After=local-fs.target
Before=display-manager.service lightdm.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/uhuru-firstboot

[Install]
WantedBy=multi-user.target
UHURU_P179_EOF

put "$INC/etc/uhuru-store/catalog.d/20-dev.json" <<'UHURU_P179_EOF'
{
  "categories": [
    {"id": "dev", "name": "Zana za Msanidi", "icon": "utilities-terminal-symbolic",
     "fallback_icon": "applications-development",
     "desc": "Zana za ziada za ujenzi: mashine pepe, hifadhidata, uhariri wa msimbo na simu za Android. Zana za msingi (git, node, python, gcc) tayari ziko kwenye mfumo; angalia kwa: uhuru-dev doctor."}
  ],
  "apps": [
    {"id": "virt-manager", "type": "apt", "name": "Virt-Manager", "category": "dev",
     "summary": "Tengeneza na uendeshe mashine pepe (KVM/QEMU) kwa kuonyesha kwa michoro.",
     "package": "virt-manager", "desktop": "virt-manager.desktop", "icon": "virt-manager", "keywords": "vm qemu kvm mashine pepe virtualbox"},
    {"id": "sqlitebrowser", "type": "apt", "name": "DB Browser for SQLite", "category": "dev",
     "summary": "Tazama na uhariri hifadhidata za SQLite kwa meza na maswali.",
     "package": "sqlitebrowser", "desktop": "sqlitebrowser.desktop", "icon": "sqlitebrowser", "keywords": "sqlite database hifadhidata sql"},
    {"id": "meld", "type": "apt", "name": "Meld", "category": "dev",
     "summary": "Linganisha mafaili na folda, na utatue migongano ya git kwa macho.",
     "package": "meld", "desktop": "org.gnome.meld.desktop", "icon": "org.gnome.meld", "keywords": "diff linganisha merge git"},
    {"id": "gvim", "type": "apt", "name": "Vim (GTK)", "category": "dev",
     "summary": "Kihariri chenye nguvu cha msimbo chenye dirisha lake, kwa wapenzi wa Vim.",
     "package": "vim-gtk3", "desktop": "gvim.desktop", "icon": "gvim", "keywords": "vim editor msimbo"},
    {"id": "emacs", "type": "apt", "name": "Emacs", "category": "dev",
     "summary": "Mazingira makubwa ya kuhariri na kupanga kazi, yanayoweza kupanuliwa bila mwisho.",
     "package": "emacs", "desktop": "emacs.desktop", "icon": "emacs", "keywords": "emacs editor msimbo"},
    {"id": "scrcpy", "type": "apt", "name": "scrcpy", "category": "dev",
     "summary": "Onyesha na udhibiti simu ya Android kwenye kompyuta kupitia USB.",
     "package": "scrcpy", "desktop": "scrcpy.desktop", "icon": "scrcpy", "keywords": "android simu adb skrini"},
    {"id": "ghex", "type": "apt", "name": "GHex", "category": "dev",
     "summary": "Hariri mafaili ya binary kwa mtazamo wa hexadecimal.",
     "package": "ghex", "desktop": "org.gnome.GHex.desktop", "icon": "org.gnome.GHex", "keywords": "hex binary"}
  ]
}
UHURU_P179_EOF

put "$INC/etc/xdg/autostart/uhuru-phase8-init.desktop" <<'UHURU_P179_EOF'
[Desktop Entry]
Type=Application
Name=Uhuru Phase 8 init
Exec=/usr/local/bin/uhuru-phase8-init
OnlyShowIn=XFCE;
NoDisplay=true
X-GNOME-Autostart-enabled=true
UHURU_P179_EOF

put "$INC/etc/xdg/autostart/uhuru-usbwatch.desktop" <<'UHURU_P179_EOF'
[Desktop Entry]
Type=Application
Name=Uhuru Flash Safe
Exec=/usr/local/bin/uhuru-usbwatch
OnlyShowIn=XFCE;
NoDisplay=true
X-GNOME-Autostart-enabled=true
UHURU_P179_EOF

put "$INC/usr/local/bin/msaada" <<'UHURU_P179_EOF'
#!/bin/bash
# msaada - mwongozo wa haraka wa Uhuru Dev Edition (Kiswahili)
Y=$'\033[1;33m'; C=$'\033[36m'; D=$'\033[2m'; B=$'\033[1m'; N=$'\033[0m'
row() { printf '  %s%-22s%s %s\n' "$C" "$1" "$N" "$2"; }
head_() { printf '\n%s%s%s\n' "$Y" "$1" "$N"; }
printf '%sUhuru OS - Mwongozo wa Msanidi%s  %s(andika "msaada" wakati wowote)%s\n' "$B" "$N" "$D" "$N"
head_ "KIBODI NA MADIRISHA"
row "Super (Windows)" "Start menu"
row "Ctrl+Alt+T" "terminali mpya"
row "F12" "terminali ya kushuka (juu ya skrini)"
row "Alt+Tab" "badilisha dirisha"
head_ "TERMINALI (zsh)"
row "mshale wa kulia (â†’)" "kubali pendekezo la kijivu"
row "mshale juu/chini" "tafuta historia kwa herufi ulizoanza kuandika"
row "Ctrl+R" "tafuta kwenye historia nzima (fzf)"
row "Ctrl+T" "chagua faili (fzf)"
row "Alt+C" "ingia kwenye folda (fzf)"
row "z jina" "nenda kwenye folda uliyotembelea (zoxide)"
row "mkcd folda" "tengeneza folda na uingie"
row "extract faili" "fungua zip, tar, 7z, gz, xz"
row "serve [port]" "seva ya HTTP ya folda ya sasa (8000)"
row "ports" "bandari zinazosikiliza"
head_ "GIT (njia fupi)"
row "gs  ga  gc  gp  gl" "status, add, commit, push, pull"
row "gd  glog" "diff, historia ya michoro"
head_ "TMUX (skrini nyingi ndani ya terminali moja)"
row "tmux" "anza; Ctrl+b kisha:"
row "  |   -" "gawanya kulia / chini"
row "  c   n   p" "dirisha jipya / linalofuata / lililopita"
row "  d" "toka bila kuzima (rudi na: tmux a)"
head_ "NEOVIM (nvim)"
row "i  Esc" "andika / acha kuandika"
row "Space w  /  Space q" "hifadhi / toka"
row ":q!" "toka bila kuhifadhi"
head_ "ZANA ZA UHURU"
row "uhuru-dev doctor" "angalia zana zote za ujenzi"
row "uhuru-dev setup" "weka jina/barua ya git na SSH key"
row "uhuru-workspace" "diski ya kudumu ya kazi (UHURU-WORK)"
row "uhuru-store" "LGT Store: sakinisha programu zaidi"
head_ "KUJENGA UHURU OS NDANI YA UHURU OS"
row "uhuru-dev setup" "kisha: gh auth login"
row "git clone <repo>" "pakua mradi wako (mfano uhuru-os)"
row "bash scripts/ci-watch.sh vXXX" "fuatilia build ya GitHub"
head_ "LUGHA NA VYOMBO"
row "python3 -m venv .venv" "mazingira ya Python (pip ya mfumo imezuiwa na Debian)"
row "pipx install <zana>" "zana za Python zenye mazingira yake"
row "npm i -g <kifurushi>" "inaenda ~/.npm-global (bila sudo)"
row "podman run ..." "makontena bila root ('docker' inafanya kazi pia)"
row "distrobox create ..." "Ubuntu/Alpine ndani ya Uhuru"
row "adb  fastboot  scrcpy" "simu ya Android kutoka kwenye kompyuta"
printf '\n%sKumbuka:%s kabla ya kisakinishi, live session haihifadhi chochote. Tumia %suhuru-workspace%s.\n\n' "$B" "$N" "$B" "$N"
UHURU_P179_EOF

put "$INC/usr/local/bin/uhuru-dev" <<'UHURU_P179_EOF'
#!/bin/bash
# uhuru-dev - zana za msanidi za Uhuru OS (Uhuru Dev Edition)
#   uhuru-dev doctor [--ci]   kagua zana za ujenzi (--ci: mstari mmoja kwa mashine)
#   uhuru-dev setup [--yes]   weka jina/barua ya git, SSH key na mapendekezo ya git
#   uhuru-dev help
CORE_CMDS="git curl wget gcc make python3 pip3 node npm jq rg fdfind batcat fzf tmux nvim zsh btop tree rsync ssh sqlite3 shellcheck aria2c socat lb debootstrap xorriso"
OPT_CMDS="gh cmake pipx podman docker distrobox adb fastboot scrcpy zoxide exa fish tig shfmt git-lfs"

have() { command -v "$1" >/dev/null 2>&1; }

ver() {
    case "$1" in
        ssh)  ssh -V 2>&1 | head -n 1 ;;
        lb)   lb --version 2>&1 | head -n 1 ;;
        pip3) pip3 --version 2>&1 | awk '{print $1" "$2}' ;;
        make) make --version 2>&1 | head -n 1 ;;
        *)    timeout 4 "$1" --version 2>&1 | head -n 1 ;;
    esac | cut -c1-58
}

cmd_doctor() {
    local ci=0 c miss="" om="" nc=0 tc=0 no=0 to=0
    [ "$1" = "--ci" ] && ci=1
    [ "$ci" = 1 ] || printf '\n  \033[1;33mUhuru Dev\033[0m - afya ya zana za msanidi\n\n  \033[1mZana za msingi\033[0m\n'
    for c in $CORE_CMDS; do
        tc=$((tc + 1))
        if have "$c"; then
            nc=$((nc + 1))
            [ "$ci" = 1 ] || printf '   \033[32mâœ”\033[0m %-12s %s\n' "$c" "$(ver "$c")"
        else
            miss="$miss${miss:+,}$c"
            [ "$ci" = 1 ] || printf '   \033[31mâœ˜\033[0m %-12s haipo\n' "$c"
        fi
    done
    [ "$ci" = 1 ] || printf '\n  \033[1mZana za ziada\033[0m\n'
    for c in $OPT_CMDS; do
        to=$((to + 1))
        if have "$c"; then
            no=$((no + 1))
            [ "$ci" = 1 ] || printf '   \033[32mâœ”\033[0m %-12s %s\n' "$c" "$(ver "$c")"
        else
            om="$om${om:+,}$c"
            [ "$ci" = 1 ] || printf '   \033[33mâ€“\033[0m %-12s haipo (sakinisha: sudo apt install <kifurushi>)\n' "$c"
        fi
    done
    if [ "$ci" = 1 ]; then
        if [ -z "$miss" ]; then
            echo "DEV-OK coremissing=none core=$nc/$tc opt=$no/$to optmissing=${om:-none}"
        else
            echo "DEV-FAIL coremissing=$miss core=$nc/$tc opt=$no/$to optmissing=${om:-none}"
        fi
    else
        printf '\n  Msingi: %s/%s   Ziada: %s/%s\n' "$nc" "$tc" "$no" "$to"
        [ -z "$miss" ] && printf '  \033[32mZana zote za msingi zipo. Uko tayari kujenga.\033[0m\n\n' || printf '  \033[31mZinakosekana: %s\033[0m\n\n' "$miss"
    fi
    [ -z "$miss" ]
}

cmd_setup() {
    local yes=0 name email ans
    [ "$1" = "--yes" ] && yes=1
    name=$(git config --global user.name 2>/dev/null || true)
    email=$(git config --global user.email 2>/dev/null || true)
    if [ -z "$name" ]; then
        if [ "$yes" = 1 ]; then name=${GIT_NAME:-}; else read -rp "Jina lako (litaonekana kwenye git commits): " name; fi
        [ -n "$name" ] && git config --global user.name "$name"
    fi
    if [ -z "$email" ]; then
        if [ "$yes" = 1 ]; then email=${GIT_EMAIL:-}; else read -rp "Barua pepe yako (ya GitHub): " email; fi
        [ -n "$email" ] && git config --global user.email "$email"
    fi
    git config --global init.defaultBranch master
    git config --global pull.rebase false
    git config --global color.ui auto
    have nvim && git config --global core.editor nvim
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        ans=y
        [ "$yes" = 1 ] || read -rp "Tengeneza SSH key mpya (ed25519)? [Y/n] " ans
        case "${ans:-y}" in
            [Nn]*) ;;
            *) ssh-keygen -q -t ed25519 -N "" -C "${email:-uhuru}" -f "$HOME/.ssh/id_ed25519" && echo "SSH key imetengenezwa." ;;
        esac
    fi
    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        echo; echo "Public key yako (iweke GitHub > Settings > SSH and GPG keys):"; cat "$HOME/.ssh/id_ed25519.pub"
    fi
    echo
    if have gh; then
        if gh auth status >/dev/null 2>&1; then echo "gh: umeshaingia GitHub."
        else echo "Hatua inayofuata: gh auth login   (kisha: gh auth setup-git)"; fi
    fi
    echo "Kumbuka: kabla ya kisakinishi (awamu ya 7), tumia 'uhuru-workspace' kuhifadhi kazi na funguo zako."
}

case "${1:-help}" in
    doctor) shift; cmd_doctor "$@" ;;
    setup)  shift; cmd_setup "$@" ;;
    *) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
UHURU_P179_EOF

put "$INC/usr/local/bin/uhuru-installer" <<'UHURU_P179_EOF'
#!/bin/bash
# uhuru-installer - sakinisha Uhuru OS kwenye diski (Calamares, chapa ya Uhuru)
#   uhuru-installer            ukaguzi wa awali kisha kisakinishi
#   uhuru-installer --check    ukaguzi wa muundo wa kisakinishi (kwa CI; hauanzishi kisakinishi)
#   uhuru-installer --log      onyesha mahali pa log ya kisakinishi
CAL=${UHURU_CAL_DIR:-/etc/calamares}
MODDIRS=${UHURU_CAL_MODDIRS:-"/usr/lib/x86_64-linux-gnu/calamares/modules /usr/lib/calamares/modules"}
ROOT=${UHURU_ROOT:-}
have() { command -v "$1" >/dev/null 2>&1; }
pkg_ok() { dpkg-query -W -f='${db:Status-Abbrev}' "$1" 2>/dev/null | grep -q '^ii'; }

cmd_check() {
    local miss="" brand mods=0 m name found sb=ok crypt=ok fs=ok efi=no md=0 d S="$CAL/settings.conf"
    for d in $MODDIRS; do [ -d "$d" ] && md=$((md + 1)); done
    have calamares || [ -n "$UHURU_CAL_DIR" ] || miss="$miss,calamares"
    if [ ! -f "$S" ]; then
        miss="$miss,settings.conf"
    else
        brand=$(sed -n 's/^branding:[[:space:]]*//p' "$S" | head -n 1 | tr -d "\"' ")
        [ -n "$brand" ] || miss="$miss,branding-key"
        for f in branding.desc show.qml logo.png; do
            [ -f "$CAL/branding/$brand/$f" ] || miss="$miss,branding/$f"
        done
        # moduli zilizoorodheshwa kwenye 'sequence:' lazima ziwepo
        for m in $(awk '/^sequence:/{s=1; next} s && /^[A-Za-z]/{s=0} s' "$S" \
                   | sed -n 's/^[[:space:]]*-[[:space:]]\{1,\}\([A-Za-z0-9_@-]\{1,\}\)[[:space:]]*\(#.*\)\{0,1\}$/\1/p'); do
            name=${m%%@*}; mods=$((mods + 1)); found=0
            for d in $MODDIRS; do [ -d "$d/$name" ] && found=1; done
            [ "$found" = 1 ] || miss="$miss,module:$name"
        done
        [ "$mods" -ge 8 ] || miss="$miss,sequence-ndogo"
    fi
    [ -f "$ROOT/usr/lib/shim/shimx64.efi.signed" ] && [ -f "$ROOT/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed" ] || sb=no
    [ -d "$ROOT/usr/lib/grub/x86_64-efi" ] && [ -d "$ROOT/usr/lib/grub/i386-pc" ] || sb=no
    [ "$sb" = ok ] || miss="$miss,secureboot-files"
    [ -f "$ROOT/usr/share/initramfs-tools/hooks/cryptroot" ] && have cryptsetup || crypt=no
    [ "$crypt" = ok ] || miss="$miss,luks(cryptsetup-initramfs)"
    for t in mkfs.ext4 mkfs.btrfs mkfs.xfs mkfs.fat; do have "$t" || { fs=no; miss="$miss,$t"; }; done
    [ -d /sys/firmware/efi ] && efi=yes
    if [ -z "$miss" ]; then
        echo "INSTALLER-OK modules=$mods moddirs=$md brand=$brand sb=$sb crypt=$crypt fs=$fs efi=$efi"
    else
        echo "INSTALLER-FAIL missing=${miss#,} modules=$mods moddirs=$md"
        return 1
    fi
}

cmd_log() {
    local f
    for f in /root/.cache/Calamares/Calamares/Calamares.log "$HOME/.cache/Calamares/Calamares/Calamares.log" /var/log/calamares.log; do
        [ -f "$f" ] && { echo "$f"; return 0; }
    done
    echo "Log ya kisakinishi haijapatikana (haijaendeshwa bado?). Mahali pa kawaida: /root/.cache/Calamares/Calamares/Calamares.log"
    return 1
}

cmd_launch() {
    local ram mode disks live_dev live_disk xa msg
    ram=$(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo)
    mode=BIOS; [ -d /sys/firmware/efi ] && mode=UEFI
    live_dev=$(findmnt -n -o SOURCE /run/live/medium 2>/dev/null)
    live_disk=""; [ -n "$live_dev" ] && live_disk=$(lsblk -no PKNAME "$live_dev" 2>/dev/null | head -n 1)
    disks=$(lsblk -dnb -o NAME,SIZE,TYPE,MODEL 2>/dev/null | awk -v ld="$live_disk" '$3=="disk" && $2>=12000000000 && $1!=ld {printf "%s (%d GB) ", $1, $2/1000000000}')
    if [ -z "$disks" ]; then
        zenity --error --width=460 --title="Sakinisha Uhuru OS" \
            --text="Hakuna diski ya kusakinisha.\n\nUnahitaji diski yenye angalau GB 12 (diski ngumu, SSD, au diski pepe ya VM). Ongeza diski kisha ujaribu tena." 2>/dev/null
        return 1
    fi
    msg="Utasakinisha <b>Uhuru OS</b> kwenye kompyuta hii.\n\nMfumo wa kuwasha: <b>$mode</b>   â€¢   RAM: <b>${ram} MB</b>\nDiski zinazopatikana: <b>$disks</b>\n\nâ€¢ Unaweza kuchagua <b>usimbaji wa diski</b> (LUKS) kwenye hatua ya diski.\nâ€¢ Hakikisha una <b>nakala rudufu</b> ya data muhimu; kufuta diski hakurudishwi.\nâ€¢ Usizime kompyuta wakati wa usakinishaji."
    [ "$ram" -lt 1500 ] && msg="$msg\n\n<b>Onyo:</b> RAM ni ndogo (chini ya 1.5 GB); usakinishaji unaweza kuwa polepole."
    zenity --question --width=500 --title="Sakinisha Uhuru OS" --ok-label="Endelea" --cancel-label="Ghairi" --text="$msg" 2>/dev/null || return 0
    xa=${XAUTHORITY:-$HOME/.Xauthority}
    if sudo -n true 2>/dev/null; then
        exec sudo env DISPLAY="$DISPLAY" XAUTHORITY="$xa" /usr/local/sbin/uhuru-installer-run
    fi
    exec pkexec env DISPLAY="$DISPLAY" XAUTHORITY="$xa" /usr/local/sbin/uhuru-installer-run
}

case "${1:-}" in
    --check) cmd_check ;;
    --log)   cmd_log ;;
    "")      cmd_launch ;;
    *) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
UHURU_P179_EOF

put "$INC/usr/local/bin/uhuru-phase8-init" <<'UHURU_P179_EOF'
#!/bin/sh
# Uhuru OS awamu ya 8: F12 = terminali ya kushuka; unganisha diski ya kazi (UHURU-WORK) ikiwepo.
# Inaendeshwa kila login; haibadilishi mipangilio ambayo mtumiaji ameshaweka.
if command -v xfconf-query >/dev/null 2>&1; then
    i=0
    while [ "$i" -lt 15 ]; do
        xfconf-query -c xfce4-keyboard-shortcuts -l >/dev/null 2>&1 && break
        i=$((i + 1)); sleep 1
    done
    CUR=$(xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/F12 2>/dev/null || true)
    [ -n "$CUR" ] || xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/F12 -n -t string -s "xfce4-terminal --drop-down" >/dev/null 2>&1
fi
if [ -e /dev/disk/by-label/UHURU-WORK ] && command -v uhuru-workspace >/dev/null 2>&1; then
    uhuru-workspace mount >/dev/null 2>&1
fi
exit 0
UHURU_P179_EOF

put "$INC/usr/local/bin/uhuru-protect" <<'UHURU_P179_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kituo cha Ulinzi cha Uhuru OS - hali ya usalama ya kompyuta kwa muhtasari (Kiswahili).

  uhuru-protect           fungua Kituo cha Ulinzi
  uhuru-protect --check   hali ya kila kipengele kwa mstari mmoja (kwa CI; msimbo 0 = hakuna 'bad')
  uhuru-protect --smoke   jenga dirisha bila kulionyesha (kwa CI)
"""
import glob
import os
import shutil
import subprocess
import sys
import threading
import time

ROOT = os.environ.get("UHURU_PROTECT_ROOT", "")
APPLIANCE_ICON = "/usr/share/uhuru-store/icons/uhuru-store.svg"

CSS = """
window.lgt-protect { background: #f3f7f7; }
headerbar.lgt-header { background: #0b3b44; color: #ffffff; border: none; box-shadow: none; }
headerbar.lgt-header .title { color: #ffffff; font-weight: 700; }
headerbar.lgt-header .subtitle { color: #f5c518; font-size: 9pt; }
.lgt-banner-ok { background-image: linear-gradient(to right, #0b6b4a, #12a37a); border-radius: 18px; padding: 22px 26px; }
.lgt-banner-warn { background-image: linear-gradient(to right, #8a5a00, #d19a00); border-radius: 18px; padding: 22px 26px; }
.lgt-banner-bad { background-image: linear-gradient(to right, #8b1a1a, #d33a2c); border-radius: 18px; padding: 22px 26px; }
.lgt-banner-title { color: #ffffff; font-weight: 800; font-size: 20pt; }
.lgt-banner-sub { color: #ffffff; font-size: 10.5pt; }
.lgt-row { background: #ffffff; border-radius: 14px; padding: 12px 16px; border: 1px solid #dfe9e9; }
.lgt-row-title { color: #0b2f36; font-weight: 700; font-size: 11.5pt; }
.lgt-row-detail { color: #587274; font-size: 9.5pt; }
.lgt-dot-ok { color: #12a37a; font-size: 20pt; }
.lgt-dot-warn { color: #d19a00; font-size: 20pt; }
.lgt-dot-bad { color: #d33a2c; font-size: 20pt; }
.lgt-dot-info { color: #7d9496; font-size: 20pt; }
button.lgt-act { background: #f5c518; color: #0b2f36; border-radius: 999px; padding: 4px 16px; font-weight: 800; border: none; box-shadow: none; }
button.lgt-act:hover { background: #ffd43b; }
"""


def p(path):
    return ROOT + path


def run(argv, timeout=6):
    try:
        r = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, universal_newlines=True, timeout=timeout)
        return r.returncode, r.stdout.strip()
    except Exception:
        return 127, ""


def read(path, default=""):
    try:
        with open(p(path), "r", encoding="utf-8", errors="replace") as fh:
            return fh.read().strip()
    except OSError:
        return default


def pkg_installed(name):
    rc, out = run(["dpkg-query", "-W", "-f", "${db:Status-Abbrev}", name])
    return rc == 0 and out.startswith("ii")


def is_live():
    return "boot=live" in read("/proc/cmdline")


# ---- vipengele: kila kimoja kinarudisha (id, kichwa, hali, maelezo, kitendo|None) ; hali: ok | warn | info | bad
def check_firewall():
    prof = read("/etc/uhuru-firewall/profile", "none")
    rc, act = run(["systemctl", "is-active", "nftables"])
    if act == "active" and prof in ("umma", "nyumbani"):
        if prof == "umma":
            return ("fw", "Ngome ya moto", "ok", "Imewashwa - wasifu wa UMMA: hakuna kinachoingia bila ruhusa.", ("Badili kuwa NYUMBANI", "nyumbani"))
        return ("fw", "Ngome ya moto", "ok", "Imewashwa - wasifu wa NYUMBANI: kompyuta za mtandao huo zinaruhusiwa (Uhuru Share kwa LAN).", ("Badili kuwa UMMA", "umma"))
    return ("fw", "Ngome ya moto", "bad", "Haifanyi kazi (huduma=%s, wasifu=%s)." % (act or "?", prof), ("Washa (UMMA)", "umma"))


def check_apparmor():
    on = read("/sys/module/apparmor/parameters/enabled") == "Y"
    rc, act = run(["systemctl", "is-active", "apparmor"])
    if on and act == "active":
        return ("aa", "AppArmor (kufungia programu)", "ok", "Imewashwa: programu zimefungwa kwenye mipaka yake.", None)
    return ("aa", "AppArmor (kufungia programu)", "bad", "Haijawashwa (kernel=%s, huduma=%s)." % ("ndiyo" if on else "hapana", act or "?"), None)


def check_sysctl():
    want = {"/proc/sys/kernel/kptr_restrict": "2", "/proc/sys/kernel/dmesg_restrict": "1",
            "/proc/sys/net/ipv4/tcp_syncookies": "1", "/proc/sys/fs/protected_symlinks": "1",
            "/proc/sys/net/ipv4/conf/all/rp_filter": "1"}
    bad = [os.path.basename(k) for k, v in want.items() if read(k) != v]
    if not bad:
        return ("sysctl", "Kernel iliyoimarishwa", "ok", "Siri za kernel zimefichwa; mtandao unalindwa dhidi ya mashambulizi ya kawaida.", None)
    return ("sysctl", "Kernel iliyoimarishwa", "bad", "Mipangilio haijatumika: %s" % ", ".join(bad), None)


def check_updates():
    ok = pkg_installed("unattended-upgrades") and os.path.isfile(p("/etc/apt/apt.conf.d/52uhuru-security-updates"))
    if not ok:
        return ("upd", "Sasisho za usalama", "bad", "Sasisho za kiotomatiki hazijawekwa.", None)
    if is_live():
        return ("upd", "Sasisho za usalama", "ok", "Zimewekwa; zinaanza kufanya kazi kwenye mfumo uliosakinishwa (si kwenye live).", None)
    stamp = p("/var/lib/apt/periodic/unattended-upgrades-stamp")
    if os.path.isfile(stamp):
        days = int((time.time() - os.path.getmtime(stamp)) / 86400)
        return ("upd", "Sasisho za usalama", "ok" if days <= 14 else "warn", "Mara ya mwisho: siku %d zilizopita." % days, None)
    return ("upd", "Sasisho za usalama", "warn", "Zimewashwa; hazijawahi kuendeshwa bado (zinahitaji mtandao).", None)


def check_disk():
    if is_live():
        return ("disk", "Usimbaji wa diski", "info", "Live session: hakuna kinachohifadhiwa. Usimbaji (LUKS) unachaguliwa wakati wa kusakinisha.", None)
    rc, out = run(["lsblk", "-rno", "TYPE"])
    if "crypt" in out.split():
        return ("disk", "Usimbaji wa diski", "ok", "Diski imesimbwa (LUKS): data haisomeki ikiibiwa kompyuta.", None)
    return ("disk", "Usimbaji wa diski", "warn", "Diski HAIJASIMBWA. Ikiibiwa kompyuta, data inasomeka. Sakinisha upya ukichagua usimbaji.", None)


def check_secureboot():
    if not os.path.isdir(p("/sys/firmware/efi")):
        return ("sb", "Secure Boot", "info", "Kompyuta hii imewashwa kwa BIOS (si UEFI); Secure Boot haitumiki.", None)
    rc, out = run(["mokutil", "--sb-state"])
    if "enabled" in out.lower():
        return ("sb", "Secure Boot", "ok", "Imewashwa: programu za kuwasha zimethibitishwa.", None)
    return ("sb", "Secure Boot", "info", "UEFI ipo lakini Secure Boot imezimwa (unaweza kuiwasha kwenye mipangilio ya BIOS).", None)


def check_flash():
    if not os.path.isfile(p("/etc/xdg/autostart/uhuru-usbwatch.desktop")):
        return ("usb", "Ulinzi wa flash", "bad", "Mlinzi wa flash hajawekwa.", None)
    rc, out = run(["pgrep", "-fc", "[u]huru-usbwatch"])
    detail = "Kila flash inayounganishwa inakaguliwa kwa virus vya shortcut na autorun."
    return ("usb", "Ulinzi wa flash", "ok", detail, ("Kagua flash sasa", "scan"))


def check_av():
    db = sorted(glob.glob(p("/var/lib/clamav/main.c[vl]d")) + glob.glob(p("/var/lib/clamav/daily.c[vl]d")))
    if not shutil.which("clamscan") and not os.path.exists(p("/usr/bin/clamscan")):
        return ("av", "Antivirus (ClamAV)", "warn", "ClamAV haijasakinishwa.", None)
    if not db:
        return ("av", "Antivirus (ClamAV)", "warn", "Hifadhidata ya virusi haijapakuliwa (inahitaji mtandao mara moja).", ("Sasisha sasa", "avupdate"))
    days = int((time.time() - max(os.path.getmtime(f) for f in db)) / 86400)
    if days > 14:
        return ("av", "Antivirus (ClamAV)", "warn", "Hifadhidata ina siku %d; sasisha." % days, ("Sasisha sasa", "avupdate"))
    return ("av", "Antivirus (ClamAV)", "ok", "Hifadhidata ni mpya (siku %d)." % days, None)


def check_privacy():
    if os.path.isfile(p("/etc/NetworkManager/conf.d/90-uhuru-privacy.conf")):
        return ("nm", "Faragha ya mtandao", "ok", "MAC ya Wi-Fi haifuatiliki; anwani za IPv6 za muda zinatumika.", None)
    return ("nm", "Faragha ya mtandao", "bad", "Mipangilio ya faragha haijawekwa.", None)


CHECKS = [check_firewall, check_apparmor, check_sysctl, check_updates, check_disk, check_secureboot,
          check_flash, check_av, check_privacy]


def collect():
    out = []
    for fn in CHECKS:
        try:
            out.append(fn())
        except Exception as exc:  # kipengele kimoja kisiangushe kituo kizima
            out.append((fn.__name__, fn.__name__, "bad", "Hitilafu: %s" % exc, None))
    return out


def summary(items):
    cnt = {"ok": 0, "warn": 0, "info": 0, "bad": 0}
    for it in items:
        cnt[it[2]] += 1
    return cnt


def cmd_check():
    items = collect()
    cnt = summary(items)
    toks = ",".join("%s=%s" % (it[0], it[2]) for it in items)
    head = "PROTECT-OK" if cnt["bad"] == 0 else "PROTECT-FAIL"
    print("%s n=%d ok=%d warn=%d info=%d bad=%d %s" % (head, len(items), cnt["ok"], cnt["warn"], cnt["info"], cnt["bad"], toks))
    return 0 if cnt["bad"] == 0 else 1


def priv(argv):
    return argv if os.geteuid() == 0 else ["pkexec"] + argv


def do_action(code):
    if code in ("umma", "nyumbani"):
        return subprocess.call(priv(["/usr/local/sbin/uhuru-firewall", code]))
    if code == "avupdate":
        return subprocess.call(priv(["freshclam"]))
    if code == "scan":
        subprocess.Popen(["xfce4-terminal", "--hold", "-T", "Uhuru Flash Safe", "-e", "uhuru-usbscan --all"])
        return 0
    return 1


def main(argv):
    if "--check" in argv:
        return cmd_check()
    smoke = "--smoke" in argv
    try:
        import gi
        gi.require_version("Gtk", "3.0")
        gi.require_version("Gdk", "3.0")
        from gi.repository import Gtk, Gdk, GLib, Pango
    except Exception as exc:
        print("SMOKE-FAIL import %s" % str(exc).replace(" ", "_")[:60])
        return 1
    if Gdk.Display.get_default() is None:
        print("SMOKE-FAIL no-display" if smoke else "uhuru-protect: hakuna skrini (DISPLAY)")
        return 1
    GLib.set_prgname("uhuru-protect")
    GLib.set_application_name("Kituo cha Ulinzi")
    try:
        win = build_window(Gtk, Gdk, GLib, Pango)
        if smoke:
            win.get_child().show_all()
            win.realize()
            for _ in range(60):
                if not Gtk.events_pending():
                    break
                Gtk.main_iteration()
            print("SMOKE-OK rows=%d" % win.row_count())
            win.destroy()
            return 0
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        win.refresh()
        Gtk.main()
        return 0
    except Exception as exc:
        if smoke:
            import traceback
            traceback.print_exc(file=sys.stderr)
            print("SMOKE-FAIL %s" % (type(exc).__name__ + ":" + str(exc)).replace(" ", "_")[:70])
            return 1
        raise


def build_window(Gtk, Gdk, GLib, Pango):
    class ProtectWindow(Gtk.Window):
        def __init__(self):
            Gtk.Window.__init__(self, title="Kituo cha Ulinzi")
            self.set_default_size(760, 720)
            self.set_position(Gtk.WindowPosition.CENTER)
            self.get_style_context().add_class("lgt-protect")
            if os.path.isfile(APPLIANCE_ICON):
                try:
                    self.set_icon_from_file(APPLIANCE_ICON)
                except Exception:
                    pass
            prov = Gtk.CssProvider()
            prov.load_from_data(CSS.encode("utf-8"))
            screen = Gdk.Screen.get_default()
            if screen is not None:
                Gtk.StyleContext.add_provider_for_screen(screen, prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            self.rows_box = None
            self._build()
            self.refresh()

        def _build(self):
            hb = Gtk.HeaderBar()
            hb.set_show_close_button(True)
            hb.get_style_context().add_class("lgt-header")
            hb.set_title("Kituo cha Ulinzi")
            hb.set_subtitle("Uhuru OS \u2022 Letema Group Tech")
            btn = Gtk.Button.new_from_icon_name("view-refresh-symbolic", Gtk.IconSize.BUTTON)
            btn.set_tooltip_text("Angalia tena")
            btn.connect("clicked", lambda _b: self.refresh())
            hb.pack_end(btn)
            self.set_titlebar(hb)
            root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
            root.set_margin_top(22)
            root.set_margin_bottom(22)
            root.set_margin_start(26)
            root.set_margin_end(26)
            self.add(root)
            self.banner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            self.banner_title = Gtk.Label(label="")
            self.banner_title.set_xalign(0)
            self.banner_title.get_style_context().add_class("lgt-banner-title")
            self.banner_sub = Gtk.Label(label="")
            self.banner_sub.set_xalign(0)
            self.banner_sub.get_style_context().add_class("lgt-banner-sub")
            self.banner.pack_start(self.banner_title, False, False, 0)
            self.banner.pack_start(self.banner_sub, False, False, 0)
            root.pack_start(self.banner, False, False, 0)
            scroll = Gtk.ScrolledWindow()
            scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            self.rows_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
            scroll.add(self.rows_box)
            root.pack_start(scroll, True, True, 0)
            self._rows = 0

        def row_count(self):
            return self._rows

        def refresh(self):
            for child in self.rows_box.get_children():
                self.rows_box.remove(child)
            items = collect()
            cnt = summary(items)
            ctx = self.banner.get_style_context()
            for cls in ("lgt-banner-ok", "lgt-banner-warn", "lgt-banner-bad"):
                ctx.remove_class(cls)
            if cnt["bad"]:
                ctx.add_class("lgt-banner-bad")
                self.banner_title.set_text("Kuna hatari")
                self.banner_sub.set_text("Vipengele %d vinahitaji hatua ya haraka." % cnt["bad"])
            elif cnt["warn"]:
                ctx.add_class("lgt-banner-warn")
                self.banner_title.set_text("Angalia")
                self.banner_sub.set_text("Mfumo uko salama, lakini mambo %d yanaweza kuboreshwa." % cnt["warn"])
            else:
                ctx.add_class("lgt-banner-ok")
                self.banner_title.set_text("Umelindwa")
                self.banner_sub.set_text("Hakuna tatizo la usalama lililopatikana.")
            self._rows = 0
            for ident, title, state, detail, action in items:
                row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
                row.get_style_context().add_class("lgt-row")
                dot = Gtk.Label(label="\u25cf")
                dot.get_style_context().add_class("lgt-dot-" + state)
                row.pack_start(dot, False, False, 0)
                txt = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
                t = Gtk.Label(label=title)
                t.set_xalign(0)
                t.get_style_context().add_class("lgt-row-title")
                d = Gtk.Label(label=detail)
                d.set_xalign(0)
                d.set_line_wrap(True)
                d.set_max_width_chars(70)
                d.get_style_context().add_class("lgt-row-detail")
                txt.pack_start(t, False, False, 0)
                txt.pack_start(d, False, False, 0)
                row.pack_start(txt, True, True, 0)
                if action:
                    b = Gtk.Button(label=action[0])
                    b.get_style_context().add_class("lgt-act")
                    b.set_valign(Gtk.Align.CENTER)
                    b.connect("clicked", self.on_action, action[1])
                    row.pack_end(b, False, False, 0)
                self.rows_box.pack_start(row, False, False, 0)
                self._rows += 1
            self.rows_box.show_all()

        def on_action(self, _btn, code):
            def worker():
                do_action(code)
                GLib.idle_add(self.refresh)
            threading.Thread(target=worker, daemon=True).start()

    return ProtectWindow()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
UHURU_P179_EOF

put "$INC/usr/local/bin/uhuru-shell" <<'UHURU_P179_EOF'
#!/bin/sh
# Uhuru Terminal inaanza na shell hii: zsh (chaguo-msingi), au ile uliyochagua kwenye ~/.config/uhuru/shell (zsh|bash|fish).
# Ikiwa shell uliyochagua haifanyi kazi, inarudi kwenye bash ili terminali isifungwe kamwe.
pick=""
[ -r "$HOME/.config/uhuru/shell" ] && pick=$(head -n 1 "$HOME/.config/uhuru/shell" | tr -dc 'a-z')
[ -n "$UHURU_SHELL" ] && pick=$UHURU_SHELL
for s in $pick zsh bash sh; do
    p=$(command -v "$s" 2>/dev/null) || continue
    [ -x "$p" ] || continue
    if [ "$s" = zsh ] && ! "$p" -ic true </dev/null >/dev/null 2>&1; then continue; fi
    if [ "$1" = "--print" ]; then echo "$s"; exit 0; fi
    exec "$p"
done
exec /bin/sh
UHURU_P179_EOF

put "$INC/usr/local/bin/uhuru-sign" <<'UHURU_P179_EOF'
#!/bin/sh
# uhuru-sign - saini ya kidijitali (ed25519, openssl) ya faili na vifurushi, ili masasisho ya nje ya mtandao yasighushiwe.
#   uhuru-sign keygen [jina]            tengeneza jozi ya funguo (~/.config/uhuru/sign/<jina>.key na .pub)
#   uhuru-sign sign <faili> [funguo]    tengeneza <faili>.sig
#   uhuru-sign verify <faili> [pub]     thibitisha saini (msimbo 0 = sahihi)
#   uhuru-sign --selftest               jaribio la ndani (CI)
KD=${UHURU_SIGN_DIR:-$HOME/.config/uhuru/sign}

keygen() {
    name=${1:-default}
    mkdir -p "$KD" && chmod 700 "$KD"
    [ -f "$KD/$name.key" ] && { echo "Funguo '$name' zipo tayari: $KD/$name.key"; return 1; }
    openssl genpkey -algorithm ed25519 -out "$KD/$name.key" 2>/dev/null && chmod 600 "$KD/$name.key" || return 1
    openssl pkey -in "$KD/$name.key" -pubout -out "$KD/$name.pub" 2>/dev/null || return 1
    echo "Funguo zimetengenezwa: $KD/$name.key (siri, usishiriki) na $KD/$name.pub (ya umma, inaweza kusambazwa)"
}
sign() {
    f=$1; key=${2:-$KD/default.key}
    [ -f "$f" ] && [ -f "$key" ] || { echo "faili au funguo hazipo"; return 1; }
    t=$(mktemp) || return 1
    openssl pkeyutl -sign -inkey "$key" -rawin -in "$f" -out "$t" 2>/dev/null || { rm -f "$t"; return 1; }
    openssl base64 -A -in "$t" > "$f.sig"; rm -f "$t"
    echo "Saini: $f.sig"
}
verify() {
    f=$1; pub=${2:-$KD/default.pub}
    [ -f "$f" ] && [ -f "$f.sig" ] && [ -f "$pub" ] || { echo "faili, saini au funguo ya umma hazipo"; return 2; }
    t=$(mktemp) || return 2
    openssl base64 -d -A -in "$f.sig" -out "$t" 2>/dev/null
    if openssl pkeyutl -verify -pubin -inkey "$pub" -rawin -in "$f" -sigfile "$t" >/dev/null 2>&1; then
        rm -f "$t"; echo "SAINI SAHIHI: $f"; return 0
    fi
    rm -f "$t"; echo "SAINI SI SAHIHI: $f"; return 1
}
selftest() {
    T=$(mktemp -d) || return 1
    KD="$T/k"
    echo "kifurushi cha majaribio" > "$T/pkg.bin"
    keygen t >/dev/null && sign "$T/pkg.bin" "$KD/t.key" >/dev/null || { echo "SIGN-FAIL sign"; rm -rf "$T"; return 1; }
    verify "$T/pkg.bin" "$KD/t.pub" >/dev/null || { echo "SIGN-FAIL verify"; rm -rf "$T"; return 1; }
    echo "kimeharibiwa" >> "$T/pkg.bin"
    if verify "$T/pkg.bin" "$KD/t.pub" >/dev/null; then echo "SIGN-FAIL tamper-haikugunduliwa"; rm -rf "$T"; return 1; fi
    rm -rf "$T"; echo "SIGN-OK ed25519"
}
case "$1" in
    keygen) keygen "$2" ;;
    sign) sign "$2" "$3" ;;
    verify) verify "$2" "$3" ;;
    --selftest) selftest ;;
    *) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
UHURU_P179_EOF

put "$INC/usr/local/bin/uhuru-usbscan" <<'UHURU_P179_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""uhuru-usbscan - Uhuru Flash Safe: ukaguzi na usafi wa flash/diski za nje (virus vya "shortcut", autorun, faili za kujificha).

  uhuru-usbscan <folda>           ripoti ya Kiswahili            --json  ripoti kwa mashine    --count  idadi ya hatari
  uhuru-usbscan <folda> --clean   hamisha faili hatari kwenye ~/Uhuru-Quarantine na ufunue folda zilizofichwa
  uhuru-usbscan <folda> --deep    pia tumia ClamAV (ikiwa hifadhidata ya virusi ipo)
  uhuru-usbscan --all             kagua flash zote zilizounganishwa
  uhuru-usbscan --update          sasisha hifadhidata ya ClamAV (inahitaji mtandao)
  uhuru-usbscan --selftest        jaribio la ndani (CI)
"""
import array
import fcntl
import glob
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import time

SCRIPT_EXT = {".scr", ".vbs", ".vbe", ".wsf", ".pif", ".hta", ".cmd", ".bat", ".com"}
DOC_EXT = {".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".jpg", ".jpeg", ".png", ".gif",
           ".txt", ".mp3", ".mp4", ".mkv", ".zip", ".rar", ".odt", ".ods"}
LNK_BAD = [b"cmd.exe", b"wscript", b"cscript", b"powershell", b"rundll32", b"mshta", b"regsvr32",
           b".vbs", b".vbe", b".bat", b".cmd", b".js"]
MAX_FILES = 20000
FAT_GET = 0x80047210
FAT_SET = 0x40047211
HIDDEN_BITS = 0x06  # hidden | system


def _fat_attrs(path):
    try:
        fd = os.open(path, os.O_RDONLY)
    except OSError:
        return None
    try:
        buf = array.array("I", [0])
        fcntl.ioctl(fd, FAT_GET, buf, True)
        return buf[0]
    except OSError:
        return None
    finally:
        os.close(fd)


def _fat_unhide(path):
    attrs = _fat_attrs(path)
    if attrs is None or not (attrs & HIDDEN_BITS):
        return False
    try:
        fd = os.open(path, os.O_RDONLY)
        try:
            fcntl.ioctl(fd, FAT_SET, struct.pack("I", attrs & ~HIDDEN_BITS))
        finally:
            os.close(fd)
        return True
    except OSError:
        return False


def _lnk_suspicious(path):
    try:
        if os.path.getsize(path) > 20000:
            return False
        with open(path, "rb") as fh:
            data = fh.read(20000).lower()
    except OSError:
        return False
    return any(pat in data for pat in LNK_BAD)


def scan(root):
    """Inarudisha orodha ya matokeo: dict(path, rel, kind, severity, reason)."""
    root = os.path.abspath(root)
    found = []

    def add(path, kind, sev, reason):
        found.append({"path": path, "rel": os.path.relpath(path, root), "kind": kind, "severity": sev, "reason": reason})

    try:
        top = sorted(os.scandir(root), key=lambda e: e.name.lower())
    except OSError:
        return found
    names = {e.name.lower() for e in top}
    dirs = {e.name.lower() for e in top if e.is_dir(follow_symlinks=False)}
    for e in top:
        n, low = e.name, e.name.lower()
        base, ext = os.path.splitext(low)
        if e.is_dir(follow_symlinks=False):
            a = _fat_attrs(e.path)
            if a is not None and a & HIDDEN_BITS:
                add(e.path, "folda-imefichwa", "medium", "Folda '%s' imefichwa (virus vya shortcut hufanya hivi ili uone njia-mkato za uongo tu)." % n)
            continue
        if ext == ".lnk":
            if base in dirs or (base in names and base != low):
                add(e.path, "shortcut-ya-uongo", "high", "Njia-mkato '%s' inaiga folda/faili yenye jina lile lile (dalili ya virus vya shortcut)." % n)
            elif _lnk_suspicious(e.path):
                add(e.path, "shortcut-hatari", "high", "Njia-mkato '%s' inaendesha amri za Windows (cmd/wscript/powershell)." % n)
        elif low == "autorun.inf":
            add(e.path, "autorun", "medium", "autorun.inf: faili ya kuanzisha programu kiotomatiki kwenye Windows.")
        elif ext in SCRIPT_EXT:
            add(e.path, "script-hatari", "high", "Faili ya script ya Windows '%s' kwenye mzizi wa flash." % n)
        elif ext in (".exe",):
            inner = os.path.splitext(base)[1]
            if base in dirs:
                add(e.path, "exe-inaiga-folda", "high", "Programu '%s' ina jina la folda '%s' (hila ya kuonekana kama folda)." % (n, base))
            elif inner in DOC_EXT:
                add(e.path, "jina-mbili", "high", "'%s' inajifanya kuwa hati lakini ni programu (viendelezi viwili)." % n)
            else:
                add(e.path, "exe", "low", "Programu '%s' kwenye mzizi wa flash (angalia kama unaitambua)." % n)
    # kina cha pili: viendelezi viwili na script ndani ya folda
    count = 0
    for dirpath, dirnames, filenames in os.walk(root):
        depth = os.path.relpath(dirpath, root).count(os.sep) + (0 if dirpath == root else 1)
        if depth >= 3:
            dirnames[:] = []
        if dirpath == root:
            continue
        for fn in filenames:
            count += 1
            if count > MAX_FILES:
                return found
            low = fn.lower()
            base, ext = os.path.splitext(low)
            p = os.path.join(dirpath, fn)
            if ext in (".exe", ".scr", ".vbs", ".pif", ".bat", ".cmd") and os.path.splitext(base)[1] in DOC_EXT:
                add(p, "jina-mbili", "high", "'%s' inajifanya kuwa hati lakini ni programu (viendelezi viwili)." % fn)
            elif ext == ".lnk" and _lnk_suspicious(p):
                add(p, "shortcut-hatari", "high", "Njia-mkato '%s' inaendesha amri za Windows." % fn)
            elif low == "autorun.inf":
                add(p, "autorun", "medium", "autorun.inf ndani ya folda.")
    return found


def threats(found):
    return [f for f in found if f["severity"] in ("high", "medium")]


def clean(root, found, qroot=None):
    """Hamisha faili hatari kwenye karantini (hazifutwi) na ufunue folda zilizofichwa."""
    label = os.path.basename(os.path.abspath(root)) or "flash"
    qdir = os.path.join(qroot or os.path.join(os.path.expanduser("~"), "Uhuru-Quarantine"),
                        "%s-%s" % (label, time.strftime("%Y%m%d-%H%M%S")))
    moved, unhidden, failed = [], [], []
    for f in found:
        if f["severity"] == "low":
            continue
        if f["kind"] == "folda-imefichwa":
            (unhidden if _fat_unhide(f["path"]) else failed).append(f["rel"])
            continue
        if not os.path.exists(f["path"]):
            continue
        dest = os.path.join(qdir, f["rel"])
        try:
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            shutil.move(f["path"], dest)
            moved.append(f["rel"])
        except OSError:
            failed.append(f["rel"])
    return {"quarantine": qdir if moved else "", "moved": moved, "unhidden": unhidden, "failed": failed}


def clam_db():
    for pat in ("/var/lib/clamav/main.c[vl]d", "/var/lib/clamav/daily.c[vl]d"):
        if glob.glob(pat):
            return True
    return False


def deep_scan(root):
    exe = shutil.which("clamscan")
    if not exe or not clam_db():
        return None
    try:
        out = subprocess.run([exe, "-r", "--infected", "--no-summary", "--max-filesize=50M", root],
                             stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, universal_newlines=True, timeout=900).stdout
    except Exception:
        return None
    return [ln for ln in out.splitlines() if ln.strip().endswith("FOUND")]


def mounts():
    user = os.environ.get("USER") or os.path.basename(os.path.expanduser("~"))
    res = []
    for base in ("/run/media/%s" % user, "/media/%s" % user):
        res += [d for d in sorted(glob.glob(base + "/*")) if os.path.isdir(d)]
    return res


def report(root, found, extra=None):
    th = threats(found)
    print("Flash: %s" % root)
    if not found:
        print("  Safi: hakuna dalili za virus vya shortcut, autorun wala faili zinazotia shaka.")
    for f in found:
        mark = {"high": "HATARI ", "medium": "SHAKA  ", "low": "angalia"}[f["severity"]]
        print("  [%s] %s\n            %s" % (mark, f["rel"], f["reason"]))
    if extra:
        for ln in extra:
            print("  [ClamAV] " + ln)
    if th:
        print("\n  Faili %d zinatia shaka. Safisha kwa: uhuru-usbscan \"%s\" --clean" % (len(th), root))


def selftest():
    tmp = tempfile.mkdtemp(prefix="uhuru-usb-")
    try:
        usb = os.path.join(tmp, "FLASH")
        os.makedirs(os.path.join(usb, "Picha"))
        os.makedirs(os.path.join(usb, "Kazi", "2026"))
        open(os.path.join(usb, "Picha", "safi.jpg"), "wb").write(b"jpg")
        open(os.path.join(usb, "Kazi", "2026", "ripoti.pdf.exe"), "wb").write(b"MZ")
        open(os.path.join(usb, "Picha.lnk"), "wb").write(b"L\x00\x00\x00 cmd.exe /c start Picha.exe")
        open(os.path.join(usb, "Picha.exe"), "wb").write(b"MZ")
        open(os.path.join(usb, "autorun.inf"), "w").write("[autorun]\nopen=Picha.exe\n")
        open(os.path.join(usb, "run.vbs"), "w").write("WScript.Echo 1")
        open(os.path.join(usb, "kitabu.txt"), "w").write("safi")
        found = scan(usb)
        kinds = sorted({f["kind"] for f in found})
        need = {"shortcut-ya-uongo", "exe-inaiga-folda", "autorun", "script-hatari", "jina-mbili"}
        if not need.issubset(set(kinds)):
            print("USBSCAN-FAIL kinds=%s" % ",".join(kinds))
            return 1
        if any(f["rel"] in ("kitabu.txt", os.path.join("Picha", "safi.jpg")) for f in found):
            print("USBSCAN-FAIL false-positive")
            return 1
        res = clean(usb, found, qroot=os.path.join(tmp, "Q"))
        left = [n for n in ("Picha.lnk", "Picha.exe", "autorun.inf", "run.vbs") if os.path.exists(os.path.join(usb, n))]
        safe = os.path.exists(os.path.join(usb, "kitabu.txt")) and os.path.exists(os.path.join(usb, "Picha", "safi.jpg"))
        if left or not safe or len(res["moved"]) < 5 or not os.path.isdir(res["quarantine"]):
            print("USBSCAN-FAIL clean left=%s safe=%s moved=%d" % (",".join(left), safe, len(res["moved"])))
            return 1
        if threats(scan(usb)):
            print("USBSCAN-FAIL baada-ya-usafi")
            return 1
        print("USBSCAN-OK detected=%d cleaned=%d" % (len(threats(found)), len(res["moved"])))
        return 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    flags = {a for a in argv if a.startswith("--")}
    if "--selftest" in flags:
        return selftest()
    if "--update" in flags:
        exe = shutil.which("freshclam")
        if not exe:
            print("freshclam haipo (sakinisha clamav-freshclam).")
            return 1
        cmd = [exe] if os.geteuid() == 0 else ["pkexec", exe]
        return subprocess.call(cmd)
    if "--all" in flags:
        ms = mounts()
        if not ms:
            print("Hakuna flash iliyounganishwa (/run/media/%s)." % (os.environ.get("USER", "?")))
            return 0
        for m in ms:
            report(m, scan(m))
            print()
        return 0
    if not args:
        print(__doc__)
        return 2
    root = args[0]
    if not os.path.isdir(root):
        print("Folda '%s' haipo." % root)
        return 2
    found = scan(root)
    if "--count" in flags:
        print(len(threats(found)))
        return 0
    extra = deep_scan(root) if "--deep" in flags else None
    if "--json" in flags:
        print(json.dumps({"root": root, "findings": found, "clam": extra}, ensure_ascii=False))
        return 0
    report(root, found, extra)
    if "--clean" in flags:
        res = clean(root, found)
        print("\nImehamishwa: %d  |  Imefunuliwa: %d  |  Imeshindikana: %d" % (len(res["moved"]), len(res["unhidden"]), len(res["failed"])))
        if res["quarantine"]:
            print("Karantini: %s (faili hazijafutwa; unaweza kuzikagua au kuzifuta mwenyewe)" % res["quarantine"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
UHURU_P179_EOF

put "$INC/usr/local/bin/uhuru-usbwatch" <<'UHURU_P179_EOF'
#!/bin/sh
# Uhuru Flash Safe: inaangalia flash/diski za nje zinapounganishwa (/run/media/$USER) na kuzikagua mara moja.
# Mount zilizokuwepo wakati wa login hazikaguliwi tena (hazikuulizi); zile mpya zinakaguliwa ndani ya sekunde chache.
U=$(id -un)
SEEN=$(mktemp)
trap 'rm -f "$SEEN"' EXIT
notify() {
    if command -v notify-send >/dev/null 2>&1; then notify-send -i dialog-information "$1" "$2"
    else zenity --info --no-wrap --timeout=8 --title="$1" --text="$2" 2>/dev/null; fi
}
mark_existing() { for d in /run/media/"$U"/* /media/"$U"/*; do [ -d "$d" ] && echo "$d" >> "$SEEN"; done; }
handle() {
    d=$1; name=$(basename "$d")
    n=$(uhuru-usbscan "$d" --count 2>/dev/null || echo 0)
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    if [ "$n" -gt 0 ]; then
        if zenity --question --width=480 --title="Uhuru Flash Safe" --ok-label="Safisha sasa" --cancel-label="Baadaye" \
            --text="Flash <b>$name</b> ina faili <b>$n</b> zinazotia shaka (kawaida za virus vya \"shortcut\").\n\nSafisha sasa? Faili hatari zitahamishiwa <b>~/Uhuru-Quarantine</b> (hazifutwi) na folda zako zilizofichwa zitafunuliwa." 2>/dev/null; then
            uhuru-usbscan "$d" --clean >/dev/null 2>&1
            notify "Uhuru Flash Safe" "Flash '$name' imesafishwa."
        fi
    else
        notify "Uhuru Flash Safe" "Flash '$name' ni safi."
    fi
}
mark_existing
while :; do
    for d in /run/media/"$U"/* /media/"$U"/*; do
        [ -d "$d" ] || continue
        grep -qxF "$d" "$SEEN" && continue
        echo "$d" >> "$SEEN"
        sleep 2
        handle "$d"
    done
    sleep 3
done
UHURU_P179_EOF

put "$INC/usr/local/bin/uhuru-workspace" <<'UHURU_P179_EOF'
#!/bin/bash
# uhuru-workspace - diski ya kudumu ya kazi (label UHURU-WORK), ili kazi, funguo za SSH na mipangilio ya git visipotee
# kwenye live session. Kazi zako zinaonekana kwenye ~/work.
#   uhuru-workspace status [--ci]     hali ya diski
#   uhuru-workspace init <kifaa>      tengeneza diski mpya (ext4) - inafuta data iliyopo
#   uhuru-workspace mount             unganisha, tengeneza ~/work na viungo vya .ssh, .gitconfig, gh
LABEL=UHURU-WORK
DEV="/dev/disk/by-label/$LABEL"
LINK="$HOME/work"
ITEMS=".ssh .gitconfig .config/gh .zsh_history .bash_history .config/uhuru/shell .npmrc"

mnt_point() { findmnt -rn -S "LABEL=$LABEL" -o TARGET 2>/dev/null | head -n 1; }

link_home() {
    local H=$1 it src dst
    for it in $ITEMS; do
        src="$HOME/$it"; dst="$H/$it"
        mkdir -p "$(dirname "$dst")" "$(dirname "$src")"
        if [ -e "$dst" ]; then
            [ -L "$src" ] && [ "$(readlink "$src")" = "$dst" ] && continue
            [ -e "$src" ] && [ ! -L "$src" ] && mv "$src" "$src.uhuru-bak"
            ln -sfn "$dst" "$src"
        elif [ -e "$src" ] && [ ! -L "$src" ]; then
            mv "$src" "$dst" && ln -sfn "$dst" "$src"
        fi
    done
    chmod 700 "$H/.ssh" 2>/dev/null
    return 0
}

cmd_status() {
    local mp
    if [ ! -e "$DEV" ]; then echo "WS-NONE hakuna-diski-yenye-label-$LABEL"; return 0; fi
    mp=$(mnt_point)
    if [ -n "$mp" ]; then echo "WS-MOUNTED $mp"; else echo "WS-FOUND haijaunganishwa"; fi
}

cmd_mount() {
    local mp
    [ -e "$DEV" ] || { echo "Diski yenye label $LABEL haipatikani. Tumia: uhuru-workspace init <kifaa>"; return 1; }
    mp=$(mnt_point)
    if [ -z "$mp" ]; then
        udisksctl mount -b "$(readlink -f "$DEV")" >/dev/null 2>&1
        mp=$(mnt_point)
    fi
    [ -n "$mp" ] || { echo "Imeshindikana kuunganisha diski."; return 1; }
    if ! mkdir -p "$mp/work" "$mp/.home" 2>/dev/null; then
        echo "Huna ruhusa kwenye diski. Endesha: sudo chown $USER:$USER \"$mp\""; return 1
    fi
    ln -sfn "$mp/work" "$LINK"
    link_home "$mp/.home"
    echo "Tayari: ~/work -> $mp/work (funguo na mipangilio vinahifadhiwa kwenye diski hii)"
}

cmd_init() {
    local dev=$1 ans mp
    [ -b "$dev" ] || { echo "Kifaa '$dev' si kifaa cha block. Mfano: uhuru-workspace init /dev/vdb"; return 1; }
    if findmnt -rn -S "$dev" >/dev/null 2>&1; then echo "Kifaa kimeunganishwa tayari; kitoe kwanza."; return 1; fi
    if [ -n "$(lsblk -no FSTYPE "$dev" 2>/dev/null | tr -d ' \n')" ]; then
        echo "ONYO: $dev tayari ina mfumo wa mafaili; data yote itafutwa."
    fi
    read -rp "Andika YES kutengeneza diski ya kazi kwenye $dev: " ans
    [ "$ans" = "YES" ] || { echo "Imeghairiwa."; return 1; }
    sudo mkfs.ext4 -F -L "$LABEL" -m 0 "$dev" >/dev/null || return 1
    sleep 1
    udisksctl mount -b "$dev" >/dev/null 2>&1
    mp=$(mnt_point)
    [ -n "$mp" ] && sudo chown "$USER:$USER" "$mp"
    cmd_mount
}

case "${1:-status}" in
    status) cmd_status ;;
    mount)  cmd_mount ;;
    init)   cmd_init "$2" ;;
    *) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
UHURU_P179_EOF

put "$INC/usr/local/sbin/uhuru-firewall" <<'UHURU_P179_EOF'
#!/bin/bash
# uhuru-firewall - ngome ya moto ya Uhuru OS (nftables). Inabana kila kinachoingia isipokuwa majibu ya muunganisho wako.
#   uhuru-firewall status [--ci]   hali na wasifu wa sasa
#   uhuru-firewall umma            wasifu mkali (cafe, shule, mtandao wa pamoja)  [chaguo-msingi]
#   uhuru-firewall nyumbani        ruhusu kompyuta za mtandao wa nyumbani/ofisi (kwa Uhuru Share kupitia LAN)
#   uhuru-firewall allow <bandari>/<tcp|udp>   fungua bandari moja     (deny: ifunge tena; list: orodha)
DIR=${UHURU_FW_DIR:-/etc/uhuru-firewall}
TPL=${UHURU_FW_TPL:-/usr/share/uhuru-firewall}
NFTCONF=${UHURU_FW_CONF:-/etc/nftables.conf}

die() { echo "uhuru-firewall: $*" >&2; exit 1; }
need_root() { [ "$(id -u)" = 0 ] || die "inahitaji root (tumia: pkexec uhuru-firewall $*)"; }
profile() { cat "$DIR/profile" 2>/dev/null || echo none; }

custom_rules() {
    local proto port
    [ -f "$DIR/custom-ports.conf" ] || return 0
    while read -r proto port _; do
        case "$proto" in tcp|udp) ;; *) continue ;; esac
        case "$port" in ''|*[!0-9]*) continue ;; esac
        printf '        %s dport %s accept\n' "$proto" "$port"
    done < "$DIR/custom-ports.conf"
}

regen() {   # regen <wasifu>: tengeneza active.nft + nftables.conf (haitumii kwa kernel)
    local p=$1 rules
    [ -f "$TPL/$p.tpl" ] || die "wasifu '$p' haupo"
    mkdir -p "$DIR"
    rules=$(custom_rules)
    awk -v r="$rules" '/#CUSTOM#/ { if (r != "") print r; next } { print }' "$TPL/$p.tpl" > "$DIR/active.nft.new" || die "imeshindikana kutengeneza sheria"
    mv -f "$DIR/active.nft.new" "$DIR/active.nft"
    echo "$p" > "$DIR/profile"
    cat > "$NFTCONF" <<NFT
#!/usr/sbin/nft -f
# Uhuru OS: inatengenezwa na uhuru-firewall. Wasifu: $p
table inet uhuru
delete table inet uhuru
include "$DIR/active.nft"
NFT
}

apply() {
    command -v nft >/dev/null 2>&1 || die "nft haipo"
    nft -c -f "$NFTCONF" || die "sheria zina kosa; hazijatumika (ngome ya awali bado inafanya kazi)"
    nft -f "$NFTCONF" || die "imeshindikana kutumia sheria"
    systemctl enable nftables >/dev/null 2>&1 || true
}

cmd_status() {
    local act pol p
    act=$(systemctl is-active nftables 2>/dev/null); p=$(profile)
    pol="n/a"
    if [ "$(id -u)" = 0 ] && command -v nft >/dev/null 2>&1; then
        nft list chain inet uhuru input 2>/dev/null | grep -q 'policy drop' && pol=drop || pol=none
    fi
    if [ "$1" = "--ci" ]; then
        if [ "$act" = active ] && { [ "$pol" = drop ] || [ "$pol" = "n/a" ]; } && { [ "$p" = umma ] || [ "$p" = nyumbani ]; }; then
            echo "FW-OK profile=$p policy=$pol"
        else
            echo "FW-FAIL service=${act:-none} profile=$p policy=$pol"; return 1
        fi
    else
        echo "Ngome ya moto: huduma=${act:-haijulikani}  wasifu=$p  sera=$pol"
        case "$p" in
            umma)     echo "  Wasifu wa UMMA: hakuna kinachoingia bila ruhusa (salama kwa cafe na mitandao ya pamoja)." ;;
            nyumbani) echo "  Wasifu wa NYUMBANI: kompyuta za mtandao huo zinaruhusiwa (Uhuru Share kupitia LAN inafanya kazi)." ;;
        esac
        [ -s "$DIR/custom-ports.conf" ] && { echo "  Bandari zilizofunguliwa:"; sed 's/^/    /' "$DIR/custom-ports.conf"; }
    fi
}

setprofile() { need_root "$1"; regen "$1" && apply && echo "Wasifu wa ngome ya moto: $1"; }

cmd_allow() {
    local spec=$1 port proto
    need_root allow "$spec"
    port=${spec%%/*}; proto=${spec##*/}
    case "$port" in ''|*[!0-9]*) die "bandari si sahihi: $spec" ;; esac
    case "$proto" in tcp|udp) ;; *) die "tumia muundo: 8080/tcp" ;; esac
    mkdir -p "$DIR"
    grep -qx "$proto $port" "$DIR/custom-ports.conf" 2>/dev/null || echo "$proto $port" >> "$DIR/custom-ports.conf"
    regen "$(profile | grep -E '^(umma|nyumbani)$' || echo umma)" && apply && echo "Bandari $port/$proto imefunguliwa."
}

cmd_deny() {
    local spec=$1 port proto
    need_root deny "$spec"
    port=${spec%%/*}; proto=${spec##*/}
    [ -f "$DIR/custom-ports.conf" ] && sed -i "/^$proto $port\$/d" "$DIR/custom-ports.conf"
    regen "$(profile | grep -E '^(umma|nyumbani)$' || echo umma)" && apply && echo "Bandari $port/$proto imefungwa."
}

case "${1:-status}" in
    status)   cmd_status "$2" ;;
    umma)     setprofile umma ;;
    nyumbani) setprofile nyumbani ;;
    allow)    cmd_allow "$2" ;;
    deny)     cmd_deny "$2" ;;
    list)     cat "$DIR/custom-ports.conf" 2>/dev/null ;;
    regen)    need_root regen; regen "${2:-umma}" ;;
    *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
UHURU_P179_EOF

put "$INC/usr/local/sbin/uhuru-firstboot" <<'UHURU_P179_EOF'
#!/bin/sh
# Uhuru OS: usafi wa mara ya kwanza kwenye mfumo ULIOSAKINISHWA (haiendeshwi kwenye live). Haivunji boot.
LOG=/var/log/uhuru-firstboot.log
{
    echo "uhuru-firstboot: $(date -u +%FT%TZ)"
    rm -f /etc/lightdm/lightdm.conf.d/60-uhuru-live-autologin.conf
    [ -f /etc/lightdm/lightdm.conf ] && sed -i -E 's/^[[:space:]]*(autologin-user(-timeout)?=mtumiaji.*)$/#\1/' /etc/lightdm/lightdm.conf
    touch /var/lib/uhuru-setup.done
    [ -x /usr/local/sbin/uhuru-locale-setup ] && /usr/local/sbin/uhuru-locale-setup
    echo "uhuru-firstboot: tayari"
} >> "$LOG" 2>&1
touch /var/lib/uhuru-firstboot.done
exit 0
UHURU_P179_EOF

put "$INC/usr/local/sbin/uhuru-installer-run" <<'UHURU_P179_EOF'
#!/bin/sh
# (root) inahakikisha chapa ya kisakinishi ipo, kisha inaanzisha Calamares. Chapa ikikosekana inarudi kwenye 'debian' ili kisakinishi kisikwame.
S=/etc/calamares/settings.conf
b=$(sed -n 's/^branding:[[:space:]]*//p' "$S" 2>/dev/null | head -n 1 | tr -d "\"' ")
if [ -n "$b" ] && [ "$b" != debian ] && [ ! -f "/etc/calamares/branding/$b/branding.desc" ]; then
    sed -i 's/^branding:.*/branding: debian/' "$S"
fi
[ -n "$DISPLAY" ] && export QT_QPA_PLATFORM=xcb
exec calamares "$@"
UHURU_P179_EOF

put "$INC/usr/share/applications/uhuru-dev-doctor.desktop" <<'UHURU_P179_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Uhuru Dev: Afya ya zana
Name[sw]=Uhuru Dev: Afya ya zana
Comment=Angalia zana zote za ujenzi (git, node, python, gcc, n.k.)
Comment[sw]=Angalia zana zote za ujenzi (git, node, python, gcc, n.k.)
Exec=bash -c "uhuru-dev doctor; echo; read -rp 'Bonyeza Enter kufunga... ' _"
Icon=utilities-terminal
Terminal=true
Categories=Development;
UHURU_P179_EOF

put "$INC/usr/share/applications/uhuru-dev-setup.desktop" <<'UHURU_P179_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Uhuru Dev: Weka git na SSH
Name[sw]=Uhuru Dev: Weka git na SSH
Comment=Jina na barua ya git, SSH key na mapendekezo
Comment[sw]=Jina na barua ya git, SSH key na mapendekezo
Exec=bash -c "uhuru-dev setup; echo; read -rp 'Bonyeza Enter kufunga... ' _"
Icon=preferences-system
Terminal=true
Categories=Development;
UHURU_P179_EOF

put "$INC/usr/share/applications/uhuru-flash-safe.desktop" <<'UHURU_P179_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Chunguza Flash
Name[sw]=Chunguza Flash
Comment=Kagua flash zilizounganishwa kwa virus vya shortcut na autorun
Comment[sw]=Kagua flash zilizounganishwa kwa virus vya shortcut na autorun
Exec=bash -c "uhuru-usbscan --all; echo; read -rp 'Bonyeza Enter kufunga... ' _"
Icon=drive-removable-media
Terminal=true
Categories=System;Security;
UHURU_P179_EOF

put "$INC/usr/share/applications/uhuru-installer.desktop" <<'UHURU_P179_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Sakinisha Uhuru OS
Name[sw]=Sakinisha Uhuru OS
GenericName=Install Uhuru OS
Comment=Sakinisha Uhuru OS kwenye diski ya kompyuta hii
Comment[sw]=Sakinisha Uhuru OS kwenye diski ya kompyuta hii
Exec=uhuru-installer
Icon=/usr/share/uhuru-store/icons/uhuru-installer.svg
Terminal=false
Categories=System;Settings;
Keywords=install;sakinisha;usakinishaji;disk;diski;
UHURU_P179_EOF

put "$INC/usr/share/applications/uhuru-msaada.desktop" <<'UHURU_P179_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Mwongozo wa Msanidi
Name[sw]=Mwongozo wa Msanidi
Comment=Njia fupi za kibodi, terminali, git, tmux na zana za Uhuru
Comment[sw]=Njia fupi za kibodi, terminali, git, tmux na zana za Uhuru
Exec=bash -c "msaada | less -R"
Icon=help-browser
Terminal=true
Categories=Development;
UHURU_P179_EOF

put "$INC/usr/share/applications/uhuru-protect.desktop" <<'UHURU_P179_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Kituo cha Ulinzi
Name[sw]=Kituo cha Ulinzi
GenericName=Security Center
Comment=Hali ya usalama: ngome ya moto, sasisho, usimbaji wa diski, ulinzi wa flash
Comment[sw]=Hali ya usalama: ngome ya moto, sasisho, usimbaji wa diski, ulinzi wa flash
Exec=uhuru-protect
Icon=security-high
Terminal=false
Categories=System;Settings;Security;
Keywords=usalama;ulinzi;firewall;ngome;virus;antivirus;security;
UHURU_P179_EOF

put "$INC/usr/share/applications/uhuru-usalama.desktop" <<'UHURU_P179_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Taarifa ya Usalama na Faragha
Name[sw]=Taarifa ya Usalama na Faragha
Comment=Tunachokilinda, tunachokifanya, na tusichokifanya kamwe
Comment[sw]=Tunachokilinda, tunachokifanya, na tusichokifanya kamwe
Exec=bash -c "less /usr/share/doc/uhuru/USALAMA.md"
Icon=help-about
Terminal=true
Categories=System;Security;
UHURU_P179_EOF

put "$INC/usr/share/doc/uhuru/USALAMA.md" <<'UHURU_P179_EOF'
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
UHURU_P179_EOF

put "$INC/usr/share/uhuru-firewall/nyumbani.tpl" <<'UHURU_P179_EOF'
# Uhuru OS firewall - wasifu: nyumbani (mtandao wa nyumbani/ofisi unaoamini) - kompyuta za mtandao huo zinaruhusiwa (Uhuru Share kwa LAN)
table inet uhuru {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state established,related accept
        ct state invalid drop
        iifname "lo" accept
        icmp type { echo-request, destination-unreachable, time-exceeded, parameter-problem } limit rate 10/second accept
        icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
        udp sport 67 udp dport 68 accept
        udp sport 547 udp dport 546 accept
        ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16 } accept
        ip6 saddr { fe80::/10, fc00::/7 } accept
        #CUSTOM#
    }
}
UHURU_P179_EOF

put "$INC/usr/share/uhuru-firewall/umma.tpl" <<'UHURU_P179_EOF'
# Uhuru OS firewall - wasifu: umma (cafe, shule, mtandao wa pamoja) - hakuna kinachoingia bila ruhusa
table inet uhuru {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state established,related accept
        ct state invalid drop
        iifname "lo" accept
        icmp type { echo-request, destination-unreachable, time-exceeded, parameter-problem } limit rate 10/second accept
        icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
        udp sport 67 udp dport 68 accept
        udp sport 547 udp dport 546 accept
        #CUSTOM#
    }
}
UHURU_P179_EOF

put "$INC/usr/share/uhuru-phase7/branding/uhuru/branding.desc" <<'UHURU_P179_EOF'
---
componentName: uhuru

strings:
    productName:         Uhuru OS
    shortProductName:    Uhuru
    version:             1.0
    shortVersion:        1.0
    versionedName:       Uhuru OS 1.0
    shortVersionedName:  Uhuru 1.0
    bootloaderEntryName: Uhuru
    productUrl:          https://letemagrouptech.lsicbusiness.online
    supportUrl:          https://letemagrouptech.lsicbusiness.online
    knownIssuesUrl:      https://letemagrouptech.lsicbusiness.online
    releaseNotesUrl:     https://letemagrouptech.lsicbusiness.online

images:
    productLogo:         "logo.png"
    productIcon:         "logo.png"

slideshow:               "show.qml"
slideshowAPI:            1

style:
    sidebarBackground:    "#0b2f36"
    sidebarText:          "#eaf6f6"
    sidebarTextSelect:    "#0b2f36"
    sidebarTextHighlight: "#f5c518"
UHURU_P179_EOF

put "$INC/usr/share/uhuru-phase7/branding/uhuru/logo.png" <<'UHURU_P179_EOF'
‰PNG

   IHDR   €   €   “®½ˆ    cHRM  z&  €„  ú   €è  u0  ê`  :˜  pœºQ<   bKGDÿÿÿÿÿÿ	X÷Ü   tIMEê&1Íäw   &·IDATxÚíg\TÇ×Ç»,°ôª‚)¢"Ö¿bC¢ÆØÅ®Ø£Æ¨ØbO¢kì-jì`{kbP± *¡Ø@¥——v÷y1wŸ|br÷.Û.÷ûf>ÃÌœ93Ü9wvîÌ€ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ£ªÀc[ŠQ\|çN‚Á$fÿ„nÁ$ô¼EBïpúŒ'aİ¹$¬M•s^LB*İd-	Ëç°ğf-%áÛ¾\FÂ¤-$LHÂÔÖ$L?CÂ<?‘¨]»d×Ùî/Õp ’A¸í,k4›„A£I8põ÷lë©	õIx"ˆ„Wç“0~11ØÖ°ºÃ C8o‰ùl&a_êM;»	]ØÖÓ0dN áºk$<Ó„IÄ@(¦³­aU‡3 z†ø:£Hl$5ëÉ¶^ÆÁw|†o"á5gtg tè&ïH¬ë"®§Şèõç³­_ÕàÅO$œ•GÂ+‰a(·f[3c…3 B¼eI-²íÔÛ›ıı³ü—‚¶À‹íïj˜6î?Mı |
Üzgşˆ–¤\Ú¾ym’¾?óõ/i´ôô´•6šÌùì^©àpÅŠ/ß©o-&Q†!â1o¾'ŒÎ ¨	ğÂû$6¾	·èJ~vñ^~$p÷jÒ—æCãG¢‹€Ë[ã’-„l·^{ºKü¿—¼wè]œ´ÿÖ÷FI'À¾µÈR~_×µMÙKÂ½µˆAö`»ı•Î Ğ@<ŠI¬?µš}ê¶r³Å?óO¿Íy’d9XİûB†mk «S¡­ †íV—v6dõ€¹Ç{ÙÄ }2›~ vn–Áò<]Õ2àk^NÙnwe3 Ÿ@¾¯rUú	ë/­¨yOE†QÉB_`eô¹Şvk€èû)»…NúÓ¿Õq/‘T4Šq·/Ô	qr//\vÛ$ÊÚ6yyŠ Àü¶i©‚ğ—ò~Qœä?)¦ñú%=Êlxr °ÄwÈš_Ø\pxu1[lÂú¥)ÌvÑÙ)g…vúkGÀr¯Ÿ¥o€ÿës..Ğ&Ïûéy€×™‹çšJ}±‡„ızCXC-0ª½øçâİ<)	Ã<**§ôI¹îg—>‰šßÜ>0ØÑSwznhVô Šõ›'éøU»fic Ör{Èv±İ‹ÀÛ9Ö‚àÙïééfS«õ–YœÜ»õÑª¥îêÙ6aô­œD`àÕV§Šƒ ^Ïw4•¶ø	Ww «A¨¶€üzÔº{Ièğ½ºåå‡ß¡7pÜ.:Sd
L{Pàø@s}š§zü"]L¾Õ%L|h÷»OxÉÀy³M¼¼=Û½¥=ŠÆŠghœífYØawmŒõ@ vÇ«3Â¹šËİ¼aTaN+`èˆÖÅ'5•’Kí lÓ›‚¿t¶¶SÙ©v€ü¡$±±¢åÿ|ÿ¼«ù0`H“->.¼ylÆ[´‘×V¸.É‹¶Rÿà7æMÄE¶{ÇğHìKòºçw<2³| ,L9.°on”üÉÿ«âòm™z!³3ğù†oJökªÕÈëÄúœíşÑ7UŞ oº†Ä¶N!áD‘ºåÓ½s½›I÷÷…:…1¾)Ï…æê×ß}ª”ä0¿G÷ü­€_m·ğ² jÀ2¶{§òòÌ;}¥éÀ*ÉyÛñÀÅ²§	–˜	H½¥EÀÏÆöÏ^¸{:˜Ë¾ª¨»¨™ÁÔGÄ ”…²İ/º¦Ê 2ğ>Ø]úJ˜Ê)²Ñ^@øªÛ.VåÀœƒ‡Mê×;Ğ¤URq;`A¿Ş·ógµ·;Jd:ü\]yÛ"']ğXÑã\™İ/@ä®ûkDgÕ/¿6yxÏÜ DÔşP‘Àà0^ª[:‘š	´]JAnG¶ûCWT9@¾G9‰½¨[.;Hüÿ(ÒkÇçdàáŠ—ª±¸ÖêŠ—‹´Ø”’œ3ğêïQ¾€í^¨ú¤\Îo²„Û:nb†¥”ùÌåZÌ©[&„¿œ<9«àô³uùÈŠÖîÙŠ‚—:ßÁ`hªŒ ßo‰ÅoV·\´sr}¡Ğ›·¾³«Xıú_6+ÓèÔ¸wÉ]¶[_)ƒ<àFĞss?`Ğó-_¸ª_üÜóY@kGïBéãŠVŞ(„‚„¶»ASÔ°™•2ğ›,!1õş¾;7OZÍSàwîø£¸ğêĞFŞÛÜÀ¯4˜B ĞñFƒÔ’xàÕÆâ·­€q›:6‡0ïÓ`ıH×\`ßÅ›V¹Å‡SÏß,¶»ASŒv@½ñ©É[|8S~ù]Åô 9œˆ¶{:\·±Vcç]díĞ’ÌX ğ¡ïŞ=nàáĞ·†%.4ÿ _Û”ïÒŠ9ÿÓNŸ‰ıåaƒ¶ç½xcyo§nm¾¥fkÙn·º ¿nK}Æ”¿l™l. ãöìšïÜ¸$‰›gáFŸßgk×²&ÀÁÌ¸ŒPÀ9Øú¤<ˆíVshKÖØBoş] üÆß\¿şzıa£é[úüİöúI
}	Ÿd…¦óKÑ[İÚêJˆ!xeÉv»™0@­êS_ŞsÚ2å/µ+_4`ÀM)®m˜¯RªÎÔŒÊ
L,J Víœ—»0#ˆÅ¶[Í¡kÊ#d-±˜_ïX¦Ã7ÀÁ^·{ZyÓç¨ï5Bšœü-ô÷Œ$@he†šêÖæ(¦¾°pNS=*ı õŸò swSş²á²±¸‡nëZ‡yà/÷Î¬•»škÍüªÉHÁ}ÌÖ6š+–MŞ×>ô‹”CB``ø¦e®5²ïdóğ«ºµİ)ÿç>”ÊG¥ŸÜI½ù'Ò¾ùåÉŠèŒòÜè|¸\#n­…+½Ü­·G‡ää ƒë´).f»•lsüçèİ"'`êbULÜ»u÷·–È€ƒK'ûeù|OŞ(\f’ş‹™	L,c»ŸRig Ô–İH›È8å_´éø<{wæ¿kôøâì–ÜÀçø'ƒ¿˜Pœìúm¼vCú|—/Å‰-À"÷íÕş…ÿU)õ<Of»ŸRéf Ô!êTVâ{¦üû›ÜÌ·šÌ}t¡Ãú|[ßŒ‘“	6¨W\Âv+9*;ÇD9S¿=å¨bãø³¡sû cÒ:¸mUWºïxêĞÑ^¶ÛYif Ô±\jÀß‹eÊ•–l.lÎ<ğ—>n—7‚øcğè€QÅ9À2¯à©yıéóÍ-=ºÂáµ&ù‘0P]é÷L¨çıÛí¬4€0ï	h×Y³ÛˆOñ}š¯çšM/iôäÀâ;À×6]†ˆW±İ.ceò.õÄ›QIíc‹T8"é³vı/®¯ì‰âû|Æ}”—Äy¬;{cİ PxRI,ŒÖÖ*Š1ÀÈÈŸû:çÓËó	¨‘TÖXÙrÈ‰¼ã Ì`‚
æáàøÔó³*j¨eîÏ€Ï¼&eÍé³‡œ"Ï§¢ÁğbfG=ÿŒËˆú‚5@ùÜ£¼¾9Ç”?<ÿöP«< ¶é«iÂ0ú|gx3â2B“Şü›˜ÍVë8ª&İù`pæâŒˆ[†ò_õ®"¼n/°b\ÁRr&Š8¢Xô_OÂú´ç¬Ó[æ6læ4;|ÍA…÷÷ÈŞ¡®Q€ó9›òÖì¶Š£êâ|Å&W Díq>ßlŞá½N@º(×I°IjıïHØß)§®1¸ Ük_"±SËh3¾C>Àä}œfÒËwºcgñ0 pïÒZ†nGu%ğßR`ÜŒµÄcéóM^¼ï•ÓT ïÉó¬šSÔøxl¨v˜ª¢2ñÀæŸiÏº˜¢ÃR„7éó}oÖ?:ÿ ` -qq™2å³Ïô_Ï™¦32¦ m/û’Á=Cw»%®ú=Ş`ëÊø4Şşù¾^ÿ”üx`/nXü×5zCÊ\¡;ğç³g?š÷>oˆÆş?”„úï8ƒÍ ¨›t¨Ë·ÓÖr‘,áÀ^[\TüãÛ¦Ë¬X¶4ûIQÏ0F‹ÂÈ–2ÙĞ—…²h¶O	¿=m^¦Š	üK[¿s¹ ”7”½Ã>&©ÛSãEï>	ü`d¦';Çô]¥OXäµQúèÔ·A›’›LÒ88C'n%Q@@™WG©Š¥¼“µcÚ‰n¨+uä}ë­w@mxÈ'±´ëòRYùR¼¦G‡wsü“^ŞÆa!«r~ ÷y£rA=_…¤æ¨¸Ãxú£ğ ¥åñ–IèÎÿ¼·B÷hĞ•ñf³ÏvÕ£O×rvq_ÀËÅåûò%†Ñšƒ£¢xÙº,(_
·h9¨x}¾³†‰Ô>VÜõ;}ék °Ş.E>I1ƒ€©qt —°0®Oüq†Ñ–ƒC[¾êã‘?†>]ys”|ªb1I[ï¯/=õf ÈÔ¥ÎJ«OkÁ¢Z&·úÒËéş…ÿYI
PûWG‘¬™¾´åàĞ-µŸ;Ö•ùİ6Î“<¦ÏõMòh¡“´ú¡Ôx¦k=õ<ÉxüqEûs…v*Ü|ÌïÕ»vşıjÉÁ¡/æÛ÷–äï¦O_¹ÿ\s»êJÉ8W¨(:7 ÄRñ¶‘X˜]¾ì1â{üC@L‡”wBÓ§ÛZX„Ë¿l÷°²%ºÖ’ƒÃ0øÅ¸M/û°É·Ø"wùwzô¾”%ÂZ@ö7âXæCDaı©ñµNWúéiàÃxœ÷·OR-§Ñ§/4ønŞ S„
øyçà¨TLBgˆ²ÁiyOé³ı~ì‰Ìr’ºB}~Ò•zz2 ıİt¯ÎºpÜ¶+}z7‘ÿ{‰)“ã »¹ºÄŒ>}uÀ…d[F¿WJúêì«€ÀlÚk³Ç‹cø@Ö€B7Á½§7â±Eº°Zv“so~*‚m±e[yĞ|‚Goé¸Í¼_xKd-~ÈüS`6ãAcuÑ™ ¿Ml'’˜í9©{ùIß˜«Ø8ùi—õâê°µ—£Z2¹¨K¸ø$}ú=»ä%æŒ÷¸v§ÆÛ×Úê£ã@#ÆÅ‰c£W‹jĞ§·ûÍç`	w¹&G¥İ_>—K¾¥O?~2ê¸È^]i¦j«@íİ|ò)Š!\îwÒBEım¶È{èV+Ê‚s_›£rk_—
âf[¸òoC™7ĞV€AwèR2oü!ø‹¾ä¨‹í/%˜€N†÷‹ÂÁa ¾&_µF=h»(‘>[æã‚{‚LÂ†1å`Bk@~‹º˜í)Ï·¼s1mB/'èc£’/µÕ†ƒÃ8*j´Q¢b¦ûüÌû¦~LRõ¤Æß MõĞÑÀş/¦÷#SŸU\åé7ÁÍ¿t£n´áà¨ìøsó+İDŸ~ÿiJ†ğ‰ºÒì_iª‡€£7[‡Oš§Ò§»Œ´$×ÙÇÊËÛª÷[ï™'ª+Í­¦zèÈ xÒïü{ˆ—Ñf)7…Vô„ãL¯(T8ıäà¨J‡šüª°¥O^2Kè®®4Ï?ÕÍù):2 ŞgèRÊÊ¶â4}ÉV1^u¤¥ jÁ2İhÃÁQé©	;È€€I^aR­İ}xï×´¤€Ïº”w¤3ùıèK6Jp¯YªÂ«*GU¦ÑwÇR­ı\øŒÑ´¤@]Z÷Şâó%µy*ózLrª[^ª-88Œ:!NnåZ_^÷[MKêÈ ÔM—RT,ı‚¿–¾¤s„Í+YİhÁÁal¸„Ú\“uÒVJm]âëÈ 8/¡Kùh+İÏëF_ÒFjQ,o¥-88Œë‡/äíµ•â¼HÓ’:2 6éRJÃË³y*¾gš?2å)8ï¾Õó#¦
­¯ç±ÖxAGÀ„v’/OTìƒŠ€`ÿ "u£‡±ÁÊ[‚óÚJ1ÕøR<€ò9´ôå-Â¯ô%e»åó¡ñ6ãF«Ø/´•R®ñ=Ø:2 …´n…KL*Ò—”,«ÅÓz”ƒÃ8)iZ&çñ´•"Ş¡iI€¬éR,Ó…C*®ú*JDüûºÑ‚ƒÃØ(JDüm¥d.Ö´¤ÀÛ£t)V¥ÂSò¹*T)¬+¸«-88Œ¬…ÿå¯b¤íÖ´¤ÀË•t)VÌ_(BéK¾ş%ûµ‰
g‰U™W»²_jÿü§j|!º@ò.ºK?árù9ú’ñMÓ2ÍöêF‹ªŒò‹ĞûeÑ:Ô7M~]µ—SÕ‰÷OË0c¼.œ‰ä•š–Ô‘HN—bÚS0*ÜDÿ•rXè à=ò!Ğ6Uñç%ñ|Fgë•ñĞ’·|­lõ±f&W0ŞFQ‰x‡<€›”{B‘¶Â’ºiZRG µ5mR3x áµXú^‚ô`Ywçœ–Gßy›6b[‹
èùÎ×úZ™mUœÖ^¡î+ëÊSáú. ¹×XiºÒRëkª‡@ú!¦í};•¨¸43¢ğ?•IJõåÄ©±èÛZT^}íl,{ÊØnµúd†à§Ğ§öğı²Ä[]iéû5ÕCG Ñ•GË ¯ÚR—'ü’gÊ$¥ú’Ü6cšéï@nP‘Œ¯öR†G©ŸR_CaŸ,z${¦½C‘°+ı©Ùúô–A>RµgPynšê¡µ‰ÚµûğAvŠÄâ?Ğåk0¤frY<½œ«æñÓ-øÀè
A ßQ±İpõH¼Å·jÁv«+~Êş7ó3)‚*»*Tı¼7SëMY“”„zÔøûMS=tìü$í–`—f¶me*~©ìv»»•€¸#röÕ¾Ï}Ä%†«o¥ôü7vaÀ|AS¶[ÿ7J}”úŠÿïs˜Â•íÄ°ö¾İÓJÅß%À6PæË$ìDe»è*íç@şVŞœ º+ü—IT¸@ÊºTÂ¿¢[­ôIïÏ“üª½œŠ2 xÓ	—®@Y¬ìN°×~eıJ}[ı¯)Yw
'ğ/Ñ§w{í?C’ù÷xQÍµ5L9˜Ğ±ˆ_Á”cğ˜Ö£‹U¬nŞiœÔÓ\ëf¦›=¼JYØÉ˜qÖô0éÊŞN‡o”õ)ëWêchØêM¹Ó6)Ø|5}úY­¿.ÎRWZÜmõÑ™ ¿E
–“XF2]¾6ï°ƒv8\k¬+­ô…Âô¶"’ÙzD3—ëÉ-…ÙÔŒ>dl¸ê¯>¥|e}Êú²¿•ıo,ì¨}m²µŠ}1mxŞ?•0^›iI·UÚê£§ëÁ×=§KqÚjİL¸¸Ú4ıÇÍ'±Ë_E u?Æñ-ô£>˜Ò¼K¨øGíåhŠòÜØA’›ØPûw…Í.@\GR‹¥¹\ey¥<¥|¶ŞøJØîïŠR úx‡oÄ}µNøİ¿Ó3m¬dÍ §íÖÍå#™¤­ÕÙV­}‘ü7g’píEÇsSz5/¸Ì±:üÜÁáßé—â[H€APëGIÒ ÖíAYĞlFpiğèğë¡ÆÚ´G¹·çaÀ;ÙuKÙ$`Ğ€VÖÅÍ€úÁµËâë£æµåcÿŞ¹§ÜÀ£üŸ,Éèg:˜íŞı›fÃë„KO6º=(3¢UÿË¶q~ åÿ>OÒ«sÁŸ Ôzé¦+½´>‰ü)ä®2uK°œVÑì©âGüp áñy¿¸ÿ‡G3Û67åV@Òë6¥½ğ5ºÃ¥¡O¾9bæ t¾êV+íåqü“+›ç~(šılXi.ÛÚ¨Áv\…àó|Îî5‚cıø’g{6`õø´€ÓëÌ3 şNò@1Y[õtş€Rl:‰-¾F—OùS  ­×$é,zÜ“tà	>é+MĞµ–úCù`ŸĞ¶ Hë4J”ıi4Ÿ"¡VúÓ%ô?ÀÔ««´Pİ¿ø©®¾=­(‰8Ê”cÁâ>/óULhV=;/µÓYsÇş ÛüŸÙÖ¢ê`¬ı¹êæ¹l»)ôéöô)ÎWûEqP×úéÍ KõšrTğb)]¾Öû½I_ÒË¹öÔß¢!ğ¶IÎ[ãÎ¨Êƒ]˜åvùàÂ…9Ï2ØÖÆxQöŸ²?…·ms2O€Kq-êÑçk}Îû‚4™IÚ‹ï¨ñ´N×zêy dÖkZ¨ÛÜGoËQñ^ñÙ¹—vû£­.iÕÊóºÔXŞmPh^&ÛÚÊşRöŸ±±ÂóÜUÏëÖ‚Ñs> üí¼£Ìû7féíÉ1¸Â¸A¨oJ‹õÅiôé‘Ñ÷ŠN ©v™»L4¾=¾ŠøÜW\„†t_pI{yUeÿ(ûËØHfn3YD^¾¿W¤Âİ}_´ˆ(~©®Ô+Ëõ¥¯Ş ™º”×$±I´_Í
LfÃØ,Ù–Óƒ^^hëğæ ”¢\÷ß0ôÏ¢œ¾9Cğ)ÊşPöÑA=3–‡sTñºÛl²3ç@(5™Æ3|“~¦Æ³¾Ô6Ğ@IÄV¦mZ½)VqW`tlÊ^¡p=êù3óv†Õ^'ìÇDd‹ÖõmQĞ€ûi l¿²?”ıcl\¿ôüy ½&e¶Ğ>ß@y«Åj?·úÖÛ`€X²·Il
íäÎ$UPc€cs¦îÏTáèhğÀ-;\Ş Ï—Nä©ØZYÙQNu«Ûb¡²½Æ:ÕWòñÒi¼şÀàñ[º¼¢ÏwlÇÔß3;&>Í$uJ,5^ô~ÊÁÀ3 %{3åø|dÃô’}@À^Û¤*—¥œö¶3"WYt(»şš¸i¨zû”íQ¶ÏX÷>eÙûÓ~v*.¾	XáµCúø< áÃµßç{æµ_ÑdÇ`ÊGĞ©§tùÒëäÖlšI÷pû‰^^äæĞ Œ?À¡¾¤^lµJ÷(wÎ:2Ñş"û[ŒÕE¹ewMëa»ò¾0¾<LÜZ–¸MøŞº)ÁUÅí¾\Ã®§ÏÜâÉ=^&oşÓ§Õ– ¨½QÏ©UÎú´Ç;ÂmoGY‰€ÙÂÃéå&4^u$íà|Õ&OÀVëôÇóæéÿ3	l½¶Éú;à˜KÔ!«Jà~[y:OyHGy6¢ª‘Õ½Ğ‘ø=š?Ä}}¾µÃææ£xí;1na±Œ„f`8—8,ıP®	(>ôc|„G¦·_[ä
4¿ä&U±5¸ŸïÆî®kòÛòø‰Iªñ¡X[0ª]®/½=å8;læéŒ.Àää.­×ëŞU™RR¾²>eıJ}ªêÀ/¿&ÂZ ŸÍÆ ×ôùš/ó#]„|lÿs‘Úk÷ızzà+©4ÒÈŒ`ÑkL—/{„ø6ÿ0ĞğÊ¼Ãî*îC­L/z
ü”>,2×€LŒÂe”,}ÈŞlÈñ0¹|¼Z:•×(>Sr7õ3ï¤X÷·{íÏf:¾*oXœ4k¡¸Å¶ö,B}ŞûöË#32€OoÉ¬şGŸıY«ÕıÓVN¬»Ê‡1	_|•üå¬Íá*™0¡œ…eP_ÈÆĞåÚ“œ$lôY°~ƒë[z¹Ë<(o09³Ëçbo¤ä¨êü\~í´õ<à‡Z‘WìĞç;wjÖšŒ@ëöŞVRÆË>s©-o®|ê;¿Æ^}µ…µŸ ŸBuD-ks˜)ëñŞ>Ò;À—¡a¹½èó}Èö'€ã¿FŸÙ±İJcáøÓè›"+æ¿¦öĞU¹=ÕøJÚô`{à+©4@	é˜¿(çZ#0åßÁ¡h;0şF§B±
SÇ¸âhœ9òğËŞLR9ª+gÖ<œjÙ˜tà¨£}¾ñ›;Å‹Ûcv°)Rû”âÈÔó¯n	}Sé€ÒQ‡(Ÿg»Ş3å_n>¨{^!Ğm€D…¡‰¡{²œ ÇE90Iå¨.¿}^dL\»Gî¤ÂÇa·?ı‡Krå­MÈS{Çâ.êÿ¡™l·óS*­ø'S©uåDÚƒ•üº¼\öÅM|œş÷Z‰3Üq´vô¿–n=@d•gE„Cï”“ÿ÷×î[Ï¦8ğ»£-}ö€¼¶HßûNŒÍŠ ø¼Q¸ÌTI"åÉbj¥uto4<Y$txEb9u˜òKQ†w@°É&wW Æ!%FÕ-¬£®´¿T”¬z<Ä.w;`2Zğ•Î^shKù>Yslæ“9L¶¸İÎJÅ­{™Kå@dŸĞQ€ğ£É\¸«[›#õæÏmÂv»é0’€ò'A®‰y2:3Âd1j§—Ïx™±èöÈ‚DÅ”í`Wr3Q§ÕË÷ÕŒ²f6áWçÏ_UŒ¬Õâüë@Ç å³kşÊ<ğ»ú/’¼NßŸa•±£¢ßÓ¹²|%F3ø2#ğ£®ÉŒßÁ”_á ¸…À"Å‰?ìm€İ¦×3¬Ÿ0×Ù$Ô$óxÅws‰Û­æ¨(·Z'N4Ï‚S7™¸4gÎ?>­“…¸°üá ¼R€ß†7jßYÙhø	Øn·º­PBAjoÖãê–Û·ôæR«%À¼mG3ö2çw¶cxğıÛşçò“ËÁfû‘Ìå8ËÇ³¥x€eOO´«ìõº±ßZÿÓê…C=rÇ cgt˜[´¬¢µ6=@ş“1l·¿¢½PBÍBH,^mç‰Qüdwac Óú>®ùê×wB6mw¦Ğ1£¤ä ªóNCÖC ×ç› ƒ}·,vaüfô7çKg]Î°ò½“¥ş8×hõÆßÃv7hJ•1 Jˆ!¨û‰¥¾V·\ö8qÿÒzÇQçTàáâ—¥Â_˜Ëµ:àe*U ›JCrs¦ ^}]ÂËw/phKJdæ“•@¨}xÇm@ÌĞ‰P­+ê
¥_á—&÷ÍòœNXw’¯híVdà¿4†;kTRå€ê«Á}»{•„¾ó™Ê)^áø á…·‡Yås‚G;ˆ˜JıMğ†–‹¿şÒ§(2Pûº£ƒ¬)Û½aü¼Î)Ä+Vó´ÛD¶¿ßGtMıòk7wÏ-B:´¿SdğjáW0zãU’HíÕo»•ZÜ«¯nÉÊN•5 Jˆ!0¥Nl¥¼ÍMl©nù´²\KÁ`rì¾™N?1½Sò„õëï~·1_ò ˜ïÓÛ$'àwÈmHÙ* ÃÑFÿşĞ7ñæ@Bİôå¦? «îœÏµ›\šş´…¿úbZ­ó*‘ò¡cÏşpËux/û¦¢Êì¢LÄÔ3dà—}Ëv÷èš*o >…„Ôo¶ˆq-ÿçİgMÍC€!ı¶¶u¹QñúmFY´”7 VÔ¬È{ôm×"æãs@èg²C¡7×•—ò2OlNY?˜'Z,L>.°o‘ÄòŸW\Ş±;Óâ2ÛŸû4¸UÂx¢„‘aÔÎ½ï4•`,T; „‚zuI,ê	í?ª-àW<†%pTµ]ô0}ÜAÇšëÓ|™ÇXé
`ò».;Å§€vO}~-™8Ÿ±y/oÍvoiOVHa]ş]àN›¤`óÕÀ†×fX÷b¿Z!Ôâê·Íá£9-€!5['?xq¾.<÷:	Û, öêkqŸ²qQm€’CKÂ°•#;&OÆtàÔÃû}E«oöèèè[Q)ôŒş6°™øí7»¤/Ğ°­›Cév ö,ÇW²¶l÷"Ö/w·à—ö•ÙràjPÂ6óÓÀ-·â­Ûk/_É¶àÑs’€şgşw©ø(`ò^'›t,¦œn®ö¨,§óMµ7 ŸB‚/åŸ÷Ì9Ög\<ü¹‰â2>¢.%ç€•OÎ°[D¯J™)¬­?ı[¥y5•~]v–~ÔéçäX.\6ÚÄÉÚ6ï->(ZæWM?*ø o›â4 ÿQ1™×(éXfÎS …Î'^49¥°¡à6ğúhöS ¾CšØl7Ó1å½ĞTíåõ½ô=° IŸÓùsÖy?”>ø?òvCcy/¾'a¿/É€Ol£©¤ªg h |Xÿ¹$<Å¸ã‰\ß¢,ş7À…‹ÿ°<¬z!ß6 È|YøDğŒíV—gY`î‰^ÑÀ—7štÿ¸pZa]_>JWµèHÂÓ¿S®·*ğ]§jÃ 5!AH}NGmùÙ¤+ù9_…òî>úëœù\àØÅè³";àrÃ¸U`q°Ûÿ’`Hß€àâ< §Ï¾’HÀé©õ0ù íåÿ“)Ô9Ğ½¯É€—v`»ı•Î h1–Ô¯ï‘ƒI¸“Ññ³¦d¦ÆóŸ	ñiÁf«ûÉ©ùÂÇÀ­ôÄxó zOÊÂZ†ï‡€@¯¯¥Y@ »o£’†@K_OiS [pÙU ÆpÛİ2µ·ciÊ¤}$ŒØC]¨qÇğ=aœp@GP‹‰9$Ö•ú­¹r`^©fR9ş‰ò7ü,jÑöÊ
jñÎ•mÍŒÎ èbê,&±‘ãIæÁ¶^Ær•>â0è¯·±­QUƒ3 †µ˜èCyŠéK:˜Cy5tIb[OÃA-²®£áœCÂ¤2àŞ»ÇQ18PÉ Â–ZKğ§®öè²›„ƒ(ÿ´~jŸPg—3˜NÂkÔ<n!àß³­au‡3 F1êŞdû—$tABOêEŸ_IèM½Q=©ëİÇĞ™º‚Íf"	M¨³åTşÂ]$Ì¢NÆ§Q›jS©+Ü’)?¸IÔ-…©ÔmŒé;I˜GyÄ‘c»¿8888888888888888888888888888ªÿ³¥l·ëƒ“    IEND®B`‚UHURU_P179_EOF

put "$INC/usr/share/uhuru-phase7/branding/uhuru/show.qml" <<'UHURU_P179_EOF'
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 7000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b3b44"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Karibu Uhuru OS"; color: "#f5c518"; font.pixelSize: 34; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Mfumo wako, uhuru wako."; color: "#eaf6f6"; font.pixelSize: 18 }
            }
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b3b44"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Salama kwa msingi"; color: "#f5c518"; font.pixelSize: 30; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Ngome ya moto, ulinzi wa flash na sasisho za usalama."; color: "#eaf6f6"; font.pixelSize: 16 }
            }
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b3b44"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Tayari kwa kazi"; color: "#f5c518"; font.pixelSize: 30; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "LGT Store, TraceTZ Hub na zana za msanidi."; color: "#eaf6f6"; font.pixelSize: 16 }
            }
        }
    }
}
UHURU_P179_EOF

put "$INC/usr/share/uhuru-phase7/modules/welcome.conf" <<'UHURU_P179_EOF'
---
# Uhuru OS: kisakinishi hakihitaji mtandao (offline-first); kinahitaji nafasi ya diski, RAM na ruhusa ya root.
showSupportUrl: false
showKnownIssuesUrl: false
showReleaseNotesUrl: false
requirements:
    requiredStorage: 12
    requiredRam: 1.0
    internetCheckUrl: http://example.com
    check:
        - storage
        - ram
        - power
        - root
    required:
        - storage
        - ram
        - root
UHURU_P179_EOF

put "$INC/usr/share/uhuru-phase8/skel/.config/nvim/init.lua" <<'UHURU_P179_EOF'
-- Uhuru OS - neovim: mipangilio ya msingi bila plugins (inafanya kazi bila mtandao)
local o = vim.opt
o.number = true
o.relativenumber = true
o.mouse = "a"
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.termguicolors = true
o.cursorline = true
o.scrolloff = 6
o.signcolumn = "yes"
o.updatetime = 300
o.undofile = true
o.splitright = true
o.splitbelow = true
o.wrap = false
if vim.fn.executable("xclip") == 1 or vim.fn.executable("wl-copy") == 1 then o.clipboard = "unnamedplus" end

vim.g.mapleader = " "
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<cr>", { desc = "hifadhi" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "toka" })
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "faili" })
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

if not pcall(vim.cmd, "colorscheme habamax") then pcall(vim.cmd, "colorscheme desert") end
UHURU_P179_EOF

put "$INC/usr/share/uhuru-phase8/skel/.config/uhuru/shell-common.sh" <<'UHURU_P179_EOF'
# Uhuru OS: mipangilio ya pamoja ya shell (bash na zsh) - Uhuru Dev Edition.
# Faili hii inabadilishwa na masasisho; mabadiliko yako yaweke kwenye ~/.zshrc au ~/.bashrc.
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

export EDITOR="${EDITOR:-nvim}"
export VISUAL="$EDITOR"
export LESS="-FRX"
export HISTCONTROL=ignoreboth
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH" ;; esac
export PATH

alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
if command -v exa >/dev/null 2>&1; then
    alias ls='exa --group-directories-first'
    alias ll='exa -lah --group-directories-first --git'
    alias tree='exa --tree --level=3'
fi
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v nvim >/dev/null 2>&1 && alias v='nvim'

alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate -20'
alias ports='ss -tulpn'

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
serve() { python3 -m http.server "${1:-8000}"; }
extract() {
    [ -f "$1" ] || { echo "extract: faili '$1' haipo"; return 1; }
    case "$1" in
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.xz|*.txz)   tar xJf "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.7z)             7z x "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.xz)             unxz "$1" ;;
        *) echo "extract: aina ya faili haijulikani: $1"; return 1 ;;
    esac
}
UHURU_P179_EOF

put "$INC/usr/share/uhuru-phase8/skel/.npmrc" <<'UHURU_P179_EOF'
prefix=${HOME}/.npm-global
UHURU_P179_EOF

put "$INC/usr/share/uhuru-phase8/skel/.tmux.conf" <<'UHURU_P179_EOF'
# Uhuru OS - tmux
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -g default-command "exec /usr/local/bin/uhuru-shell"
set -g mouse on
set -g history-limit 50000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -s escape-time 10
setw -g mode-keys vi
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind r source-file ~/.tmux.conf \; display "tmux: mipangilio imesomwa upya"
set -g status-style "bg=#0b2f36,fg=#eaf6f6"
set -g status-left "#[bg=#f5c518,fg=#0b2f36,bold] Uhuru #[default] "
set -g status-right "#[fg=#f5c518]%d/%m %H:%M "
setw -g window-status-current-style "bg=#f5c518,fg=#0b2f36,bold"
UHURU_P179_EOF

put "$INC/usr/share/uhuru-phase8/skel/.zshrc" <<'UHURU_P179_EOF'
# Uhuru OS - zsh ya msanidi: mapendekezo, rangi, historia bora na prompt yenye git.
# Hariri faili hii upendavyo; haitabadilishwa na masasisho.
[[ -o interactive ]] || return 0

mkdir -p "$HOME/.cache" 2>/dev/null

# --- historia
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt AUTO_CD HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY INC_APPEND_HISTORY
setopt EXTENDED_GLOB INTERACTIVE_COMMENTS PROMPT_SUBST NO_BEEP

# --- ukamilishaji (Tab)
autoload -Uz compinit
compinit -u -d "$HOME/.cache/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh-comp"

# --- funguo
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search 2>/dev/null
zle -N down-line-or-beginning-search 2>/dev/null
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# --- aliases na kazi za pamoja
[ -f "$HOME/.config/uhuru/shell-common.sh" ] && . "$HOME/.config/uhuru/shell-common.sh"

# --- fzf (Ctrl+R, Ctrl+T, Alt+C) na zoxide (z)
for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/doc/fzf/examples/completion.zsh; do
    [ -f "$f" ] && . "$f"
done
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# --- prompt: mtumiaji@kompyuta  folda  (tawi-la-git)
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'
precmd() { vcs_info }
PROMPT='%B%F{214}%n%f%b%F{244}@%f%F{45}%m%f %F{114}%~%f%F{176}${vcs_info_msg_0_}%f
%(?.%F{214}.%F{196})â¯%f '

# --- salamu
print -P "%B%F{214}Uhuru OS 1.0%f%b  -  Letema Group Tech   %F{244}(andika %Bmsaada%b%F{244} kupata mwongozo)%f"

# --- plugins (syntax-highlighting lazima iwe ya mwisho)
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
UHURU_P179_EOF

put "$INC/usr/share/uhuru-store/icons/uhuru-installer.svg" <<'UHURU_P179_EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0b3b44"/><stop offset="1" stop-color="#137a82"/></linearGradient></defs>
<rect x="6" y="6" width="116" height="116" rx="28" fill="url(#g)"/>
<rect x="28" y="78" width="72" height="22" rx="6" fill="#f5c518"/>
<circle cx="88" cy="89" r="3.5" fill="#0b2f36"/>
<path d="M64 24v36" stroke="#ffffff" stroke-width="9" stroke-linecap="round"/>
<path d="M46 46l18 18 18-18" fill="none" stroke="#ffffff" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
UHURU_P179_EOF

put config/package-lists/uhuru-phase8.list.chroot <<'UHURU_P179_EOF'
# Uhuru OS awamu ya 8: Uhuru Dev Edition - zana za msingi (zinajulikana kuwepo kwenye Debian 12).
# Zana za ziada (gh, podman, distrobox, adb, zoxide, n.k.) zinawekwa na hook 9995 bila kuvunja build.
git
curl
wget
build-essential
pkg-config
python3-dev
python3-pip
python3-venv
libssl-dev
libffi-dev
zlib1g-dev
nodejs
npm
jq
ripgrep
fd-find
bat
fzf
tmux
neovim
zsh
zsh-autosuggestions
zsh-syntax-highlighting
fish
btop
tree
ncdu
rsync
openssh-client
sqlite3
shellcheck
aria2
socat
live-build
debootstrap
xorriso
squashfs-tools
mtools
gdb
strace
lsof
manpages-dev
netcat-openbsd
bind9-dnsutils
traceroute
UHURU_P179_EOF

put config/hooks/live/9995-uhuru-phase8.hook.chroot <<'UHURU_P179_EOF'
#!/bin/sh
# Uhuru OS awamu ya 8: Uhuru Dev Edition - zana za ziada, mipangilio ya shell/terminali/git. Haivunji build.
set -e
P8=/usr/share/uhuru-phase8/skel
SK=/etc/skel
[ -d "$P8" ] || { echo "uhuru-phase8: $P8 haipo"; exit 1; }
export DEBIAN_FRONTEND=noninteractive

# 1. zana za ziada (kila moja ikikosekana inaishia onyo tu)
OPT="gh git-lfs cmake pipx podman podman-docker podman-compose uidmap slirp4netns fuse-overlayfs catatonit distrobox android-tools-adb android-tools-fastboot scrcpy zoxide exa tig shfmt fonts-jetbrains-mono httpie"
apt-get update -qq >/dev/null 2>&1 || echo "uhuru-phase8: ONYO: apt-get update imeshindwa"
if ! apt-get install -y --no-install-recommends $OPT >/tmp/uhuru-p8-opt.log 2>&1; then
    echo "uhuru-phase8: ONYO: usakinishaji wa pamoja umeshindwa; najaribu moja moja"
    for p in $OPT; do
        apt-get install -y --no-install-recommends "$p" >/dev/null 2>&1 || echo "uhuru-phase8: ONYO: $p haipatikani"
    done
fi
apt-get clean || true

# 2. majina mafupi ya zana za Debian
[ -x /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind /usr/local/bin/fd
[ -x /usr/bin/batcat ] && ln -sf /usr/bin/batcat /usr/local/bin/bat

# 3. git ya mfumo mzima na kihariri chaguo-msingi
git config --system init.defaultBranch master
git config --system pull.rebase false
git config --system color.ui auto
if command -v nvim >/dev/null 2>&1; then
    git config --system core.editor nvim
    update-alternatives --set editor /usr/bin/nvim 2>/dev/null || true
fi

# 4. faili za mtumiaji mpya (/etc/skel): zile za kwetu tu zinaandikwa; za mtumiaji hazifutwi
mkdir -p "$SK/.config/uhuru" "$SK/.config/nvim" "$SK/.config/xfce4/terminal"
cp -f "$P8/.config/uhuru/shell-common.sh" "$SK/.config/uhuru/shell-common.sh"
[ -e "$SK/.zshrc" ]                || cp "$P8/.zshrc" "$SK/.zshrc"
[ -e "$SK/.tmux.conf" ]            || cp "$P8/.tmux.conf" "$SK/.tmux.conf"
[ -e "$SK/.npmrc" ]                || cp "$P8/.npmrc" "$SK/.npmrc"
[ -e "$SK/.config/nvim/init.lua" ] || cp "$P8/.config/nvim/init.lua" "$SK/.config/nvim/init.lua"

# 5. bash: pakia mipangilio ya pamoja (mara moja tu; PS1 na salamu zilizopo hazibadilishwi)
touch "$SK/.bashrc"
if ! grep -q 'uhuru-phase8' "$SK/.bashrc"; then
    cat >> "$SK/.bashrc" <<'BASHRC'

# uhuru-phase8: aliases na kazi za msanidi (git, mkcd, extract, serve, ...)
[ -f "$HOME/.config/uhuru/shell-common.sh" ] && . "$HOME/.config/uhuru/shell-common.sh"
BASHRC
fi

# 6. Uhuru Terminal (xfce4-terminal): inaanza na uhuru-shell (zsh); rangi na mipangilio ya sasa vinabaki
TR="$SK/.config/xfce4/terminal/terminalrc"
[ -f "$TR" ] || printf '[Configuration]\n' > "$TR"
grep -q '^\[Configuration\]' "$TR" || sed -i '1i [Configuration]' "$TR"
setkey() {
    if grep -q "^$1=" "$TR"; then sed -i "s|^$1=.*|$1=$2|" "$TR"; else sed -i "/^\[Configuration\]/a $1=$2" "$TR"; fi
}
setkey RunCustomCommand TRUE
setkey CustomCommand uhuru-shell
setkey ScrollingLines 50000
if command -v fc-list >/dev/null 2>&1 && fc-list 2>/dev/null | grep -qi 'JetBrains Mono'; then
    setkey FontUseSystem FALSE
    setkey FontName "JetBrains Mono 11"
fi

chmod 0755 /usr/local/bin/uhuru-dev /usr/local/bin/uhuru-shell /usr/local/bin/uhuru-workspace /usr/local/bin/uhuru-phase8-init /usr/local/bin/msaada
if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database /usr/share/applications || true; fi

# 7. uthibitisho wa ujenzi (hautavunja build; telemetry ya CI itaripoti tena ndani ya ISO)
zsh -n "$SK/.zshrc" || echo "uhuru-phase8: ONYO: .zshrc ina kosa la syntax"
/usr/local/bin/uhuru-dev doctor --ci || echo "uhuru-phase8: ONYO: zana za msingi hazijakamilika"
echo "uhuru-phase8: Uhuru Dev Edition imewekwa"
exit 0
UHURU_P179_EOF

put config/hooks/live/9996-uhuru-phase7.hook.chroot <<'UHURU_P179_EOF'
#!/bin/sh
# Uhuru OS awamu ya 7: kisakinishi (Calamares) chenye chapa ya Uhuru, usimbaji wa diski (LUKS), Secure Boot, mifumo ya mafaili.
# Calamares, calamares-settings-debian, grub-efi-amd64-signed, grub-pc-bin, firmware na microcode zilikuwepo tayari; hapa tunaongeza
# kinachokosekana. Kila kitu ni "soft": kikikosekana kinaishia onyo, na CI (UHURU-P7) inaripoti.
set -e
export DEBIAN_FRONTEND=noninteractive
P7=/usr/share/uhuru-phase7
CAL=/etc/calamares

# 1. vifurushi vinavyokosekana
PK="python3-yaml cryptsetup-initramfs lvm2 btrfs-progs xfsprogs shim-signed qml-module-qtquick2 qml-module-qtquick-controls2 gparted timeshift accountsservice libnotify-bin"
apt-get update -qq >/dev/null 2>&1 || echo "uhuru-phase7: ONYO: apt-get update imeshindwa"
if ! apt-get install -y --no-install-recommends $PK >/tmp/uhuru-p7.log 2>&1; then
    echo "uhuru-phase7: ONYO: usakinishaji wa pamoja umeshindwa; najaribu moja moja"
    for p in $PK; do
        apt-get install -y --no-install-recommends "$p" >/dev/null 2>&1 || echo "uhuru-phase7: ONYO: $p haikusakinishwa"
    done
fi
dpkg --configure -a >/dev/null 2>&1 || true
apt-get clean || true

# 2. huduma ya usafi wa mara ya kwanza (mfumo uliosakinishwa tu)
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /etc/systemd/system/uhuru-firstboot.service /etc/systemd/system/multi-user.target.wants/uhuru-firstboot.service
chmod 0755 /usr/local/sbin/uhuru-firstboot /usr/local/sbin/uhuru-installer-run /usr/local/bin/uhuru-installer

# 3. Calamares: chapa ya Uhuru na mipangilio (kila badiliko linakaguliwa na linarudishwa likiharibu YAML)
yaml_ok() {
    python3 - "$1" <<'PY' 2>/dev/null
import sys
try:
    import yaml
except ImportError:
    sys.exit(0)
yaml.safe_load(open(sys.argv[1]))
PY
}
ykey() {
    f=$1; k=$2; v=$3
    [ -n "$(tail -c1 "$f")" ] && echo >> "$f"
    if grep -q "^$k:" "$f"; then sed -i "s|^$k:.*|$k: $v|" "$f"; else printf '%s: %s\n' "$k" "$v" >> "$f"; fi
}
tune_partition() {
    ykey "$CAL/modules/partition.conf" efiSystemPartitionSize 512MiB
    ykey "$CAL/modules/partition.conf" enableLuksAutomatedPartitioning true
    ykey "$CAL/modules/partition.conf" luksGeneration luks1
}
guarded() {   # guarded <faili> <amri...>: tekeleza, kagua YAML, rudisha nakala ikiwa imeharibika
    f=$1; shift
    cp -p "$f" "$f.uhuru-bak"
    "$@"
    if yaml_ok "$f"; then rm -f "$f.uhuru-bak"; else mv -f "$f.uhuru-bak" "$f"; echo "uhuru-phase7: ONYO: $f ilirudishwa (YAML ilikuwa batili)"; fi
}
if [ -f "$CAL/settings.conf" ]; then
    mkdir -p "$CAL/branding/uhuru" "$CAL/modules"
    cp -a "$P7/branding/uhuru/." "$CAL/branding/uhuru/"
    if yaml_ok "$CAL/branding/uhuru/branding.desc"; then
        guarded "$CAL/settings.conf" sed -i 's/^branding:.*/branding: uhuru/' "$CAL/settings.conf"
    else
        echo "uhuru-phase7: ONYO: branding.desc ni batili; chapa ya Debian inabaki"
    fi
    [ -f "$CAL/modules/welcome.conf" ] && cp -p "$CAL/modules/welcome.conf" "$CAL/modules/welcome.conf.uhuru-bak"
    cp -f "$P7/modules/welcome.conf" "$CAL/modules/welcome.conf"
    if yaml_ok "$CAL/modules/welcome.conf"; then rm -f "$CAL/modules/welcome.conf.uhuru-bak"; else
        [ -f "$CAL/modules/welcome.conf.uhuru-bak" ] && mv -f "$CAL/modules/welcome.conf.uhuru-bak" "$CAL/modules/welcome.conf"
    fi
    [ -f "$CAL/modules/partition.conf" ] && guarded "$CAL/modules/partition.conf" tune_partition
else
    echo "uhuru-phase7: ONYO: $CAL/settings.conf haipo (calamares-settings-debian haikusakinishwa?)"
fi

# 4. onyesha kisakinishi cha Uhuru pekee (Debian's zinafichwa) na kiweke kwenye vipendwa vya Start menu
for f in /usr/share/applications/install-debian.desktop /usr/share/applications/calamares.desktop; do
    if [ -f "$f" ]; then
        sed -i '/^NoDisplay=/d' "$f"
        sed -i '/^\[Desktop Entry\]/a NoDisplay=true' "$f"
    fi
done
rm -f /etc/skel/Desktop/install-debian.desktop
for rc in /etc/skel/.config/xfce4/panel/whiskermenu-1.rc /etc/xdg/xfce4/panel/whiskermenu-defaults.rc; do
    if [ -f "$rc" ] && ! grep -q 'uhuru-installer.desktop' "$rc"; then
        sed -i 's/^favorites=/favorites=uhuru-installer.desktop,/' "$rc"
    fi
done
if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database /usr/share/applications || true; fi

# 5. uthibitisho wa ujenzi (hautavunja build; CI inaripoti tena ndani ya ISO)
/usr/local/bin/uhuru-installer --check || echo "uhuru-phase7: ONYO: ukaguzi wa kisakinishi umeshindwa (angalia mistari ya ONYO hapo juu)"
echo "uhuru-phase7: kisakinishi cha Uhuru kimewekwa"
exit 0
UHURU_P179_EOF

put config/hooks/live/9997-uhuru-phase9.hook.chroot <<'UHURU_P179_EOF'
#!/bin/sh
# Uhuru OS awamu ya 9: ulinzi (ngome ya moto, AppArmor, sasisho za usalama, ClamAV, Flash Safe, uwazi). Haivunji build.
set -e
export DEBIAN_FRONTEND=noninteractive

PK="nftables apparmor apparmor-utils unattended-upgrades clamav clamav-freshclam libnotify-bin"
apt-get update -qq >/dev/null 2>&1 || echo "uhuru-phase9: ONYO: apt-get update imeshindwa"
if ! apt-get install -y --no-install-recommends $PK >/tmp/uhuru-p9.log 2>&1; then
    echo "uhuru-phase9: ONYO: usakinishaji wa pamoja umeshindwa; najaribu moja moja"
    for p in $PK; do
        apt-get install -y --no-install-recommends "$p" >/dev/null 2>&1 || echo "uhuru-phase9: ONYO: $p haikusakinishwa"
    done
fi
dpkg --configure -a >/dev/null 2>&1 || true
apt-get clean || true

chmod 0755 /usr/local/sbin/uhuru-firewall /usr/local/bin/uhuru-usbscan /usr/local/bin/uhuru-usbwatch /usr/local/bin/uhuru-sign /usr/local/bin/uhuru-protect

# ngome ya moto: wasifu wa 'umma' kwa msingi, huduma ya nftables ianze kila boot
mkdir -p /etc/uhuru-firewall
/usr/local/sbin/uhuru-firewall regen umma
systemctl enable nftables >/dev/null 2>&1 || echo "uhuru-phase9: ONYO: nftables haikuwashwa"

# AppArmor ianze kila boot; ClamAV isipakue hifadhidata kiotomatiki (mtandao ni ghali); cups-browsed (hatari ya mbali) imefungwa
systemctl enable apparmor >/dev/null 2>&1 || true
systemctl disable clamav-freshclam.service >/dev/null 2>&1 || true
systemctl mask cups-browsed.service >/dev/null 2>&1 || true

# uwazi: orodha ya vifurushi (SBOM) na toleo
mkdir -p /usr/share/uhuru
dpkg-query -W -f='${Package}\t${Version}\n' 2>/dev/null | sort > /usr/share/uhuru/SBOM-packages.txt
printf 'Uhuru OS 1.0\nLetema Group Tech\nImejengwa: %s\n' "$(date -u +%F)" > /usr/share/uhuru/RELEASE
if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database /usr/share/applications || true; fi

# uthibitisho wa ujenzi (hautavunja build)
/usr/local/bin/uhuru-usbscan --selftest || echo "uhuru-phase9: ONYO: usbscan selftest imeshindwa"
/usr/local/bin/uhuru-sign --selftest || echo "uhuru-phase9: ONYO: sign selftest imeshindwa"
/usr/local/bin/uhuru-protect --check || echo "uhuru-phase9: ONYO: baadhi ya vipengele vya ulinzi si sawa (kawaida AppArmor/ngome hazijawashwa ndani ya chroot)"
echo "uhuru-phase9: ulinzi umewekwa"
exit 0
UHURU_P179_EOF

cat > "$W/telem_func" <<'UHURU_P179_EOF'
# v17.1: ukaguzi wa awamu ya 7 (kisakinishi, Secure Boot, LUKS, mifumo ya mafaili)
P7PID=""
p7check() {
    local inst miss="" p fb=no acct=no ts=no
    inst=$(timeout -k 1 25 /usr/local/bin/uhuru-installer --check 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,/:()+-' ' ' | tr -s ' ' ',' | cut -c1-220)
    for p in calamares calamares-settings-debian cryptsetup-initramfs shim-signed lvm2 btrfs-progs xfsprogs accountsservice grub-efi-amd64-signed grub-pc-bin; do
        dpkg-query -W -f='${db:Status-Abbrev}' "$p" 2>/dev/null | grep -q '^ii' || miss="$miss${miss:+,}$p"
    done
    if [ -f /etc/systemd/system/multi-user.target.wants/uhuru-firstboot.service ] && [ -x /usr/local/sbin/uhuru-firstboot ]; then fb=ok; fi
    [ -f /etc/systemd/system/accounts-daemon.service.d/uhuru-live.conf ] && acct=ok
    dpkg-query -W -f='${db:Status-Abbrev}' timeshift 2>/dev/null | grep -q '^ii' && ts=yes
    printf 'UHURU-P7 inst=%s pkgmiss=%s fb=%s acct=%s ts=%s' "${inst:-empty}" "${miss:-none}" "$fb" "$acct" "$ts"
}
# v17.0: ukaguzi wa awamu ya 8 (Uhuru Dev Edition: zana, zsh, terminali)
P8PID=""
p8check() {
    local sk=/etc/skel cfg=no dev zs=none bs=none sh=none ws xu
    if [ -f "$sk/.zshrc" ] && [ -f "$sk/.tmux.conf" ] && [ -f "$sk/.config/nvim/init.lua" ] && [ -f "$sk/.config/uhuru/shell-common.sh" ] \
        && grep -q '^CustomCommand=uhuru-shell' "$sk/.config/xfce4/terminal/terminalrc" 2>/dev/null; then cfg=ok; fi
    dev=$(timeout -k 1 40 /usr/local/bin/uhuru-dev doctor --ci 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,/:+-' ' ' | tr -s ' ' ',' | cut -c1-200)
    ws=$(timeout -k 1 10 /usr/local/bin/uhuru-workspace status --ci 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,/:-' ' ' | tr -s ' ' ',' | cut -c1-40)
    if [ -e /var/lib/uhuru-setup.done ]; then
        xu=$(timeout -k 1 3 ps -C xfce4-session -o user= 2>/dev/null | head -n 1 | tr -d ' ')
        if [ -n "$xu" ]; then
            zs=$(timeout -k 2 30 runuser -u "$xu" -- env HOME="/home/$xu" TERM=xterm-256color zsh -ic 'print -r -- "ZSH-OK ${ZSH_VERSION} sug=${+ZSH_AUTOSUGGEST_STRATEGY} hl=${+ZSH_HIGHLIGHT_HIGHLIGHTERS} mkcd=${+functions[mkcd]}"' </dev/null 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,-' ' ' | tr -s ' ' ',' | cut -c1-80)
            bs=$(timeout -k 2 20 runuser -u "$xu" -- env HOME="/home/$xu" TERM=xterm-256color bash -ic 'echo BASH-OK' </dev/null 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,-' ' ' | tr -s ' ' ',' | cut -c1-30)
            sh=$(timeout -k 2 20 runuser -u "$xu" -- env HOME="/home/$xu" /usr/local/bin/uhuru-shell --print </dev/null 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9' ' ' | tr -s ' ' ',' | cut -c1-20)
        fi
    fi
    printf 'UHURU-P8 cfg=%s dev=%s zsh=%s bash=%s shell=%s ws=%s' "$cfg" "${dev:-empty}" "${zs:-empty}" "${bs:-empty}" "${sh:-empty}" "${ws:-empty}"
}
# v17.1: ukaguzi wa awamu ya 9 (ulinzi: ngome ya moto, AppArmor, kernel, flash, saini, Kituo cha Ulinzi)
P9PID=""
p9check() {
    local fw pr us sg wc=0 gui=none xu
    fw=$(timeout -k 1 15 /usr/local/sbin/uhuru-firewall status --ci 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,/:-' ' ' | tr -s ' ' ',' | cut -c1-80)
    pr=$(timeout -k 2 30 /usr/local/bin/uhuru-protect --check 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,/:-' ' ' | tr -s ' ' ',' | cut -c1-220)
    us=$(timeout -k 2 40 /usr/local/bin/uhuru-usbscan --selftest 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,/:-' ' ' | tr -s ' ' ',' | cut -c1-60)
    sg=$(timeout -k 2 30 /usr/local/bin/uhuru-sign --selftest 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,/:-' ' ' | tr -s ' ' ',' | cut -c1-40)
    if [ -e /var/lib/uhuru-setup.done ]; then
        xu=$(timeout -k 1 3 ps -C xfce4-session -o user= 2>/dev/null | head -n 1 | tr -d ' ')
        if [ -n "$xu" ]; then
            wc=$(timeout -k 1 3 pgrep -u "$xu" -fc '[u]huru-usbwatch' 2>/dev/null)
            gui=$(timeout -k 2 40 runuser -u "$xu" -- env DISPLAY=:0 XAUTHORITY="/home/$xu/.Xauthority" /usr/local/bin/uhuru-protect --smoke 2>&1 | tail -n 1 | tr -c 'A-Za-z0-9=_.,-' ' ' | tr -s ' ' ',' | cut -c1-70)
            [ -n "$gui" ] || gui=empty
        fi
    fi
    printf 'UHURU-P9 fw=%s protect=%s usb=%s sign=%s watch=%s gui=%s' "${fw:-empty}" "${pr:-empty}" "${us:-empty}" "${sg:-empty}" "${wc:-0}" "$gui"
}
UHURU_P179_EOF

cat > "$W/telem_call" <<'UHURU_P179_EOF'
    if [ $((n % 6)) -eq 2 ] && { [ -z "$P7PID" ] || ! kill -0 "$P7PID" 2>/dev/null; }; then
        { emit "$(p7check)"; } &
        P7PID=$!
    fi
    if [ $((n % 6)) -eq 5 ] && { [ -z "$P8PID" ] || ! kill -0 "$P8PID" 2>/dev/null; }; then
        { emit "$(p8check)"; } &
        P8PID=$!
    fi
    if [ $((n % 6)) -eq 4 ] && { [ -z "$P9PID" ] || ! kill -0 "$P9PID" 2>/dev/null; }; then
        { emit "$(p9check)"; } &
        P9PID=$!
    fi
UHURU_P179_EOF

cat > "$W/verdict_block" <<'UHURU_P179_EOF'
# ---- Awamu ya 7: kisakinishi (Calamares), Secure Boot, LUKS (v17.1) ----
P7=$(slogc | grep '^UHURU-P7 ' | tail -n 40)
P7LAST=$(printf '%s\n' "$P7" | tail -n 1)
p7() { printf '%s\n' "$P7" | grep -Eq "$1"; }
if [ -z "$P7" ]; then
    fail "awamu ya 7: hakuna ripoti ya UHURU-P7 (uhuru-installer au telemetry haikufanya kazi)"
else
    if p7 'inst=INSTALLER-OK'; then echo "CHECK PASS: e2e: awamu ya 7: kisakinishi cha Uhuru kina muundo kamili (chapa, moduli zote, Secure Boot, LUKS, ext4/btrfs/xfs/fat)"; else fail "awamu ya 7: muundo wa kisakinishi una upungufu ($(printf '%s\n' "$P7" | grep -o 'inst=[^ ]*' | sort -u | tail -n 1))"; fi
    if p7 'pkgmiss=none'; then echo "CHECK PASS: e2e: awamu ya 7: vifurushi vya usakinishaji vipo (calamares, cryptsetup-initramfs, shim-signed, lvm2, btrfs, xfs, grub signed)"; else fail "awamu ya 7: vifurushi vinakosekana: $(printf '%s\n' "$P7" | grep -o 'pkgmiss=[^ ]*' | sort -u | tail -n 1)"; fi
    if p7 'fb=ok acct=ok'; then echo "CHECK PASS: e2e: awamu ya 7: usafi wa mara ya kwanza na orodha ya watumiaji (mfumo uliosakinishwa) vimewekwa"; else fail "awamu ya 7: firstboot/accountsservice si sawa ($P7LAST)"; fi
    echo "CHECK INFO: e2e: awamu ya 7: $(printf '%s\n' "$P7" | grep -o 'inst=[^ ]*' | tail -n 1) $(printf '%s\n' "$P7" | grep -o 'ts=[^ ]*' | tail -n 1)  (efi=no ni kawaida kwa QEMU ya BIOS ya CI)"
fi
# ---- Awamu ya 8: Uhuru Dev Edition (v17.0) ----
P8=$(slogc | grep '^UHURU-P8 ' | tail -n 40)
P8LAST=$(printf '%s\n' "$P8" | tail -n 1)
p8() { printf '%s\n' "$P8" | grep -Eq "$1"; }
if [ -z "$P8" ]; then
    fail "awamu ya 8: hakuna ripoti ya UHURU-P8 (uhuru-dev au telemetry haikufanya kazi)"
else
    if p8 'cfg=ok'; then echo "CHECK PASS: e2e: awamu ya 8: .zshrc, tmux, neovim na Uhuru Terminal (uhuru-shell) zimewekwa kwenye /etc/skel"; else fail "awamu ya 8: mipangilio ya shell/terminali haijakamilika ($P8LAST)"; fi
    if p8 'dev=DEV-OK'; then echo "CHECK PASS: e2e: awamu ya 8: zana zote za msingi za ujenzi zipo (git, gcc, node, python, live-build, n.k.)"; else fail "awamu ya 8: zana za msingi zinakosekana ($(printf '%s\n' "$P8" | grep -o 'coremissing=[^ ]*' | tail -n 1))"; fi
    if p8 'zsh=ZSH-OK,[0-9.]+,sug=1,hl=1,mkcd=1'; then echo "CHECK PASS: e2e: awamu ya 8: zsh inapakia .zshrc kwenye session ya mtumiaji (mapendekezo, rangi za syntax, aliases)"; else fail "awamu ya 8: zsh haipakii vizuri ($(printf '%s\n' "$P8" | grep -o 'zsh=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p8 'bash=BASH-OK' && p8 'shell=zsh'; then echo "CHECK PASS: e2e: awamu ya 8: bash bado inafanya kazi na Uhuru Terminal inachagua zsh"; else fail "awamu ya 8: bash au uhuru-shell ina tatizo ($P8LAST)"; fi
    OM=$(printf '%s\n' "$P8" | grep -o 'optmissing=[^ ]*' | tail -n 1)
    echo "CHECK INFO: e2e: awamu ya 8: zana za ziada zisizopatikana: ${OM#optmissing=}"
fi
# ---- Awamu ya 9: ulinzi (v17.1) ----
P9=$(slogc | grep '^UHURU-P9 ' | tail -n 40)
P9LAST=$(printf '%s\n' "$P9" | tail -n 1)
p9() { printf '%s\n' "$P9" | grep -Eq "$1"; }
if [ -z "$P9" ]; then
    fail "awamu ya 9: hakuna ripoti ya UHURU-P9 (uhuru-protect au telemetry haikufanya kazi)"
else
    if p9 'fw=FW-OK'; then echo "CHECK PASS: e2e: awamu ya 9: ngome ya moto (nftables) inafanya kazi: kila kinachoingia kinabanwa ($(printf '%s\n' "$P9" | grep -o 'fw=[^ ]*' | tail -n 1))"; else fail "awamu ya 9: ngome ya moto haifanyi kazi ($(printf '%s\n' "$P9" | grep -o 'fw=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p9 'protect=PROTECT-OK,.*,bad=0,'; then echo "CHECK PASS: e2e: awamu ya 9: Kituo cha Ulinzi hakioni kipengele chochote chenye hatari"; else fail "awamu ya 9: Kituo cha Ulinzi kimeona hatari ($(printf '%s\n' "$P9" | grep -o 'protect=[^ ]*' | sort -u | tail -n 1))"; fi
    if p9 'protect=PROTECT-OK,.*fw=ok,aa=ok,sysctl=ok,upd=ok'; then echo "CHECK PASS: e2e: awamu ya 9: AppArmor, kernel iliyoimarishwa na sasisho za usalama vimewekwa"; else fail "awamu ya 9: AppArmor/kernel/sasisho si sawa ($(printf '%s\n' "$P9" | grep -o 'protect=[^ ]*' | sort -u | tail -n 1))"; fi
    if p9 'usb=USBSCAN-OK'; then echo "CHECK PASS: e2e: awamu ya 9: Flash Safe inatambua virus vya shortcut/autorun, haikosei faili safi, na inasafisha kwa karantini"; else fail "awamu ya 9: Flash Safe selftest imeshindwa ($(printf '%s\n' "$P9" | grep -o 'usb=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p9 'watch=[1-9]'; then echo "CHECK PASS: e2e: awamu ya 9: mlinzi wa flash (uhuru-usbwatch) anakimbia kwenye session ya mtumiaji"; else fail "awamu ya 9: mlinzi wa flash hakimbii kwenye session ($P9LAST)"; fi
    if p9 'sign=SIGN-OK'; then echo "CHECK PASS: e2e: awamu ya 9: saini za kidijitali (ed25519) zinafanya kazi, na mabadiliko ya faili yanagunduliwa"; else fail "awamu ya 9: uhuru-sign imeshindwa ($(printf '%s\n' "$P9" | grep -o 'sign=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    if p9 'gui=SMOKE-OK'; then echo "CHECK PASS: e2e: awamu ya 9: dirisha la Kituo cha Ulinzi linajengwa ndani ya session"; else fail "awamu ya 9: Kituo cha Ulinzi hakifunguki ndani ya session ($(printf '%s\n' "$P9" | grep -o 'gui=[^ ]*' | sort -u | tr '\n' ' '))"; fi
    echo "CHECK INFO: e2e: awamu ya 9: $(printf '%s\n' "$P9" | grep -o 'protect=[^ ]*' | tail -n 1)"
fi
UHURU_P179_EOF

cat > "$W/harness_add" <<'UHURU_P179_EOF'
        key ctrl-alt-t; sleep 6; typestr "uhuru-dev doctor"; key ret; sleep 10; shot 22-dev-doctor
        typestr "uhuru-installer"; key ret; sleep 6; shot 23-installer-preflight; key esc; sleep 2
        typestr "uhuru-protect"; key ret; sleep 8; shot 24-kituo-cha-ulinzi
UHURU_P179_EOF

cat > "$W/patch.py" <<'UHURU_P179_EOF'
import re, sys
kind, src, dst, snippet = sys.argv[1:5]
s = open(src, encoding="utf-8").read()
add = open(snippet, encoding="utf-8").read()
lines = s.split("\n")

def insert_before(pred, label):
    idx = [i for i, l in enumerate(lines) if pred(l)]
    if len(idx) < 1:
        sys.exit("ERROR: kiraka cha %s: mahali pa kuingiza hapajapatikana" % label)
    i = idx[0]
    lines[i:i] = add.rstrip("\n").split("\n")

def insert_after(pred, label, soft=False):
    idx = [i for i, l in enumerate(lines) if pred(l)]
    if not idx:
        if soft:
            print("SKIP: %s" % label); return False
        sys.exit("ERROR: kiraka cha %s: mahali pa kuingiza hapajapatikana" % label)
    i = idx[0] + 1
    lines[i:i] = add.rstrip("\n").split("\n")
    return True

if kind == "telem_func":
    insert_before(lambda l: l.startswith("n=0; RPID="), "telemetry (function)")
elif kind == "telem_call":
    cnt = sum(1 for l in lines if l == '    sleep "$SLEEP"')
    if cnt != 1:
        sys.exit("ERROR: kiraka cha telemetry (call): 'sleep \"$SLEEP\"' imepatikana mara %d (inatakiwa 1)" % cnt)
    insert_before(lambda l: l == '    sleep "$SLEEP"', "telemetry (call)")
elif kind == "verdict":
    insert_before(lambda l: l.startswith('if [ "$FAILS" -eq 0 ]; then echo "CHECK PASS: e2e: HATUA ZOTE'), "e2e-verdict.sh")
elif kind == "harness":
    if not insert_after(lambda l: "shot 21-uhuru-share" in l, "boot-screens.sh (21)", soft=True):
        if not insert_after(lambda l: "shot 19-lgt-store" in l, "boot-screens.sh (19)", soft=True):
            print("ONYO: picha ya 22-dev-doctor haikuongezwa (hakuna mahali pa kuiweka); si tatizo kwa CI")
else:
    sys.exit("kind?")
open(dst, "w", encoding="utf-8").write("\n".join(lines))
print("PATCH-OK", kind)

UHURU_P179_EOF

# ---- viraka vyote vinajaribiwa kwenye nakala za muda; repo haiguswi hadi vyote vikubalike
python3 "$W/patch.py" telem_func "$T" "$W/t1" "$W/telem_func"
python3 "$W/patch.py" telem_call "$W/t1" "$W/t2" "$W/telem_call"
python3 "$W/patch.py" verdict "$V" "$W/v1" "$W/verdict_block"
python3 "$W/patch.py" harness "$B" "$W/b1" "$W/harness_add"
bash -n "$W/t2"; bash -n "$W/v1"; bash -n "$W/b1"
for k in p7check p8check p9check; do grep -q "^$k()" "$W/t2" || { echo "ERROR: $k haikuingia"; exit 1; }; done
grep -q 'Awamu ya 7' "$W/v1" && grep -q 'Awamu ya 8' "$W/v1" && grep -q 'Awamu ya 9' "$W/v1" || { echo "ERROR: viraka vya verdict havikukubaliwa"; exit 1; }

# ---- ukaguzi wa faili mpya (kwenye eneo la muda)
for f in uhuru-dev uhuru-shell uhuru-workspace uhuru-phase8-init msaada uhuru-installer uhuru-usbwatch uhuru-sign; do bash -n "$STAGE/$INC/usr/local/bin/$f"; done
for f in uhuru-firewall uhuru-installer-run uhuru-firstboot; do bash -n "$STAGE/$INC/usr/local/sbin/$f"; done
bash -n "$STAGE/$INC/usr/share/uhuru-phase8/skel/.config/uhuru/shell-common.sh"
for h in 9995-uhuru-phase8 9996-uhuru-phase7 9997-uhuru-phase9; do sh -n "$STAGE/config/hooks/live/$h.hook.chroot"; done
python3 - "$STAGE/$INC" <<'PY'
import ast, json, sys, xml.dom.minidom as m
root = sys.argv[1]
for f in ("usr/local/bin/uhuru-protect", "usr/local/bin/uhuru-usbscan"):
    ast.parse(open(root + "/" + f).read())
json.load(open(root + "/etc/uhuru-store/catalog.d/20-dev.json"))
m.parse(root + "/usr/share/uhuru-store/icons/uhuru-installer.svg")
print("python/json/svg: sawa")
PY
"$STAGE/$INC/usr/local/bin/uhuru-usbscan" --selftest
"$STAGE/$INC/usr/local/bin/uhuru-sign" --selftest

# ---- kila kitu kimekubaliwa: nakili kwenye repo
cp -R "$STAGE/." .
cp "$W/t2" "$T"; cp "$W/v1" "$V"; cp "$W/b1" "$B"
chmod 0755 "$INC"/usr/local/bin/* "$INC"/usr/local/sbin/uhuru-firewall "$INC"/usr/local/sbin/uhuru-installer-run "$INC"/usr/local/sbin/uhuru-firstboot config/hooks/live/999[567]-uhuru-phase*.hook.chroot 2>/dev/null || true
chmod 0755 "$INC/usr/local/sbin/uhuru-ci-telemetry" 2>/dev/null || true

git add config scripts
git status --short | head -60
echo
echo "Tayari. Sasa:"
echo '  git commit -m "v17.1: awamu ya 7 (kisakinishi), 8 (Uhuru Dev Edition) na 9 (ulinzi)" && git push origin master'
echo '  bash scripts/ci-watch.sh v171'
exit 0
