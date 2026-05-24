# Supabase Dev Setup

Guida operativa per creare e collegare l'ambiente `dev` di PitLap seguendo le best practice.

## Obiettivo

- creare un progetto Supabase dedicato allo sviluppo
- mantenere `prod` separato fin dall'inizio
- collegare l'app Flutter a un backend reale senza sporcare l'ambiente futuro di produzione

## Regole guida

- creare solo `dev` adesso
- non usare mai `prod` per prove o bootstrap
- usare sempre chiavi pubbliche lato app
- non esporre mai `service_role` nel client
- documentare URL, project ref e note operative senza salvare segreti nel repository

## Naming raccomandato

Nome progetto:

- `pitlap-dev`

Database password:

- password lunga, unica, salvata in password manager

Region:

- scegliere la regione piu' vicina al pubblico iniziale reale
- per un progetto con base in Italia, preferire una regione UE

## Cosa recuperare dal progetto creato

Dal dashboard Supabase servono:

- `Project URL`
- `anon public key`
- `project ref`

Non va usata nel client:

- `service_role key`

## Procedura consigliata

### 1. Creazione progetto

Nel dashboard Supabase:

1. crea un nuovo progetto
2. assegna nome `pitlap-dev`
3. scegli organizzazione corretta
4. scegli regione UE
5. imposta password database robusta

### 2. Attendi provisioning completo

Prima di proseguire:

- attendi che database, auth e API siano pronti

### 3. Recupera i dati minimi ambiente

Nel dashboard, annota:

- URL progetto
- anon key
- project ref

### 4. Auth iniziale

Per il bootstrap:

- lascia Email auth attiva
- usa magic link o OTP email come primo flusso consigliato

### 5. Database schema

Quando il progetto `dev` e' pronto:

- applicare [schema.sql](Z:\ProgettiSviluppo\PitLap\supabase\schema.sql)
- verificare che tabelle, enum, trigger e policy siano creati correttamente

### 6. Storage

Bucket iniziali previsti:

- `track-media`
- `avatars`

Bucket futuri gia' previsti:

- `shop-media`
- `garage-media`
- `profile-media`
- `submission-media`

### 7. App configuration

L'app Flutter dovra' leggere:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Best practice:

- non hardcodare chiavi nel codice
- usare file ambiente separati per `dev` e futuro `prod`
- non versionare file con segreti sensibili

## Checklist pratica

Quando hai finito la creazione del progetto `dev`, dovresti avere:

- progetto Supabase `pitlap-dev`
- regione UE
- URL progetto
- anon key
- project ref
- email auth attiva

## Passo successivo

Dopo la creazione del progetto:

1. mi passi conferma che `dev` esiste
2. io ti guido nel collegamento Flutter
3. poi ti guido nell'applicazione dello schema iniziale
