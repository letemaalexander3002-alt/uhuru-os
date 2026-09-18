#!/bin/sh
# ============================================================
# Uhuru OS — Skripti ya Kujenga ISO (Awamu ya 2)
# Endesha hii kwenye mashine/seva yenye Debian 12 (bookworm)
# ============================================================
set -e

echo ">> Hatua 1/3: Kusafisha build za zamani (kama zipo)..."
sudo lb clean --purge || true

echo ">> Hatua 2/3: Kuweka mipangilio (lb config)..."
sudo lb config

echo ">> Hatua 3/3: Kujenga ISO — hii inaweza kuchukua dakika 20-60..."
sudo lb build 2>&1 | tee build.log

echo ""
echo "============================================================"
echo "IMEKAMILIKA. Angalia faili la .iso kwenye saraka hii."
echo "Kama kuna hitilafu, soma build.log kuanzia mwisho kuelekea juu."
echo "============================================================"
