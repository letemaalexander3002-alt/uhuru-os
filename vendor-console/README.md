# Letema Group Tech · Vendor Console

`index.html` ni programu ya ukurasa mmoja (haina seva) ya kuongeza, kuhariri na kuficha bidhaa za PWA kwenye LGT Store.
Inaandika faili `vendor-catalog/catalog.json` kwenye repo hii kupitia GitHub API; LGT Store ya kila kompyuta ya Uhuru OS inalisoma yenyewe.

- Fungua `index.html` kwenye simu au kompyuta (au washa GitHub Pages kwa repo hii).
- Weka GitHub token (fine-grained, ruhusa `Contents: Read and write` kwa repo hii pekee). Token inabaki kwenye kifaa chako tu.
- Kila "Hifadhi na Chapisha" ni commit yenye `[skip ci]`: haianzishi build ya ISO.
- Katalogi ya mbali inaweza kuongeza PWA tu (https). Haiwezi kusakinisha programu za Debian wala kuendesha amri.
- Repo lazima iwe ya umma (public) ili kompyuta za watumiaji ziweze kusoma `vendor-catalog/catalog.json`.
