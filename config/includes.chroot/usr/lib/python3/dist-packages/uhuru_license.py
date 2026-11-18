"""uhuru_license: uthibitishaji wa leseni za programu za LGT Store (Uhuru OS v18.0).

Marekebisho dhidi ya spec ya v18.0:
- Kitambulisho cha kompyuta kinatokana na /etc/machine-id pekee, ili kipatikane kwa mtumiaji yeyote
  (product_uuid inasomwa na root pekee, ingeleta HARDWARE_MISMATCH ya uongo).
- Grace ya nje ya mtandao (offline_grace_days, chaguo-msingi 30) inatekelezwa kupitia
  tarehe ya uthibitisho wa mwisho mtandaoni, inayohifadhiwa kwenye STATE_DIR.
- Ufunguo wa umma wa placeholder unakataliwa; haukubaliki kamwe.
"""
import base64
import hashlib
import json
import os
import time
from datetime import datetime, timezone

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey

LICENSE_DIR = os.environ.get("UHURU_LICENSE_DIR", "/etc/uhuru/licenses")
STATE_DIR = os.environ.get("UHURU_LICENSE_STATE", "/var/lib/uhuru/license-state")
PUBKEY_FILE = os.environ.get("UHURU_LICENSE_PUBKEY", "/etc/uhuru/lgt-license-public.key")
MACHINE_ID = os.environ.get("UHURU_MACHINE_ID", "/etc/machine-id")
PLACEHOLDER = "REPLACE_WITH_PRODUCTION_ED25519_PUBLIC_KEY_BASE64"
DEFAULT_GRACE_DAYS = 30


def hardware_fingerprint() -> str:
    """Alama ya kompyuta: SHA-256 ya /etc/machine-id. Thabiti kwa watumiaji wote."""
    try:
        with open(MACHINE_ID, "r", encoding="utf-8") as f:
            raw = f.read().strip()
    except OSError:
        raw = ""
    if not raw:
        raise RuntimeError("MACHINE_ID_UNAVAILABLE")
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _load_public_key() -> Ed25519PublicKey:
    with open(PUBKEY_FILE, "r", encoding="utf-8") as f:
        b64 = f.read().strip()
    if not b64 or b64 == PLACEHOLDER:
        raise RuntimeError("PUBLIC_KEY_NOT_CONFIGURED")
    return Ed25519PublicKey.from_public_bytes(base64.b64decode(b64))


def _state_path(package_name: str) -> str:
    return os.path.join(STATE_DIR, package_name + ".json")


def mark_online_ok(package_name: str, now: float = None) -> None:
    """Huitwa baada ya uthibitisho wa mtandaoni uliofanikiwa; inaanzisha upya grace."""
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(_state_path(package_name), "w", encoding="utf-8") as f:
        json.dump({"last_online": int(now if now is not None else time.time())}, f)


def _last_online(package_name: str):
    try:
        with open(_state_path(package_name), "r", encoding="utf-8") as f:
            return int(json.load(f)["last_online"])
    except (OSError, ValueError, KeyError):
        return None


def verify_app_license(package_name: str, now: float = None) -> dict:
    """Inarudisha {"valid": bool, "reason": str, ...}. Haitupi exception kwa mtumiaji."""
    now = now if now is not None else time.time()
    lic_path = os.path.join(LICENSE_DIR, package_name + ".lic")
    if not os.path.exists(lic_path):
        return {"valid": False, "reason": "NO_LICENSE_FILE"}
    try:
        pub = _load_public_key()
    except RuntimeError as exc:
        return {"valid": False, "reason": str(exc)}
    except (OSError, ValueError) as exc:
        return {"valid": False, "reason": "PUBLIC_KEY_INVALID"}
    try:
        with open(lic_path, "r", encoding="utf-8") as f:
            envelope = json.load(f)
        payload_str = envelope["payload"]
        pub.verify(base64.b64decode(envelope["signature"]), payload_str.encode("utf-8"))
    except InvalidSignature:
        return {"valid": False, "reason": "INVALID_SIGNATURE"}
    except (OSError, ValueError, KeyError, TypeError):
        return {"valid": False, "reason": "MALFORMED_LICENSE"}

    data = json.loads(payload_str)
    if data.get("package_name") != package_name:
        return {"valid": False, "reason": "PACKAGE_MISMATCH"}
    try:
        current_hw = hardware_fingerprint()
    except RuntimeError as exc:
        return {"valid": False, "reason": str(exc)}
    if data.get("hardware_hash") != current_hw:
        return {"valid": False, "reason": "HARDWARE_MISMATCH"}

    expires_at = data.get("expires_at")
    if expires_at:
        exp = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
        if datetime.fromtimestamp(now, timezone.utc) > exp:
            return {"valid": False, "reason": "LICENSE_EXPIRED"}

    grace_days = int(data.get("offline_grace_days", DEFAULT_GRACE_DAYS))
    last = _last_online(package_name)
    if last is None:
        # Hakuna uthibitisho wa mtandaoni bado: anza grace sasa.
        mark_online_ok(package_name, now)
        last = int(now)
    if now - last > grace_days * 86400:
        return {"valid": False, "reason": "OFFLINE_GRACE_EXPIRED"}

    return {
        "valid": True,
        "reason": "ACTIVE",
        "license_key": data.get("license_key"),
        "expires_at": expires_at,
    }
