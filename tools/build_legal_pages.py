#!/usr/bin/env python3
"""Genera le pagine legali statiche pubbliche da docs/legal/*.md in app/web/legal/.

Perche' esiste: Google Play e l'Apple App Store richiedono una URL pubblica
della privacy policy raggiungibile SENZA installare l'app e SENZA login. Le
pagine generate qui sono HTML puro, senza JavaScript, cosi' restano leggibili
anche se la web app Flutter e' rotta o non carica.

Uso (dalla root del repo):
    python tools/build_legal_pages.py

Nessuna dipendenza esterna: il sottoinsieme di Markdown usato nei documenti
legali (titoli, grassetto, corsivo, codice inline, link, liste, tabelle,
righe orizzontali) e' convertito da questo file.

Dopo la generazione ricordarsi che app/web/_redirects deve escludere /legal/*
PRIMA della catch-all SPA, altrimenti Cloudflare Pages serve index.html.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "legal"
OUT = ROOT / "app" / "web" / "legal"

# Solo i documenti destinati al pubblico. consent-register.md e' interno
# (registro dei trattamenti/consensi) e non va pubblicato.
PAGES = {
    "privacy-policy.md": ("privacy-policy.html", "Privacy Policy"),
    "terms-of-service.md": ("termini-di-servizio.html", "Termini di Servizio"),
    "cookie-policy.md": ("cookie-policy.html", "Cookie Policy"),
}

CSS = """
:root { color-scheme: light dark; --fg:#15181c; --bg:#ffffff; --muted:#5b6472;
        --rule:#d9dee5; --accent:#c8102e; --code:#f2f4f7; }
@media (prefers-color-scheme: dark) {
  :root { --fg:#e7eaee; --bg:#14171b; --muted:#9aa4b2; --rule:#2c323a;
          --accent:#ff5c72; --code:#1e232a; }
}
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--fg);
       font:16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
       -webkit-text-size-adjust:100%; }
.wrap { max-width:46rem; margin:0 auto; padding:2.5rem 1.25rem 4rem; }
header.site { border-bottom:1px solid var(--rule); padding-bottom:1rem; margin-bottom:2rem; }
header.site a { color:var(--accent); text-decoration:none; font-weight:700; letter-spacing:.02em; }
h1 { font-size:1.75rem; line-height:1.25; margin:0 0 1rem; }
h2 { font-size:1.25rem; margin:2.25rem 0 .75rem; }
h3 { font-size:1.05rem; margin:1.75rem 0 .5rem; }
p, li { overflow-wrap:break-word; }
a { color:var(--accent); }
hr { border:0; border-top:1px solid var(--rule); margin:2rem 0; }
code { background:var(--code); padding:.1em .35em; border-radius:4px; font-size:.9em; }
ul, ol { padding-left:1.35rem; }
.table-scroll { overflow-x:auto; margin:1rem 0; }
table { border-collapse:collapse; width:100%; font-size:.93rem; }
th, td { border:1px solid var(--rule); padding:.5rem .65rem; text-align:left; vertical-align:top; }
th { background:var(--code); }
footer.site { border-top:1px solid var(--rule); margin-top:3rem; padding-top:1rem;
              color:var(--muted); font-size:.875rem; }
