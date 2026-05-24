# Supabase

Questa cartella contiene la baseline iniziale del backend PitLap.

Contenuto:

- `schema.sql`: schema iniziale con tabelle, enum, trigger, indici e policy RLS
- `seed_demo.sql`: dati demo minimi per validare il primo flusso piste
- `deltas/`: modifiche incrementali pronte da applicare senza rilanciare l'intero schema

Uso consigliato:

- validare lo schema prima in ambiente `dev`
- applicare modifiche incrementali e documentate
- allineare sempre questo materiale con `docs/backend-baseline.md`

Delta attualmente utili:

- [2026-04-09-shop-ownership.sql](Z:\ProgettiSviluppo\PitLap\supabase\deltas\2026-04-09-shop-ownership.sql): introduce `shops`, `shop_managers` e relative policy ownership-based per l'edit del negozio
- [2026-04-10-shop-follows.sql](Z:\ProgettiSviluppo\PitLap\supabase\deltas\2026-04-10-shop-follows.sql): introduce `shop_follows` come base per preferiti negozio e contatori aggregati
