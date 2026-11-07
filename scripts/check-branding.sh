#!/bin/bash
# Ukaguzi wa branding ya Uhuru OS kwenye ISO moja. Kila kipengele: PASS, FAIL au INFO.
ISO="$1"; REPO_SPLASH="$2"; OUT="$3"
W=/tmp/audit
rm -rf "$W" && mkdir -p "$W/bi" "$W/bg" "$W/lv"
: > "$OUT"
ok()   { echo "PASS  $1  $2" >> "$OUT"; }
bad()  { echo "FAIL  $1  $2" >> "$OUT"; }
info() { echo "INFO  $1  $2" >> "$OUT"; }

xorriso -osirrox on -indev "$ISO" -extract /isolinux "$W/bi/isolinux" >/dev/null 2>&1
xorriso -osirrox on -indev "$ISO" -extract /boot/grub "$W/bg/grub" >/dev/null 2>&1
xorriso -osirrox on -indev "$ISO" -extract /live "$W/lv" >/dev/null 2>&1
FS="$W/lv/filesystem.squashfs"
unsquashfs -d "$W/root" "$FS" >/dev/null 2>&1
R="$W/root"
SPLASH="$W/bi/isolinux/splash.png"
LC="$W/bi/isolinux/live.cfg"

# 1. Splash ya isolinux: hash ya ISO dhidi ya repo
if [ -f "$SPLASH" ]; then
  H_ISO=$(sha256sum "$SPLASH" | cut -c1-16)
  if [ -f "$REPO_SPLASH" ]; then H_REPO=$(sha256sum "$REPO_SPLASH" | cut -c1-16); else H_REPO="repo-haina-faili"; fi
  if [ "$H_ISO" = "$H_REPO" ]; then ok splash_inalingana_repo "$H_ISO"; else bad splash_inalingana_repo "iso=$H_ISO repo=$H_REPO"; fi
else
  bad splash_ipo "splash.png haipo kwenye ISO"
fi

# 2. Maandishi ya Debian kwenye bootloader (maandishi tu, si picha)
HITS=$(grep -rIl -i "debian" "$W/bi" "$W/bg" 2>/dev/null | wc -l)
if [ "$HITS" -eq 0 ]; then ok bootloader_maandishi_debian "hakuna"; else bad bootloader_maandishi_debian "faili=$HITS"; fi

# 3. Plymouth default
PD=$(unsquashfs -ll "$FS" usr/share/plymouth/themes/default.plymouth 2>/dev/null | grep -- "->" | sed 's/.*-> //')
if echo "$PD" | grep -q "uhuru-os"; then ok plymouth_default "$PD"; else bad plymouth_default "${PD:-haipo}"; fi

# 4. Initrd: theme ya uhuru ndani
INI=0
for f in "$W"/lv/initrd*; do
  [ -f "$f" ] && lsinitramfs "$f" 2>/dev/null | grep -q "plymouth/themes/uhuru-os/uhuru-os.plymouth" && INI=1
done
if [ "$INI" -eq 1 ]; then ok initrd_uhuru_theme "ipo"; else bad initrd_uhuru_theme "haipo"; fi

# 5. os-release
if grep -q 'NAME="Uhuru OS"' "$R/etc/os-release" 2>/dev/null; then ok os_release "Uhuru OS"; else bad os_release "$(grep '^NAME=' "$R/etc/os-release" 2>/dev/null)"; fi

# 6. /etc/issue
if grep -qi "uhuru" "$R/etc/issue" 2>/dev/null; then ok etc_issue "ina uhuru"; else bad etc_issue "$(head -n 1 "$R/etc/issue" 2>/dev/null)"; fi

# 7. Hostname
HN=$(cat "$R/etc/hostname" 2>/dev/null)
if [ "$HN" = "uhuru-os" ]; then ok hostname "$HN"; else bad hostname "${HN:-haipo}"; fi

