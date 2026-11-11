#!/bin/bash
# Uhuru OS — ukaguzi wa ISO bila kuiwasha. Matumizi: inspect-iso.sh <iso> <out-dir>
# Majaribio ya ndani: ROOT_OVERRIDE=/njia/ya/root inaruka kupachika squashfs.
set -u
ISO=${1:?iso}; OUT=${2:?out-dir}
mkdir -p "$OUT"; R="$OUT/report.txt"; : > "$R"
W=$(mktemp -d)
SUDO=""; [ "$(id -u)" -eq 0 ] || SUDO="sudo"
cleanup() { [ -n "${ROOT_OVERRIDE:-}" ] || $SUDO umount "$W/root" 2>/dev/null; $SUDO rm -rf "$W"; }
trap cleanup EXIT

sec()   { printf '\n===== %s =====\n' "$*" >> "$R"; }
say()   { printf '%s\n' "$*" >> "$R"; }
check() { printf 'CHECK %s: %s\n' "$1" "$2" | tee -a "$R"; }
nc()    { grep -v '^[[:space:]]*#' "$1" 2>/dev/null | grep -v '^[[:space:]]*$'; }

# ---------- ISO ----------
sec "ISO"
say "faili: $(basename "$ISO")  saizi: $(stat -c %s "$ISO") bytes"
xorriso -indev "$ISO" -pvd_info 2>/dev/null | head -20 >> "$R"
say "--- /live";  xorriso -indev "$ISO" -find /live -exec lsdl 2>/dev/null >> "$R"
say "--- /EFI";   xorriso -indev "$ISO" -find /EFI -maxdepth 2 2>/dev/null >> "$R"
for f in /isolinux/live.cfg /isolinux/menu.cfg /boot/grub/grub.cfg; do
    if xorriso -osirrox on -indev "$ISO" -extract "$f" "$W/x.cfg" >/dev/null 2>&1; then
        say "--- $f (mistari muhimu)"
        grep -E -i "label|menuentry|append|linux " "$W/x.cfg" | head -30 >> "$R"
        rm -f "$W/x.cfg"
    fi
done
xorriso -indev "$ISO" -find /EFI/boot -name 'bootx64.efi' 2>/dev/null | grep -q bootx64 \
    && check PASS "ISO ina boot ya UEFI (bootx64.efi)" || check FAIL "ISO haina bootx64.efi"

# ---------- Pakiti ----------
sec "Pakiti"
xorriso -osirrox on -indev "$ISO" -extract /live/filesystem.packages "$W/fs.packages" >/dev/null 2>&1
if [ -s "$W/fs.packages" ]; then
    cp "$W/fs.packages" "$OUT/filesystem.packages"
    say "jumla ya pakiti: $(wc -l < "$W/fs.packages")"
    for p in user-setup live-config sudo zenity light-locker ufw ntfs-3g exfatprogs firefox-esr chromium xfce4-terminal thunar vlc \
             libreoffice-writer libreoffice-calc libreoffice-impress calamares lightdm lightdm-gtk-greeter \
             network-manager-gnome mousepad; do
        if awk '{print $1}' "$W/fs.packages" | grep -qx "$p"; then check PASS "pakiti $p ipo"; else check FAIL "pakiti $p HAIPO"; fi
    done
    for p in grub2-common grub-pc-bin grub-efi-amd64-bin efibootmgr mokutil; do
        if awk '{print $1}' "$W/fs.packages" | grep -qx "$p"; then check PASS "bootloader pkg $p ipo"; else check FAIL "bootloader pkg $p HAIPO (Calamares haitasakinisha)"; fi
    done
    for p in grub-efi-amd64-signed shim-signed; do
        if awk '{print $1}' "$W/fs.packages" | grep -qx "$p"; then check PASS "Secure Boot pkg $p ipo"; else check INFO "Secure Boot pkg $p haipo (Secure Boot haitafanya kazi; BIOS/UEFI ya kawaida ni sawa)"; fi
    done
    for p in os-prober dosfstools grub-common; do
        if awk '{print $1}' "$W/fs.packages" | grep -qx "$p"; then check INFO "bootloader: $p ipo"; else check INFO "bootloader: $p haipo"; fi
    done
else
    check FAIL "filesystem.packages haikupatikana"
fi

# ---------- Pachika mfumo ----------
if [ -n "${ROOT_OVERRIDE:-}" ]; then
    ROOT=$ROOT_OVERRIDE
else
    xorriso -osirrox on -indev "$ISO" -extract /live/filesystem.squashfs "$W/fs.squashfs" >/dev/null 2>&1
    mkdir -p "$W/root"
    if ! $SUDO mount -t squashfs -o loop,ro "$W/fs.squashfs" "$W/root"; then
        check FAIL "squashfs haikupachikwa; ukaguzi wa ndani umesimama"; exit 0
    fi
    ROOT=$W/root
fi

