# Media Policy

## Stato attuale

PitLap, in fase pre-alpha locale e non commerciale, adotta una policy media prudente:

- immagini pubbliche persistenti tramite URL esterni gia' online
- selezione file locale usata come preview e supporto editoriale
- nessun upload binario persistente nel database
- nessuna dipendenza obbligatoria da Storage prima della validazione prodotto

## Regola operativa corrente

Per i flussi pubblici e gestionali:

- `tracks`: URL esterni consentiti
- `shops`: URL esterni consentiti
- `events`: immagini locali ammesse nel flusso utente, ma da considerare transitorie fino a pipeline storage vera
- `spots`: immagini locali/community ammesse solo nei limiti del flusso corrente
- `profile` / `garage`: preview locale consentita, persistenza media ancora non definitiva

## Cosa evitare

- salvare immagini binarie direttamente nel database
- trattare un `data:image/...` come asset definitivo di prodotto
- mostrare in UI che un file locale e' "salvato" se non esiste ancora una persistenza reale

## Strategia alpha

Fino alla migrazione online iniziale:

- politica ufficiale: URL esterni come forma affidabile di persistenza media
- picker locale: supporto editoriale / preview, non ancora storage definitivo
- copy UI esplicito quando il file locale non e' persistito lato backend

## Strategia successiva

Quando il prodotto richiedera' asset proprietari persistenti:

1. introdurre object storage reale
2. salvare in DB solo path / URL / metadati
3. aggiungere ownership, cleanup e limiti upload
4. mostrare progresso rete reale per upload

## Criteri per attivare Storage

Attivare Storage solo quando almeno uno di questi punti diventa prioritario:

- i gestori devono caricare immagini senza passare da URL esterni
- servono asset permanenti tra device e sessioni
- la UX media locale sta creando ambiguita' o supporto utente
- la gallery pubblica diventa parte centrale del valore prodotto
