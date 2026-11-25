#!/bin/bash
# Uhuru OS v19.2.3: majaribio ya Kituo cha Ulinzi (kipengele cha AppArmor kwa mtumiaji wa kawaida na root) bila ISO.
# Matumizi: bash scripts/protect-selftest.sh      (kutoka mzizi wa repo). Inahitaji python3.
set -u
REPO=${REPO:-$(cd "$(dirname "$0")/.." && pwd)}
PROT="$REPO/config/includes.chroot/usr/local/bin/uhuru-protect"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ok=0; fail=0
check() { if [ "$2" = 0 ]; then ok=$((ok+1)); else fail=$((fail+1)); echo "  FAIL: $1"; fi; }

echo "1) uhuru-protect: syntax"
python3 -m py_compile "$PROT" 2>"$T/err"; check "py_compile uhuru-protect" $?; rm -rf "$REPO/config/includes.chroot/usr/local/bin/__pycache__"

echo "2) check_apparmor: root, mtumiaji wa kawaida, kernel imezimwa"
mkdir -p "$T/root/sys/module/apparmor/parameters" "$T/root/sys/kernel/security/apparmor" "$T/root/etc/apparmor.d"
printf 'Y\n' > "$T/root/sys/module/apparmor/parameters/enabled"
printf 'usr.sbin.cupsd (enforce)\nusr.bin.man (enforce)\n' > "$T/root/sys/kernel/security/apparmor/profiles"
for f in usr.sbin.cupsd usr.bin.man sbin.dhclient; do : > "$T/root/etc/apparmor.d/$f"; done
mkdir -p "$T/root/etc/apparmor.d/abstractions"; : > "$T/root/etc/apparmor.d/abstractions/base"   # folda hazihesabiwi
cat > "$T/t.py" <<'PY'
import importlib.machinery, importlib.util, os, sys
os.environ["UHURU_PROTECT_ROOT"] = sys.argv[2]
loader = importlib.machinery.SourceFileLoader("uhuru_protect", sys.argv[1])
spec = importlib.util.spec_from_loader("uhuru_protect", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
case = sys.argv[3]
real_access = os.access
prof = os.path.join(sys.argv[2], "sys/kernel/security/apparmor/profiles")
# Ukweli kwenye ISO: /sys/kernel/security ni 0700 ya root, kwa hiyo mtumiaji wa kawaida HAONI hata faili (si 'halisomeki': halipo machoni pake).
if case in ("user-unreadable", "user-unreadable-nodisk", "root-nofile"):
    os.remove(prof)
os.geteuid = lambda: 0 if case in ("root-readable", "service-active", "kernel-off", "root-nofile") else 1000
if case == "user-unreadable-nodisk":
    for f in os.listdir(os.path.join(sys.argv[2], "etc/apparmor.d")):
        fp = os.path.join(sys.argv[2], "etc/apparmor.d", f)
        if os.path.isfile(fp): os.remove(fp)
m.run = lambda argv, timeout=6: (0, "active" if case == "service-active" else "inactive")
if case == "kernel-off":
    open(os.path.join(sys.argv[2], "sys/module/apparmor/parameters/enabled"), "w").write("N\n")
r = m.check_apparmor()
print(r[2] + "|" + r[3])
PY
run_case() { rm -rf "$T/rc"; cp -r "$T/root" "$T/rc"; python3 "$T/t.py" "$PROT" "$T/rc" "$1" 2>&1 | tail -n 1; }   # kila kesi ina nakala yake ya mti (kesi zinafuta faili)
out=$(run_case root-readable);            eq() { case "$1" in "$2"*) check "$3" 0 ;; *) check "$3 (imepatikana: $1)" 1 ;; esac; }
eq "$out" "ok|Imewashwa: profile 2 zimepakiwa" "root: profile zinasomeka, huduma inactive -> ok (tabia ya zamani haijabadilika)"
out=$(run_case service-active);           eq "$out" "ok|Imewashwa: programu zimefungwa" "huduma active -> ok (tabia ya zamani)"
out=$(run_case user-unreadable);          eq "$out" "ok|Imewashwa kwenye kernel; profile 3 zimewekwa" "mtumiaji wa kawaida: /sys/kernel/security haionekani, profile 3 zipo kwenye diski (folda hazihesabiwi) -> ok, SI hatari ya uongo (hali halisi ya CI)"
out=$(run_case root-nofile);              eq "$out" "bad|Haijawashwa" "root bila faili la profile la kernel -> bado bad (fallback ni ya mtumiaji wa kawaida tu)"
out=$(run_case user-unreadable-nodisk);   eq "$out" "bad|Haijawashwa" "mtumiaji wa kawaida: profile hazisomeki na hazipo kwenye diski -> bado bad (ukaguzi haujalegezwa)"
out=$(run_case kernel-off);               eq "$out" "bad|Haijawashwa" "kernel imezimwa -> bad hata kama profile zipo kwenye diski"