# ---------- Faili za Uhuru OS ----------
sec "Faili za Uhuru OS"
for f in usr/local/bin/uhuru-setup usr/local/sbin/uhuru-create-user usr/local/bin/uhuru-about usr/local/bin/uhuru-wallpaper \
         etc/xdg/autostart/uhuru-setup.desktop etc/xdg/autostart/uhuru-wallpaper.desktop \
         usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper-1.png usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper-2.png \
         usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper-3.png usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper-4.png \
         usr/share/backgrounds/uhuru-os/uhuru-os-login.png usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper.svg \
         etc/skel/Desktop/firefox-esr.desktop etc/skel/Desktop/chromium.desktop etc/skel/Desktop/xfce4-terminal.desktop \
         etc/skel/Desktop/thunar.desktop etc/skel/Desktop/letema-group-tech.desktop etc/skel/Desktop/Karibu-Uhuru-OS.txt \
         etc/skel/.config/xfce4/terminal/terminalrc etc/lightdm/lightdm-gtk-greeter.conf \
         etc/chromium/policies/managed/uhuru-os.json etc/xdg/mimeapps.list \
         usr/local/sbin/uhuru-live-prep usr/local/bin/uhuru-locker usr/local/bin/uhuru-greeter-setup usr/local/bin/uhuru-selftest \
         etc/lightdm/lightdm.conf.d/50-uhuru.conf usr/share/backgrounds/uhuru-os/uhuru-os-login-hint-mtumiaji.png \
         usr/share/backgrounds/uhuru-os/uhuru-os-login-hint-user.png; do
    if [ -e "$ROOT/$f" ]; then check PASS "faili lipo: $f"; else check FAIL "faili HALIPO: $f"; fi
done
for f in usr/local/bin/uhuru-setup usr/local/sbin/uhuru-create-user usr/local/bin/uhuru-about usr/local/bin/uhuru-wallpaper usr/local/bin/uhuru-selftest; do
    if [ -f "$ROOT/$f" ]; then
        [ -x "$ROOT/$f" ] && check PASS "inaweza kuendeshwa: $f" || check FAIL "HAIENDESHEKI (chmod): $f"
        bash -n "$ROOT/$f" 2>/dev/null && check PASS "syntax sawa: $f" || check FAIL "syntax mbaya: $f"
    fi
done

# ---------- Utambulisho ----------
sec "Utambulisho wa mfumo"
say "--- os-release"; grep -E '^(NAME|PRETTY_NAME|ID|VERSION_ID|HOME_URL)=' "$ROOT/etc/os-release" >> "$R" 2>&1
grep -q '^NAME="Uhuru OS"' "$ROOT/etc/os-release" 2>/dev/null && check PASS "os-release NAME ni Uhuru OS" || check FAIL "os-release NAME si Uhuru OS"
say "--- issue"; cat "$ROOT/etc/issue" >> "$R" 2>&1
say "--- motd"; cat "$ROOT/etc/motd" >> "$R" 2>&1
say "--- hostname / timezone"; cat "$ROOT/etc/hostname" "$ROOT/etc/timezone" >> "$R" 2>&1
say "--- GRUB_DISTRIBUTOR"; grep -n '^GRUB_DISTRIBUTOR' "$ROOT/etc/default/grub" >> "$R" 2>&1
grep -q '^GRUB_DISTRIBUTOR="Uhuru OS"' "$ROOT/etc/default/grub" 2>/dev/null && check PASS "GRUB_DISTRIBUTOR ni Uhuru OS" || check FAIL "GRUB_DISTRIBUTOR si Uhuru OS (au /etc/default/grub haipo)"
grep -q '^ID_LIKE=debian' "$ROOT/etc/os-release" 2>/dev/null && check PASS "os-release ina ID_LIKE=debian" || check FAIL "os-release haina ID_LIKE=debian"
say "--- /etc/localtime"; readlink "$ROOT/etc/localtime" >> "$R" 2>&1
if [ -L "$ROOT/etc/systemd/system/multi-user.target.wants/uhuru-live-prep.service" ] && [ -f "$ROOT/etc/systemd/system/uhuru-live-prep.service" ]; then
    check PASS "huduma ya maandalizi (uhuru-live-prep) imewashwa"
else
    check FAIL "uhuru-live-prep.service haijawashwa"
fi
say "--- login-current.png ->"; readlink "$ROOT/usr/share/backgrounds/uhuru-os/login-current.png" >> "$R" 2>&1
readlink "$ROOT/usr/share/backgrounds/uhuru-os/login-current.png" 2>/dev/null | grep -q 'uhuru-os-login.png$' \
    && check PASS "login-current.png ni ya kawaida (bila maelezo) kwenye ISO" || check FAIL "login-current.png si symlink ya uhuru-os-login.png"
