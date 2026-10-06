# Sidequest

Sidequest trasforma micro-momenti in missioni da fare e immortalare con la propria crew. Il prototipo statico funziona senza account o servizi a pagamento; le stanze testuali private in tempo reale sono predisposte su Supabase (free tier), ma richiedono un progetto del gestore.

## Provalo subito

Apri il server locale con `./start.ps1`, oppure avvia `python -m http.server 8000` da questa cartella e visita `http://localhost:8000/`. Non servono dipendenze né una build.

## Cosa funziona

- 12 missioni integrate, filtri per durata e contesto, estrazione casuale e inviti con URL che porta la missione.
- Creazione locale di missioni personalizzate e conteggio delle missioni completate.
- Foto ridimensionate e archiviate soltanto sul dispositivo; card verticale pronta da scaricare o condividere nelle storie.
- Album locale con fino a 18 foto compresse, PWA installabile e shell offline.
- Stanze private a invito con messaggi testo e sincronizzazione real-time tramite Supabase, quando configurato. Nessuna foto viene caricata nella stanza.
- Limite di lunghezza dei messaggi, nickname limitati, policy Row Level Security, iscrizioni anonime persistenti e rate limit lato client.
- Nessun tracker pubblicitario o analytics di terzi nella versione iniziale.

## Monetizzare in modo trasparente

Il prodotto non mostra annunci nei controlli di gioco e non usa AdSense. Quando esisterà un accordo reale, il gestore può aggiungere fino a otto missioni sponsorizzate in `config.js`; vengono validate e mostrate con etichetta promozionale visibile e link HTTPS. Un link affiliato va inserito solo dopo l'approvazione del programma e con disclosure adeguata. Il funnel è: contenuto social → missione condivisa → invito alla crew → missione sponsorizzata dichiarata → visita tracciata dal partner o commissione. Non inventare partner o ricavi prima di avere pubblico e accordi.

## Attivare le stanze live

1. Crea un progetto Supabase sul piano gratuito e abilita **Anonymous Sign-Ins** in Authentication → Providers/Sign In.
2. In SQL Editor esegui il file `supabase-schema.sql`.
3. Copia Project URL e chiave `anon`/`publishable` in `config.js` (`supabaseUrl` e `supabaseAnonKey`). Non inserire mai la chiave `service_role`.
4. Pubblica il commit sul repository GitHub collegato a Cloudflare Pages. La stanza live si attiva automaticamente; la modalità locale continua a funzionare se Supabase non è raggiungibile.

Gli inviti sono segreti di accesso: chiunque abbia il link entra nella stanza. Condividilo soltanto con la crew. Il backend memorizza nickname e messaggi testuali; foto e ricordi restano locali. Le stanze sono protette da RLS e non hanno elenco pubblico o ricerca globale. Dal dashboard Supabase puoi eliminare una stanza e i relativi messaggi eliminando la riga in `sq_rooms`.

## Pubblicazione e costi

Il sito è statico e non richiede un processo server sempre attivo. Collega la radice di questo repository a Cloudflare Pages con framework `None`, comando di build vuoto e cartella di output `.`; il provider assegna un sottodominio `pages.dev`. Prima di attivare pagamenti o sponsorizzazioni, verifica i termini aggiornati del piano hosting.

Non serve comprare subito un dominio. Un sottodominio provider come `nome.pages.dev` va bene per la prova; Cloudflare Pages documenta 500 build al mese e 20.000 file nel piano Free. Verifica i termini Cloudflare prima di accettare pagamenti o sponsorizzazioni. Un dominio proprio si compra quando un partner pilota o la distribuzione ne giustificano il costo.

Le stanze real-time sono facoltative e usano Supabase. Il piano Free è adatto a prove con attività, ma i progetti poco attivi possono essere messi in pausa dopo sette giorni; controlla quote e stato nel dashboard. Non c’è un server da mantenere in esecuzione.

Terraform e Kubernetes non servono in questa fase. Il sito è statico; le stanze usano un servizio gestito. Valuta IaC quando gestisci più ambienti o risorse ripetibili. Valuta Kubernetes solo se volume, requisiti o dimensione del team richiedono davvero di gestire un cluster.

## Modello e acquisizione

Missione divertente → utente crea/scatta una prova → card condivisa nelle storie e link missione invitano la crew → stanza privata crea ritorno e contenuti. Dopo aver misurato inviti e ritorno, la prima monetizzazione predisposta è una missione sponsorizzata dichiarata; i pacchetti tema possono arrivare se il gruppo li richiede. Niente annunci vicini ai pulsanti di gioco o disegnati per clic accidentali.

## Privacy e limiti della versione

La modalità locale usa `localStorage`; rimuovi i dati del sito dal browser per cancellare missioni e foto. La sincronizzazione Supabase richiede rete. Le immagini non lasciano il dispositivo. Il prodotto è impostato per partire con giovani adulti (18+); prima di aprire community pubbliche, caricare immagini o rivolgersi a minorenni servono moderazione, segnalazione e procedure privacy/sicurezza più ampie. La stanza è una beta testuale privata a invito, non una chat pubblica.

La pagina privacy è informativa per il prototipo e va completata con identità e contatti del gestore prima di raccogliere dati o lanciare commercialmente.

## Manutenzione

- Le missioni base si modificano all'inizio di `app.js`.
- La cache PWA si aggiorna incrementando `CACHE` in `sw.js`.
- Per cambiare le quote Supabase osserva il progetto nel dashboard e ruota/disattiva le credenziali se hai pubblicato per errore un service key.

