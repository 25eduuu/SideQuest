# Sidequest

Web app installabile che trasforma piccoli momenti in missioni da fare e ricordare con la crew. Il progetto resta statico: Cloudflare Pages ospita il sito gratis, Supabase (piano gratuito) fornisce account, crediti e stanze live. Nessun server sempre acceso, Terraform o Kubernetes.

## Avvio locale

Apri `start.ps1` oppure esegui `python -m http.server 8000` e visita `http://localhost:8000/`. Per modalità offline non servono pacchetti. `npm test` esegue i test del motore missioni.

## Prodotto attuale

- Missioni ufficiali, filtri, quest personalizzate, condivisione link e card foto pronta per le storie. Le immagini restano nel browser.
- Account con Google OAuth e link monouso email; Apple, Discord o GitHub si possono esporre aggiungendoli a `oauthProviders` dopo averli configurati in Supabase.
- Saldo server-side: una missione ufficiale vale 10 crediti una sola volta per account. Le missioni create dagli utenti e gli account anonimi non generano crediti.
- Negozio iniziale: tre stili grafici acquistabili con crediti per le card condivisibili. I crediti non sono denaro e non sono convertibili in premi.
- Completamenti ufficiali, saldo e acquisti associati all’account e conservati su Supabase. Album e missioni personalizzate restano locali per contenere costi e dati raccolti.
- Stanze private testuali opzionali con invito. Nessuna foto viene caricata.
- Un singolo spazio pubblicitario chiaramente etichettato; per impostazione predefinita è spento e non è vicino ai controlli delle missioni.

## Collegare account e stanze

1. Crea un progetto Supabase sul piano gratuito. In **Project Settings → API** prendi Project URL e chiave pubblica `anon`/publishable e inseriscili in `config.js`. Non usare mai `service_role` nel frontend.
2. Nel Supabase **SQL Editor** esegui tutto `supabase-schema.sql`. Crea profili all’iscrizione, premi, catalogo cosmetici, acquisti sicuri e policy RLS. Le procedure di premio e acquisto verificano l’utente e i dati sul server.
3. In **Authentication → URL Configuration**, imposta Site URL a `https://sidequest-apr.pages.dev` e aggiungi la stessa origine tra i redirect consentiti.
4. In **Authentication → Providers → Google**, abilita Google. Crea un OAuth Web client in Google Cloud e inserisci il client ID e il secret nel provider Supabase. Nel client Google usa come redirect URI il callback mostrato da Supabase (formato `https://<project-ref>.supabase.co/auth/v1/callback`).
5. Abilita il collegamento manuale delle identità Supabase per permettere a chi ha già una vecchia stanza anonima di trasformarla in account senza perderla.
6. Per accesso email usa il link monouso già predisposto. Verifica impostazioni e limiti email Supabase; prima di invitare utenti, configura un mittente/SMTP affidabile se quello predefinito non è sufficiente.
7. Pubblica il commit su GitHub: Cloudflare Pages ricostruisce il sito. Crediti e acquisti richiedono rete; la parte locale continua a funzionare senza Supabase.

Gli OAuth provider aggiuntivi richiedono un’app e credenziali proprie nel provider, poi l’attivazione in Supabase e in `oauthProviders`. Il pulsante non inventa né contiene chiavi segrete.

## Annunci e ricavi

Il percorso previsto è: video/social organico → una quest provata → link condiviso alla crew → ritorno sul sito → annuncio display etichettato → impressione valida e possibile ricavo. Il ricavo non è garantito e con poco traffico sarà inizialmente molto basso; evitare scambi visite, clic propri o inviti a cliccare.

AdSense è cablato ma disattivato in `config.js`. Per accenderlo solo dopo approvazione del sito:

1. aggiungi `sidequest-apr.pages.dev` al tuo account AdSense e attendi l’approvazione;
2. crea un’unità display e inserisci il suo slot in `ads.slots.quests`;
3. imposta `ads.enabled` su `true` e pubblica;
4. verifica la CMP/messaggio di consenso per questo sito, soprattutto per SEE/Regno Unito/Svizzera, e controlla il pannello policy e le impressioni.

Il file `ads.txt` contiene l’identificativo publisher che hai fornito. Autorizza il venditore, ma da solo non approva il sito né mostra annunci. Se scegli una rete alternativa (per esempio Adsterra o Monetag), si sostituisce l’integrazione con il tag generato dal suo dashboard; il prodotto e il resto del sito non dipendono da AdSense. Attiva solo banner o annunci in pagina dichiarati, lontani dai pulsanti. Niente pop-under, overlay che intercettano tocchi o annunci confusi con le quest. Per usare video rewarded come nelle app native serve una vera app e l’SDK/formato ammesso dalla rete.

Per rimuovere ogni annuncio basta spegnere `ads.enabled`; per cancellare del tutto l’integrazione si eliminano lo spazio `#quest-ad-wrap`, il relativo loader e la riga AdSense da `ads.txt`.

## Spese e limiti

Il codice non richiede una spesa fissa per funzionare. Cloudflare Pages e Supabase hanno piani gratuiti con quote e condizioni proprie: controlla i dashboard e gli avvisi del provider; non abilitare componenti a pagamento. Account, annunci, email OAuth e CMP dipendono comunque dai rispettivi account gestore. Le chiavi pubbliche Supabase sono visibili nel sito e protette da RLS; non committare credenziali private.

## Privacy, sicurezza e manutenzione

La privacy è una bozza e contiene campi titolare/contatto da completare prima di raccogliere dati reali. Lo schema limita i messaggi in lunghezza e frequenza, usa RLS, blocca link e memorizza i premi una volta sola. Dall’account si possono cancellare identità, crediti, acquisti e stanze create dall’utente. Prima del lancio verifica informativa, retention, contatti e regole applicabili all’età del pubblico.

Le missioni base e i premi corrispondenti sono definiti rispettivamente in `core.js` e `supabase-schema.sql`: se modifichi le missioni, aggiorna anche la allowlist SQL. Per distribuire gli aggiornamenti PWA incrementa il nome cache in `sw.js`.

## Acquisizione utenti senza spam

Pubblica brevi demo originali di una missione reale su Instagram/TikTok, con invito a provarla e passare il link alla crew; alterna le missioni, mostra card generate dal prodotto e rispondi manualmente ai commenti. Il sistema già crea URL condivisibili e card verticali. Non automatizzare account o messaggi, non comprare traffico e non usare engagement bait: misurare prima accessi e ritorno con gli strumenti minimali dei provider.
