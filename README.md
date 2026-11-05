# Uhuru OS

Mfumo wa uendeshaji wa kompyuta wa kitaifa wa Tanzania, uliojengwa juu ya Debian 12 (bookworm) na XFCE.
Mahitaji kamili: Hati ya Mahitaji v1.3.

## Ujenzi
- `auto/config` — usanidi wa live-build (Debian bookworm, amd64, XFCE, Calamares).
- `config/package-lists/` — orodha ya programu.
- `.github/workflows/build-iso.yml` — ujenzi wa ISO na boot-test kwenye GitHub Actions.

Ujenzi wa ndani (Debian/Ubuntu yenye root):
```
sudo ./auto/config && sudo ./auto/build
```

Leseni ya msimbo: MIT (tazama LICENSE). Jina na nembo: alama ya biashara ya Letema Group Tech (tazama TRADEMARK.md).