grep -q '^Exec=/usr/local/bin/uhuru-locker' "$ROOT/etc/xdg/autostart/light-locker.desktop" 2>/dev/null \
    && check PASS "light-locker inaanzishwa kupitia uhuru-locker" || check FAIL "light-locker.desktop haitumii uhuru-locker"
say "--- dpkg status: shim-signed / grub-efi-amd64-signed"
for p in shim-signed grub-efi-amd64-signed; do grep -A2 "^Package: $p$" "$ROOT/var/lib/dpkg/status" >> "$R" 2>&1 || say "$p: haipo kwenye dpkg status"; done
say "--- lightdm users.conf"; nc "$ROOT/etc/lightdm/users.conf" >> "$R" 2>&1
grep -q 'Africa/Dar_es_Salaam' "$ROOT/etc/timezone" 2>/dev/null && check PASS "saa ya default ni Africa/Dar_es_Salaam" || check FAIL "saa si Africa/Dar_es_Salaam"
grep -q 'UHURU_BANNER' "$ROOT/etc/skel/.bashrc" 2>/dev/null && check PASS "terminal ya Uhuru (bashrc) ipo" || check FAIL "bashrc haina block ya Uhuru"

# ---------- Login na akaunti ----------
sec "Login na akaunti"
say "--- 0030-user-setup (_PASSWORD)"; grep -n '_PASSWORD=' "$ROOT/usr/lib/live/config/0030-user-setup" >> "$R" 2>&1
grep -q '_PASSWORD="8Anb4IpaWQzBY"' "$ROOT/usr/lib/live/config/0030-user-setup" 2>/dev/null \
    && check PASS "password ya live ni uhuru (hash sahihi)" || check FAIL "hash ya password si ya uhuru"
say "--- lightdm.conf na conf.d"; ls "$ROOT/etc/lightdm/" "$ROOT/etc/lightdm/lightdm.conf.d/" >> "$R" 2>&1
grep -rn 'autologin' "$ROOT/etc/lightdm/" >> "$R" 2>&1
say "--- greeter"; nc "$ROOT/etc/lightdm/lightdm-gtk-greeter.conf" >> "$R"
say "--- sudoers.d"; ls "$ROOT/etc/sudoers.d/" >> "$R" 2>&1
[ -e "$ROOT/etc/xdg/autostart/light-locker.desktop" ] && check PASS "light-locker autostart ipo (lock screen)" || check FAIL "light-locker autostart haipo"
say "--- autostart"; ls "$ROOT/etc/xdg/autostart/" >> "$R" 2>&1

# ---------- Wallpaper ----------
sec "Wallpaper ya desktop"
find "$ROOT/usr/share/desktop-base" -path '*wallpaper/contents/images/*' -type l 2>/dev/null | head -10 | while read -r l; do
    say "$l -> $(readlink "$l")"; done
find "$ROOT/usr/share/desktop-base" -path '*wallpaper/contents/images/*' -type l -lname '*uhuru-os*' 2>/dev/null | grep -q . \
    && check PASS "wallpaper za desktop-base zinaelekeza Uhuru" || check FAIL "wallpaper za desktop-base HAZIELEKEZI Uhuru"
say "--- alternatives desktop-background"; head -12 "$ROOT/var/lib/dpkg/alternatives/desktop-background" >> "$R" 2>&1

# ---------- Browsers ----------
sec "Browsers (policies)"
for j in etc/chromium/policies/managed/uhuru-os.json usr/lib/firefox-esr/distribution/policies.json; do
    if [ -f "$ROOT/$j" ]; then
        python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$ROOT/$j" 2>/dev/null \
            && check PASS "JSON sahihi: $j" || check FAIL "JSON mbaya: $j"
    else check FAIL "haipo: $j"; fi
done

# ---------- Calamares ----------
sec "Calamares"
C="$ROOT/etc/calamares"
if [ -d "$C" ]; then
    say "--- settings.conf"; nc "$C/settings.conf" | head -80 >> "$R"
    for m in packages bootloader users removeuser; do
        say "--- modules/$m.conf"; nc "$C/modules/$m.conf" | head -40 >> "$R"
    done
    grep -q 'bootloader' "$C/settings.conf" 2>/dev/null && check INFO "calamares: bootloader iko kwenye sequence" || check FAIL "calamares: bootloader haipo kwenye sequence"
    if grep -Eqi 'grub' "$C/modules/packages.conf" 2>/dev/null; then check INFO "calamares: packages.conf inataja grub"; else check INFO "calamares: packages.conf haitaji grub"; fi
    say "--- 'Debian' iliyobaki kwenye branding"; grep -rIn 'Debian' "$C/branding" 2>/dev/null | head -15 >> "$R"
else
    check FAIL "etc/calamares haipo"
fi

# ---------- Mwisho ----------
sec "Mwisho"
say "ripoti imeandikwa: $R"
check INFO "ukaguzi umekamilika; angalia report.txt kwenye artifact uhuru-os-report"
exit 0
