# Deploy web PROD (pitlap.app)

1. `.\build_web_prod.bat`
   - genera le pagine SEO da prod (`tools/build_seo_pages.py`), poi `flutter build web`
   - se la generazione SEO fallisce la build si ferma (serve Python: `winget install -e --id Python.Python.3.12`)
2. Pubblica `app\build\web\` su Cloudflare Pages (progetto `pitlap`, direct upload)
3. Torna sul terminale del bat e premi un tasto: invia gli URL a IndexNow (Bing, Yandex...)
   - risposta attesa `HTTP 200` o `202`; `403` = deploy non ancora online, riprova con
     `py tools\build_seo_pages.py --indexnow`
4. Controllo rapido in anonimo: `https://pitlap.app/`, `https://pitlap.app/sitemap.xml`,
   `https://pitlap.app/piste/srb-offroad-nembro/` (HTML statico, non l'app)

Google non usa IndexNow: legge la sitemap da solo (Search Console, account beppe.apps).
Cloudflare Crawler Hints e' attivo e segnala in automatico le pagine cambiate.