footer.site a { margin-right:1rem; }
"""

TEMPLATE = """<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} — PitLap</title>
<meta name="description" content="{title} di PitLap, piattaforma per la community del modellismo radiocomandato.">
<meta name="robots" content="index, follow">
<style>{css}</style>
</head>
<body>
<div class="wrap">
<header class="site"><a href="/">PitLap</a></header>
<main>
{body}
</main>
<footer class="site">
<a href="/legal/privacy-policy.html">Privacy Policy</a>
<a href="/legal/termini-di-servizio.html">Termini di Servizio</a>
<a href="/legal/cookie-policy.html">Cookie Policy</a>
<p>Titolare: Giuseppe Santoro — Rho (MI), Italia — beppe.apps@gmail.com</p>
</footer>
</div>
</body>
</html>
"""


def inline(text: str) -> str:
    out = html.escape(text, quote=False)
    out = re.sub(r"`([^`]+)`", lambda m: "<code>%s</code>" % m.group(1), out)
    out = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', out)
    out = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", out)
    out = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", out)
    return out


def is_table_sep(line: str) -> bool:
    return bool(re.fullmatch(r"\|[\s:|-]+\|", line.strip()))


def cells(line: str) -> list[str]:
    return [c.strip() for c in line.strip().strip("|").split("|")]


def is_block_start(stripped: str) -> bool:
    """Una riga che apre un blocco diverso dal paragrafo.

    Attenzione: il controllo deve essere fatto con regex e non con
    startswith("*"), altrimenti una riga in grassetto come
    "**Versione: 1.1**" verrebbe scambiata per un elenco puntato e persa.
    """
    return bool(
        re.match(r"#{1,6}\s", stripped)
        or stripped.startswith("|")
        or stripped.startswith(">")
        or re.match(r"[-*+]\s", stripped)
        or re.match(r"\d+[.)]\s", stripped)
        or re.fullmatch(r"-{3,}|\*{3,}|_{3,}", stripped)
    )


def convert(md: str) -> str:
    lines = md.splitlines()
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if not stripped:
            i += 1
            continue

        if re.fullmatch(r"-{3,}|\*{3,}|_{3,}", stripped):
            out.append("<hr>")
            i += 1
            continue

        m = re.match(r"(#{1,6})\s+(.*)", stripped)
        if m:
            lvl = len(m.group(1))
            out.append("<h%d>%s</h%d>" % (lvl, inline(m.group(2)), lvl))
            i += 1
            continue

        # Tabella: riga di intestazione seguita dal separatore.
        if stripped.startswith("|") and i + 1 < len(lines) and is_table_sep(lines[i + 1]):
            head = cells(stripped)
            i += 2
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append(cells(lines[i]))
                i += 1
            out.append('<div class="table-scroll"><table><thead><tr>')
            out.append("".join("<th>%s</th>" % inline(c) for c in head))
            out.append("</tr></thead><tbody>")
            for row in rows:
                out.append("<tr>%s</tr>" % "".join("<td>%s</td>" % inline(c) for c in row))
            out.append("</tbody></table></div>")
            continue

        # Liste (puntate o numerate), con continuazione su righe rientrate.
        bullet = re.match(r"[-*+]\s+(.*)", stripped)
        number = re.match(r"\d+[.)]\s+(.*)", stripped)
        if bullet or number:
            tag = "ul" if bullet else "ol"
            items: list[str] = []
            pattern = r"[-*+]\s+(.*)" if bullet else r"\d+[.)]\s+(.*)"
            while i < len(lines):
                cur = lines[i].strip()
                m2 = re.match(pattern, cur) if cur else None
                if m2:
                    items.append(m2.group(1))
                elif cur and lines[i].startswith(("  ", "\t")) and items:
                    items[-1] += " " + cur
                else:
                    break
                i += 1
            out.append("<%s>" % tag)
            out.extend("<li>%s</li>" % inline(it) for it in items)
            out.append("</%s>" % tag)
            continue

        # Paragrafo: righe consecutive non vuote e non speciali.
        para: list[str] = []
        while i < len(lines):
            cur = lines[i].strip()
            if not cur or is_block_start(cur):
                break
            para.append(cur)
            i += 1
        if para:
            out.append("<p>%s</p>" % "<br>".join(inline(x) for x in para))
        else:
            i += 1

    return "\n".join(out)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for src_name, (out_name, title) in PAGES.items():
        src = SRC / src_name
        body = convert(src.read_text(encoding="utf-8"))
        page = TEMPLATE.format(title=html.escape(title), css=CSS, body=body)
        (OUT / out_name).write_text(page, encoding="utf-8", newline="\n")
        print("scritto %s (%d byte)" % (out_name, len(page.encode("utf-8"))))


if __name__ == "__main__":
    main()
