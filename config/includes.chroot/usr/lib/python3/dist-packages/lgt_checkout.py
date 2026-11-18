"""lgt_checkout: msaidizi wa malipo ya M-Pesa STK Push kwa LGT Store (Uhuru OS v18.0, Awamu C).

Moduli hii haibadilishi uhuru-store. Inatoa kazi safi ambazo uhuru-store itaziita:
- normalize_msisdn(): 07XXXXXXXX / +2557XXXXXXXX / 2557XXXXXXXX -> 2557XXXXXXXX
- format_tzs(): 15000 -> "TZS 15,000"
- initiate_checkout(): POST /api/v1/checkout/initiate
- poll_checkout(): GET /api/v1/checkout/status/{ref} hadi COMPLETED/FAILED au muda uishe
- install_license(): kuhifadhi faili lililosainiwa la .lic kwa usalama (mode 0644, atomic)
"""
import json
import os
import re
import tempfile
import time
import urllib.error
import urllib.request

DEFAULT_BASE = os.environ.get("LGT_API_BASE", "https://api.store.lsicbusiness.online")
LICENSE_DIR = os.environ.get("UHURU_LICENSE_DIR", "/etc/uhuru/licenses")
_PHONE_RE = re.compile(r"^255[67][0-9]{8}$")


class CheckoutError(Exception):
    pass


def normalize_msisdn(raw: str) -> str:
    """Inarudisha namba ya Tanzania katika muundo wa 2557XXXXXXXX au 2556XXXXXXXX."""
    digits = re.sub(r"[\s\-+()]", "", raw or "")
    if digits.startswith("0") and len(digits) == 10:
        digits = "255" + digits[1:]
    if not _PHONE_RE.match(digits):
        raise CheckoutError("NAMBA_SI_SAHIHI")
    return digits


def format_tzs(amount) -> str:
    """Inaumba kiasi cha TZS kwa mfano: 15000 -> 'TZS 15,000'."""
    try:
        value = int(round(float(amount)))
    except (TypeError, ValueError):
        raise CheckoutError("KIASI_SI_SAHIHI")
    if value < 0:
        raise CheckoutError("KIASI_SI_SAHIHI")
    return "TZS {:,}".format(value)


def _require_secure(base: str, allow_insecure: bool) -> None:
    if base.startswith("https://"):
        return
    local = base.startswith("http://127.0.0.1") or base.startswith("http://localhost")
    if allow_insecure and local:
        return
    raise CheckoutError("HTTPS_INAHITAJIKA")


def _request(method: str, url: str, body: dict = None, timeout: int = 20) -> dict:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"Content-Type": "application/json", "Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as exc:
        raise CheckoutError("HTTP_%d" % exc.code)
    except (urllib.error.URLError, TimeoutError, ValueError):
        raise CheckoutError("MTANDAO_HAUPATIKANI")


def initiate_checkout(app_id: str, phone: str, hardware_hash: str, provider: str = "MPESA_TZ",
                      base: str = DEFAULT_BASE, allow_insecure: bool = False) -> dict:
    """Inaanzisha STK Push. Inarudisha {'ref': ..., 'status': 'PENDING'} kutoka seva."""
    _require_secure(base, allow_insecure)
    if provider not in ("MPESA_TZ", "TIGOPESA", "AIRTEL_TZ"):
        raise CheckoutError("MTOAJI_HAJULIKANI")
    payload = {
        "app_id": app_id,
        "phone_number": normalize_msisdn(phone),
        "provider": provider,
        "hardware_hash": hardware_hash,
    }
    res = _request("POST", base.rstrip("/") + "/api/v1/checkout/initiate", payload)
    if "ref" not in res:
        raise CheckoutError("JIBU_SIO_SAHIHI")
    return res


def poll_checkout(ref: str, base: str = DEFAULT_BASE, allow_insecure: bool = False,
                  attempts: int = 60, interval: float = 3.0, sleep=time.sleep) -> dict:
    """Inangoja hadi COMPLETED au FAILED. Inarudisha jibu la mwisho (pamoja na 'license' ikiwa ipo)."""
    _require_secure(base, allow_insecure)
    url = base.rstrip("/") + "/api/v1/checkout/status/" + urllib.request.quote(ref, safe="")
    last = {"status": "PENDING"}
    for _ in range(attempts):
        last = _request("GET", url)
        if last.get("status") in ("COMPLETED", "FAILED", "REFUNDED"):
            return last
        sleep(interval)
    raise CheckoutError("MUDA_UMEISHA")


def install_license(package_name: str, license_envelope: dict, license_dir: str = LICENSE_DIR) -> str:
    """Inaandika leseni iliyosainiwa kwa atomic (tempfile + rename), mode 0644. Inarudisha njia ya faili."""
    if not re.match(r"^[a-z0-9][a-z0-9.\-]{1,149}$", package_name or ""):
        raise CheckoutError("JINA_LA_KIFURUSHI_SIO_SAHIHI")
    if not isinstance(license_envelope, dict) or "payload" not in license_envelope or "signature" not in license_envelope:
        raise CheckoutError("LEESENI_SI_SAHIHI")
    os.makedirs(license_dir, exist_ok=True)
    final = os.path.join(license_dir, package_name + ".lic")
    fd, tmp = tempfile.mkstemp(dir=license_dir, prefix=".tmp-", suffix=".lic")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(license_envelope, fh)
        os.chmod(tmp, 0o644)  # leseni imesainiwa; ni lazima isomeke na programu (mtumiaji wa kawaida)
        os.replace(tmp, final)
    except Exception:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise
    return final
