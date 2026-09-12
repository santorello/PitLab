# Template email Auth — PitLap

Da incollare in Supabase → **Authentication → Email Templates** (dev e, al go-live, prod).
Ogni template ha **Subject** e **Body (HTML)**. Le variabili `{{ .ConfirmationURL }}` /
`{{ .Token }}` sono sostituite da Supabase, non toccarle.

> Nota: al momento le email partono dal mittente di default Supabase con limiti bassi.
> Per il go-live va configurato l'SMTP personalizzato (Resend) — vedi TODO progetto.

---

## 1. Magic Link

**Subject**
```
Il tuo link di accesso a PitLap
```
**Body**
```html
<div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;color:#1f2937">
  <div style="font-size:22px;font-weight:800;margin-bottom:16px">Pit<span style="color:#F97316">Lap</span></div>
  <p>Hai richiesto un link di accesso per entrare in PitLap.</p>
  <p>Premi il pulsante qui sotto per accedere. Il link è personale e valido per un tempo limitato.</p>
  <p style="margin:28px 0">
    <a href="{{ .ConfirmationURL }}" style="background:#F97316;color:#fff;text-decoration:none;padding:14px 24px;border-radius:10px;font-weight:700;display:inline-block">Apri PitLap</a>
  </p>
  <p style="font-size:13px;color:#6b7280">Se il pulsante non funziona, apri questo link:</p>
  <p style="font-size:12px;word-break:break-all"><a href="{{ .ConfirmationURL }}">{{ .ConfirmationURL }}</a></p>
  <p style="font-size:13px;color:#6b7280">Se non hai richiesto l'accesso, puoi ignorare questa email.</p>
</div>
```

---

## 2. Confirm signup (Conferma registrazione)

**Subject**
```
Conferma la tua registrazione a PitLap
```
**Body**
```html
<div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;color:#1f2937">
  <div style="font-size:22px;font-weight:800;margin-bottom:16px">Pit<span style="color:#F97316">Lap</span></div>
  <p>Benvenuto in PitLap!</p>
  <p>Conferma il tuo indirizzo email per attivare l'account. Il link è valido per un tempo limitato.</p>
  <p style="margin:28px 0">
    <a href="{{ .ConfirmationURL }}" style="background:#F97316;color:#fff;text-decoration:none;padding:14px 24px;border-radius:10px;font-weight:700;display:inline-block">Conferma registrazione</a>
  </p>
  <p style="font-size:13px;color:#6b7280">Se il pulsante non funziona, apri questo link:</p>
  <p style="font-size:12px;word-break:break-all"><a href="{{ .ConfirmationURL }}">{{ .ConfirmationURL }}</a></p>
  <p style="font-size:13px;color:#6b7280">Se non hai creato tu un account PitLap, puoi ignorare questa email.</p>
</div>
```

---

## 3. Invite user (Invito)

**Subject**
```
Sei stato invitato su PitLap
```
**Body**
```html
<div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;color:#1f2937">
  <div style="font-size:22px;font-weight:800;margin-bottom:16px">Pit<span style="color:#F97316">Lap</span></div>
  <p>Sei stato invitato a entrare in PitLap, la community del modellismo RC.</p>
  <p>Premi il pulsante qui sotto per accettare l'invito e creare il tuo accesso.</p>
  <p style="margin:28px 0">
    <a href="{{ .ConfirmationURL }}" style="background:#F97316;color:#fff;text-decoration:none;padding:14px 24px;border-radius:10px;font-weight:700;display:inline-block">Accetta invito</a>
  </p>
  <p style="font-size:13px;color:#6b7280">Se il pulsante non funziona, apri questo link:</p>
  <p style="font-size:12px;word-break:break-all"><a href="{{ .ConfirmationURL }}">{{ .ConfirmationURL }}</a></p>
  <p style="font-size:13px;color:#6b7280">Se non ti aspettavi questo invito, puoi ignorare questa email.</p>
</div>
```

---

## 4. Reset password (Reimposta password)

**Subject**
```
Reimposta la tua password PitLap
```
**Body**
```html
<div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;color:#1f2937">
  <div style="font-size:22px;font-weight:800;margin-bottom:16px">Pit<span style="color:#F97316">Lap</span></div>
  <p>Hai richiesto di reimpostare la password del tuo account PitLap.</p>
  <p>Premi il pulsante qui sotto per scegliere una nuova password. Il link è valido per un tempo limitato.</p>
  <p style="margin:28px 0">
    <a href="{{ .ConfirmationURL }}" style="background:#F97316;color:#fff;text-decoration:none;padding:14px 24px;border-radius:10px;font-weight:700;display:inline-block">Reimposta password</a>
  </p>
  <p style="font-size:13px;color:#6b7280">Se il pulsante non funziona, apri questo link:</p>
  <p style="font-size:12px;word-break:break-all"><a href="{{ .ConfirmationURL }}">{{ .ConfirmationURL }}</a></p>
  <p style="font-size:13px;color:#6b7280">Se non hai richiesto tu il reset, puoi ignorare questa email: la password resta invariata.</p>
</div>
```

---

## 5. Change email address (Conferma nuova email)

**Subject**
```
Conferma il cambio email su PitLap
```
**Body**
```html
<div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;color:#1f2937">
  <div style="font-size:22px;font-weight:800;margin-bottom:16px">Pit<span style="color:#F97316">Lap</span></div>
  <p>Hai richiesto di cambiare l'indirizzo email del tuo account PitLap.</p>
  <p>Premi il pulsante qui sotto per confermare il nuovo indirizzo.</p>
  <p style="margin:28px 0">
    <a href="{{ .ConfirmationURL }}" style="background:#F97316;color:#fff;text-decoration:none;padding:14px 24px;border-radius:10px;font-weight:700;display:inline-block">Conferma nuova email</a>
  </p>
  <p style="font-size:13px;color:#6b7280">Se il pulsante non funziona, apri questo link:</p>
  <p style="font-size:12px;word-break:break-all"><a href="{{ .ConfirmationURL }}">{{ .ConfirmationURL }}</a></p>
  <p style="font-size:13px;color:#6b7280">Se non hai richiesto tu il cambio, ignora questa email e contattaci.</p>
</div>
```

---

## 6. Reauthentication (Codice di verifica)

Questo template usa un **codice** (`{{ .Token }}`), non un link.

**Subject**
```
Codice di verifica PitLap
```
**Body**
```html
<div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;color:#1f2937">
  <div style="font-size:22px;font-weight:800;margin-bottom:16px">Pit<span style="color:#F97316">Lap</span></div>
  <p>Per confermare l'operazione, inserisci questo codice di verifica in PitLap:</p>
  <p style="margin:24px 0;font-size:30px;font-weight:800;letter-spacing:6px;color:#F97316">{{ .Token }}</p>
  <p style="font-size:13px;color:#6b7280">Il codice è valido per un tempo limitato. Se non hai richiesto questa operazione, puoi ignorare questa email.</p>
</div>
```