# 8. Calamares: maandishi yanayoonekana
CB="$R/etc/calamares/branding/debian"
CN=$(grep -h "Debian" "$CB"/*.desc "$CB"/*.qml 2>/dev/null | wc -l)
if [ "$CN" -eq 0 ]; then ok calamares_maandishi "hakuna"; else bad calamares_maandishi "mistari=$CN"; fi

# 9. Calamares: URL za debian.org
CU=$(grep -hE "https?://[^ \"<]*debian\.org" "$CB"/*.desc "$CB"/*.qml 2>/dev/null | wc -l)
CUF=$(grep -lE "https?://[^ \"<]*debian\.org" "$CB"/*.desc "$CB"/*.qml 2>/dev/null | xargs -r -n1 basename | tr "\n" " ")
if [ "$CU" -eq 0 ]; then ok calamares_url "hakuna debian.org"; else bad calamares_url "$CUF"; fi

# 10. Launchers za desktop
LA=$(grep -li "debian" "$R"/usr/share/applications/*.desktop 2>/dev/null | xargs -r -n1 basename | tr '\n' ' ')
if [ -z "$LA" ]; then ok launchers_debian "hakuna"; else bad launchers_debian "$LA"; fi

# 11. Programu za xfce4
XH=$(ls "$R"/usr/share/xfce4/helpers/debian-* 2>/dev/null | wc -l)
if [ "$XH" -eq 0 ]; then ok xfce_helpers_debian "hakuna"; else bad xfce_helpers_debian "$XH"; fi

# 12. Icons za emblem-debian
EI=$(find "$R/usr/share/icons" -name 'emblem-debian*' 2>/dev/null | wc -l)
if [ "$EI" -eq 0 ]; then ok emblem_debian_icons "hakuna"; else bad emblem_debian_icons "$EI"; fi

# 13. desktop-base (huenda nembo ya katikati ya desktop)
DB=$(find "$R/usr/share/icons/desktop-base" "$R/usr/share/images/desktop-base" -iname '*debian*' 2>/dev/null | wc -l)
if [ "$DB" -eq 0 ]; then ok desktop_base_debian "hakuna"; else bad desktop_base_debian "$DB faili"; fi

# 14. GRUB theme ya Debian
if [ -f "$R/etc/grub.d/05_debian_theme" ]; then bad grub_theme_debian "bado ipo"; else ok grub_theme_debian "imeondolewa"; fi

# 15. Jina kamili la mtumiaji wa live (maoni hayahesabiwi)
FN=$(grep -rn "Debian Live" "$R/usr/lib/live" 2>/dev/null | grep -v ":[[:space:]]*#" | wc -l)
FNF=$(grep -rn "Debian Live" "$R/usr/lib/live" 2>/dev/null | grep -v ":[[:space:]]*#" | sed "s#$R/usr/lib/live/##" | cut -c1-120 | tr "\n" "|")
if [ "$FN" -eq 0 ]; then ok live_fullname "hakuna"; else bad live_fullname "$FNF"; fi

# 16. Maandishi ya Debian kwenye xfce4, backgrounds, applications
UV=$(grep -rIl "Debian" "$R/usr/share/xfce4" "$R/usr/share/backgrounds" "$R/usr/share/applications" 2>/dev/null | wc -l)
UVF=$(grep -rIl "Debian" "$R/usr/share/xfce4" "$R/usr/share/backgrounds" "$R/usr/share/applications" 2>/dev/null | sed "s#^$R##" | tr "\n" " ")
if [ "$UV" -eq 0 ]; then ok user_visible_debian "hakuna"; else bad user_visible_debian "$UVF"; fi

# 17. Bootappend ya Awamu 3 kwenye live.cfg
if grep -q "username=mtumiaji" "$LC" 2>/dev/null && grep -q "console=ttyS0" "$LC" 2>/dev/null; then
  ok bootappend_awamu3 "ipo"
else
  bad bootappend_awamu3 "$(grep -h append "$LC" 2>/dev/null | head -n 1)"
fi

# 18. Password ya majaribio (kwa VM tu)
if grep -q "user-default-password" "$LC" 2>/dev/null; then info password_majaribio "ipo (kwa VM tu)"; else info password_majaribio "haipo"; fi

# 19. Credit ya Letema Group Tech (kazi ya repo, iko kwenye /work wakati wa ukaguzi)
PL_ISO="$R/usr/share/plymouth/themes/uhuru-os/logo.png"
PL_REPO="config/includes.chroot/usr/share/plymouth/themes/uhuru-os/logo.png"
if [ -f "$PL_ISO" ] && [ -f "$PL_REPO" ] && [ "$(sha256sum < "$PL_ISO")" = "$(sha256sum < "$PL_REPO")" ]; then
  ok credit_plymouth_logo "inalingana na repo"
else
  bad credit_plymouth_logo "haifanani na repo au haipo"
fi

WP_ISO="$R/usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper.png"
WP_REPO="config/includes.chroot/usr/share/backgrounds/uhuru-os/uhuru-os-wallpaper.png"
if [ -f "$WP_ISO" ] && [ -f "$WP_REPO" ] && [ "$(sha256sum < "$WP_ISO")" = "$(sha256sum < "$WP_REPO")" ]; then
  ok credit_wallpaper "inalingana na repo"
else
  bad credit_wallpaper "haifanani na repo au haipo"
fi

if [ -f "$R/usr/share/pixmaps/letema-logo.png" ]; then ok credit_logo_pixmaps "ipo"; else bad credit_logo_pixmaps "haipo"; fi

if grep -q "letemagrouptech.lsicbusiness.online" "$R/usr/share/applications/uhuru-about.desktop" 2>/dev/null \
   && grep -q "letemagrouptech.lsicbusiness.online" "$R/etc/skel/Desktop/uhuru-about.desktop" 2>/dev/null; then
  ok credit_about_desktop "ipo kwenye menyu na desktop"
else
  bad credit_about_desktop "haipo au URL sio sahihi"
fi

if grep -q "Letema Group Tech" "$CB/show.qml" 2>/dev/null; then ok credit_installer_text "ipo kwenye show.qml"; else bad credit_installer_text "haipo kwenye show.qml"; fi

if [ -f "$CB/letema-logo.png" ]; then ok credit_installer_logo "ipo"; else bad credit_installer_logo "haipo"; fi

if grep -q "SUPPORT_URL=.*letemagrouptech.lsicbusiness.online" "$R/etc/os-release" 2>/dev/null; then
  ok credit_support_url "lsicbusiness.online"
else
  bad credit_support_url "$(grep '^SUPPORT_URL' "$R/etc/os-release" 2>/dev/null)"
fi

P=$(grep -c "^PASS" "$OUT"); F=$(grep -c "^FAIL" "$OUT")
echo "MUHTASARI: PASS=$P FAIL=$F" >> "$OUT"
cat "$OUT"
