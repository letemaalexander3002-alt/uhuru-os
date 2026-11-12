#!/bin/bash
# Uhuru OS — subiri build + ukaguzi wa CI wa commit ya HEAD, onyesha matokeo ya e2e, na pakua ripoti.
# Matumizi (ndani ya ~/uhuru-os-repo):   bash scripts/ci-watch.sh [jina-la-saraka]     mfano: bash scripts/ci-watch.sh v139
cd "$(dirname "$0")/.." || exit 1
R=${UHURU_REPO:-letemaalexander3002-alt/uhuru-os}
TAG=${1:-v139}
DL=${UHURU_DL:-$HOME/storage/downloads}
SHA=$(git rev-parse HEAD)
echo "Commit: $SHA"
find_run() {   # find_run <workflow.yml>
    gh run list --workflow="$1" --repo "$R" -L 10 --json databaseId,headSha --jq ".[] | select(.headSha==\"$SHA\") | .databaseId" 2>/dev/null | head -1
}
wait_done() {  # wait_done <run-id> <sekunde-kati-ya-kuangalia>
    until [ "$(gh run view "$1" --repo "$R" --json status --jq .status 2>/dev/null)" = "completed" ]; do sleep "$2"; done
}
BID=""; until [ -n "$BID" ]; do BID=$(find_run build-iso.yml); [ -n "$BID" ] || sleep 10; done
echo "Build: $BID  (nasubiri hadi ikamilike...)"
wait_done "$BID" 60
BC=$(gh run view "$BID" --repo "$R" --json conclusion --jq .conclusion)
echo "MATOKEO build: $BC"
if [ "$BC" != "success" ]; then
    echo "=== Build imeshindwa. Mwisho wa logi iliyofeli ==="
    gh run view "$BID" --repo "$R" --log-failed 2>/dev/null | tail -n 40 | cut -c1-200
    exit 1
fi
IID=""; until [ -n "$IID" ]; do IID=$(find_run inspect-iso.yml); [ -n "$IID" ] || sleep 20; done
echo "Ukaguzi: $IID  (nasubiri hadi ukamilike...)"
wait_done "$IID" 30
echo "MATOKEO ukaguzi: $(gh run view "$IID" --repo "$R" --json conclusion --jq .conclusion)"
echo "=== CHECK za e2e / auth / diag ==="
gh run view "$IID" --repo "$R" --log 2>/dev/null | grep -E "CHECK (PASS|FAIL|INFO): (e2e|auth|diag)" | sed -E 's/^.*CHECK /CHECK /' | cut -c1-200
echo "=== JUMLA ==="
gh run view "$IID" --repo "$R" --log 2>/dev/null | grep -oE "CHECK (PASS|FAIL):" | sort | uniq -c
D="$DL/uhuru-report-$TAG"
mkdir -p "$D" && gh run download "$IID" --repo "$R" -n uhuru-os-report -D "$D" 2>&1 | tail -n 3
S=$(dirname "$(find "$D" -name serial.log 2>/dev/null | head -1)")
echo "=== Ripoti imehifadhiwa: $D  (picha/serial: $S) ==="
if [ -f "$S/serial.log" ]; then
    echo "### e2e.log"; cat "$S/e2e.log" 2>/dev/null
    echo "### STATE ya kwanza na ya mwisho"; tr -d '\r' < "$S/serial.log" | grep '^UHURU-STATE' | sed -n '1p;$p' | cut -c1-230
    echo "### idadi ya STATE (n ya mwisho)"; tr -d '\r' < "$S/serial.log" | grep -c '^UHURU-STATE'
    echo "### ACCOUNTS (ya kwanza na ya mwisho)"; tr -d '\r' < "$S/serial.log" | grep '^UHURU-ACCOUNTS' | sed -n '1p;$p'
    echo "### DIAG na AUTH"; tr -d '\r' < "$S/serial.log" | grep -E '^UHURU-(DIAG|AUTH)' | cut -c1-200 | tail -n 50
    echo "### makosa ya boot"; tr -d '\r' < "$S/serial.log" | grep -E 'FAILED|Failed|error' | cut -c1-170 | head -n 25
    echo "### picha:"; ls "$S" | grep '\.jpg$'
fi