echo "2b) check_apparmor kama mtumiaji HALISI asiye root (ruhusa halisi za mfumo wa faili, bila kubadilisha os.*)"
if [ "$(id -u)" = 0 ] && id nobody >/dev/null 2>&1; then
    chmod 755 "$T"
    RT="$T/rt"; mkdir -p "$RT/sys/module/apparmor/parameters" "$RT/sys/kernel/security/apparmor" "$RT/etc/apparmor.d"
    printf 'Y\n' > "$RT/sys/module/apparmor/parameters/enabled"
    printf 'usr.sbin.cupsd (enforce)\n' > "$RT/sys/kernel/security/apparmor/profiles"
    for f in usr.sbin.cupsd usr.bin.man sbin.dhclient; do : > "$RT/etc/apparmor.d/$f"; done
    chmod -R a+rX "$RT/sys/module" "$RT/etc"; chmod a+rx "$RT" "$RT/sys" "$RT/sys/kernel"
    chmod 400 "$RT/sys/kernel/security/apparmor/profiles"; chmod 700 "$RT/sys/kernel/security" "$RT/sys/kernel/security/apparmor"   # kama /sys/kernel/security halisi: root pekee
    cat > "$T/real.py" <<'EOPY'
import importlib.machinery, importlib.util, os, sys
os.environ["UHURU_PROTECT_ROOT"] = sys.argv[2]
if sys.argv[3] == "nobody":
    os.setgid(65534); os.setuid(65534)
loader = importlib.machinery.SourceFileLoader("uhuru_protect", sys.argv[1])
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("uhuru_protect", loader)); loader.exec_module(m)
m.run = lambda argv, timeout=6: (0, "inactive")   # huduma 'inactive' kama kwenye live ya CI
r = m.check_apparmor(); print(r[2] + "|" + r[3])
EOPY
    cp "$PROT" "$T/prot.py"; chmod 644 "$T/prot.py"; chmod 644 "$T/real.py"
    out=$(python3 "$T/real.py" "$T/prot.py" "$RT" nobody 2>&1 | tail -n 1)
    case "$out" in "ok|Imewashwa kwenye kernel; profile 3 zimewekwa"*) check "mtumiaji halisi 'nobody': /sys/kernel/security 0700 -> ok (si hatari ya uongo)" 0 ;; *) check "mtumiaji halisi 'nobody' (imepatikana: $out)" 1 ;; esac
    out=$(python3 "$T/real.py" "$T/prot.py" "$RT" root 2>&1 | tail -n 1)
    case "$out" in "ok|Imewashwa: profile 1 zimepakiwa"*) check "root halisi: profile zinasomeka -> ok (njia ya zamani)" 0 ;; *) check "root halisi (imepatikana: $out)" 1 ;; esac
else
    echo "  (si root au mtumiaji 'nobody' hayupo: jaribio la mtumiaji halisi limeruka)"
fi

echo "3) --check kwa muundo halisi"
python3 "$PROT" --check >"$T/chk" 2>&1; rc=$?; head -c 300 "$T/chk" | grep -q '^PROTECT-' ; check "uhuru-protect --check inatoa mstari wa PROTECT-... (msimbo $rc)" $?
rm -rf "$REPO/config/includes.chroot/usr/local/bin/__pycache__"

echo
echo "=== JUMLA: $ok OK, $fail FAIL ==="
[ "$fail" = 0 ]
