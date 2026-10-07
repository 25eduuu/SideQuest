# Sidequest

SideQuest è un’app mobile in sviluppo che trasforma piccoli momenti in missioni da fare e ricordare con la crew. La homepage è una vetrina statica per raccontare il prodotto e annunciare la beta; l’app nativa è in `mobile/`. Cloudflare Pages ospita la vetrina, Supabase (piano gratuito) fornisce account, crediti e crew. Nessun server sempre acceso.

## Avvio locale

Apri `start.ps1` oppure esegui `python -m http.server 8000` e visita `http://localhost:8000/`. Per modalità offline non servono pacchetti. `npm test` esegue i test del motore missioni.

## Prodotto attuale

- Homepage pubblica: presenta missioni, prove e crew e contiene un modulo beta Android/iPhone. Il modulo resta disattivato finché privacy e configurazione non sono completate.
- App nativa Expo per iOS e Android in `mobile/`, con schede Missioni, Crew, Album e Profilo, tema chiaro/scuro/di sistema e schermata iniziale SideQuest.
- Missioni giornaliere e meme, filtri, quest personalizzate e QR per luoghi aderenti.
- Per completare una missione si scatta una foto o si registra un video fino a 15 secondi. La prova condivisa con una crew può essere approvata dai membri; solo dopo l’approvazione vengono assegnati crediti.
- Account con link monouso email. Google OAuth e gli altri provider restano nascosti finché non vengono configurate credenziali reali del provider in Supabase.
- Saldo server-side: una missione ufficiale vale 10 crediti una sola volta per account. Le missioni create dagli utenti e gli account anonimi non generano crediti.
- Negozio iniziale: tre stili grafici acquistabili con crediti per le card condivisibili. I crediti non sono denaro e non sono convertibili in premi.
- Completamenti ufficiali, saldo e acquisti associati all’account e conservati su Supabase. Album privato locale e missioni personalizzate restano sul dispositivo.
- Stanze private con invito; le prove vengono condivise solo all’interno della crew scelta.
- Un singolo spazio pubblicitario chiaramente etichettato; per impostazione predefinita è spento e non è vicino ai controlli delle missioni.

## Collegare account e stanze

1. Crea un progetto Supabase sul piano gratuito. In **Project Settings → API** prendi Project URL e chiave pubblica `anon`/publishable e inseriscili in `config.js`. Non usare mai `service_role` nel frontend.
2. Nel Supabase **SQL Editor** esegui `supabase-schema.sql`, poi tutte le migrazioni in `supabase-migrations` in ordine di nome. Per aggiornare il progetto esistente esegui solo le migrazioni che non hai già applicato; la nuova `20261007_zz_ugc_safety.sql` va dopo `20261007_social_quests.sql` e `20261007_z_security_hardening.sql`. Le procedure e le policy verificano utente, appartenenza alle crew e contenuti sul server.
3. In **Authentication → URL Configuration**, imposta Site URL a `https://sidequest-apr.pages.dev` e aggiungi la stessa origine tra i redirect consentiti.
4. Il provider Email è abilitato per impostazione predefinita e il login usa link monouso. Per i test iniziali usa un indirizzo ammesso dal servizio email predefinito di Supabase; prima di aprire le registrazioni al pubblico configura SMTP. Il dominio definitivo serve per autenticare il mittente e allineare i record DNS, non per continuare a sviluppare o provare il sito.
5. Google OAuth richiede un client ID e un secret reali in Supabase e nella console Google. Fino ad allora `oauthProviders` resta vuoto e il pulsante Google non viene mostrato. Non abilitare accessi anonimi: profili, crediti e stanze richiedono un account permanente.
6. Pubblica il commit su GitHub: Cloudflare Pages ricostruisce il sito. Crediti e acquisti richiedono rete; la parte locale continua a funzionare senza Supabase.

Gli OAuth provider aggiuntivi richiedono un’app e credenziali proprie nel provider, poi l’attivazione in Supabase e in `oauthProviders`. Il pulsante non inventa né contiene chiavi segrete.

## Annunci e ricavi

Durante la beta la priorità è verificare che le persone provino le missioni, invitino una crew e tornino nell’app. La homepage non mostra annunci: con poco traffico renderebbero poco e distrarrebbero dalla presentazione del prodotto. Qualunque futura monetizzazione verrà valutata dopo la beta, senza scambi visite, clic propri o inviti a cliccare.

AdSense è predisposto ma disattivato in `config.js`: il publisher ID, il meta tag di verifica e `ads.txt` non attivano gli annunci da soli. Etsy e SideQuest sono siti distinti; l’eventuale approvazione Etsy non si estende a SideQuest. Puoi già aggiungere `https://sidequest-apr.pages.dev` in **AdSense → Siti**, verificare il sito e chiedere la revisione; `pages.dev` è un sottodominio Cloudflare ammesso dalla regola Google per piattaforme presenti nella Public Suffix List. La revisione può richiedere giorni o, in alcuni casi, 2–4 settimane. Quando il dominio personalizzato è attivo, aggiungilo a sua volta se AdSense lo richiede.

1. aggiungi ora `https://sidequest-apr.pages.dev` in **AdSense → Siti** e verifica la proprietà usando il meta tag già pubblicato o `ads.txt`;
2. chiedi la revisione di SideQuest. Se Google la approva, crea un’unità display e inserisci il suo slot in `ads.slots.quests`;
3. quando il dominio personalizzato è attivo, aggiungilo ad AdSense e segui l’eventuale verifica/revisione richiesta anche per quello;
4. verifica la CMP/messaggio europeo di consenso per SideQuest e le impostazioni per annunci rivolti a un pubblico che include minorenni; poi imposta `ads.enabled` su `true` e pubblica. Finché manca un requisito, il loader resta spento.

Il file `ads.txt` contiene l’identificativo publisher fornito e autorizza il venditore; non approva SideQuest né mostra annunci. Google esamina separatamente i nuovi siti prima che possano mostrare inserzioni. Per il pubblico 15–25, Google applica protezioni per adolescenti agli account che identifica come minori di 18 anni, inclusi annunci non personalizzati e restrizioni su categorie sensibili; non raccogliere la data di nascita solo per gli annunci. La CMP certificata richiesta da Google per annunci personalizzati in SEE/Regno Unito/Svizzera va impostata anche per SideQuest. Manteniamo un solo spazio visibile e chiaramente etichettato, lontano dai controlli: niente pop-under o posizionamenti progettati per ottenere clic accidentali. Per usare video rewarded come nelle app native serve una vera app e il formato/SDK ammesso dalla rete.

Per rimuovere ogni annuncio basta spegnere `ads.enabled`; per cancellare del tutto l’integrazione si eliminano lo spazio `#quest-ad-wrap`, il relativo loader e la riga AdSense da `ads.txt`.

## Spese e limiti

Il codice non richiede una spesa fissa per funzionare. Cloudflare Pages e Supabase hanno piani gratuiti con quote e condizioni proprie: controlla i dashboard e gli avvisi del provider; non abilitare componenti a pagamento. Account, annunci, email OAuth e CMP dipendono comunque dai rispettivi account gestore. Le chiavi pubbliche Supabase sono visibili nel sito e protette da RLS; non committare credenziali private.

## Privacy, sicurezza e manutenzione

La privacy è una bozza e contiene campi titolare/contatto da completare prima di raccogliere dati reali. Lo schema limita i messaggi in lunghezza e frequenza, usa RLS, blocca link e memorizza i premi una volta sola. Dall’account si possono cancellare identità, crediti, acquisti e stanze create dall’utente. Crew e prove richiedono accettazione esplicita delle regole; l’app include segnalazione e blocco. Prima del lancio verifica informativa, retention, contatti, procedura di moderazione e regole applicabili all’età del pubblico.

Le missioni base e i premi corrispondenti sono definiti rispettivamente in `core.js` e `supabase-schema.sql`: se modifichi le missioni, aggiorna anche la allowlist SQL. Per distribuire gli aggiornamenti PWA incrementa il nome cache in `sw.js`.

## Beta privata Android e lista iPhone

Il form in homepage non registra richieste finché `config.js` ha `beta.enabled: false`. L’invio usa la Pages Function `functions/api/beta-signup.js`, valida il token Turnstile sul server e scrive solo nella tabella privata `sq_beta_signups`. Non mette il service-role key nel browser. La lista non verifica la proprietà dell’indirizzo email; l’accesso al canale si controlla manualmente associando email e username Telegram. Non viene spedita un’email dalla lista d’attesa. L’SMTP Supabase serve invece per i link di accesso dell’app.

Prima di aprire la raccolta:

1. Completa `privacy.html`: nome/indirizzo del titolare, contatto, basi giuridiche, tempi di conservazione definitivi, fascia d’età e modalità per esercitare i diritti. Il testo è ancora una bozza.
2. In Supabase SQL Editor esegui `20261007_zzz_beta_waitlist.sql` una sola volta. Poi verifica che `anon` e `authenticated` non abbiano accesso alla tabella; le richieste vengono inserite solo dalla funzione server.
3. Crea un widget Turnstile legato all’hostname pubblico e copia la site key in `config.js` sotto `beta.turnstileSiteKey`. In Cloudflare Pages aggiungi come variabili/secrets `TURNSTILE_SECRET_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` e `BETA_SIGNUPS_ENABLED=false`. Il service-role key va salvato solo come secret server-side.
4. Crea il canale Telegram privato e un link di invito con richiesta di ingresso attiva. Imposta `beta.telegramInviteUrl` in `config.js`; approva manualmente solo username presenti nella lista e stato `approved`.
5. Pubblica tramite l’integrazione Git di Pages o Wrangler: le Pages Functions non vengono incluse in un semplice caricamento statico diretto. Verifica l’endpoint e la tabella prima di impostare `BETA_SIGNUPS_ENABLED=true` e `beta.enabled=true`.

La prima beta è riservata ai maggiorenni (18+), confermato sia nel modulo sia dalla funzione server. Le richieste iPhone servono solo a misurare l’interesse: TestFlight non è configurato. Proteggi l’accesso alla tabella in Supabase e definisci una procedura per rimuovere richieste non più necessarie.

## Acquisizione utenti senza spam

## Email di accesso e APK beta

L’app usa link monouso Supabase (`signInWithOtp`). Per inviarli a beta tester esterni serve un provider SMTP personalizzato: il mittente SMTP predefinito Supabase è limitato agli indirizzi autorizzati del team e a un volume molto basso. Dopo che il dominio SideQuest è attivo, configura un provider SMTP, verifica il dominio mittente con i record DNS richiesti (SPF/DKIM, e DMARC consigliato), quindi inserisci host, porta, username e password in **Supabase → Authentication → SMTP Settings**. Lascia disattivata la conferma automatica email; prova un link con il tuo indirizzo e controlla che il redirect apra l’app. Non committare credenziali SMTP. La lista beta non invia inviti: li gestisci tu a mano.

In `mobile/eas.json` il profilo `preview` è predisposto per un APK installabile, mentre `production` produce un AAB destinato allo store. EAS non carica `.env.local`: nell’ambiente **preview** del progetto Expo vanno create `EXPO_PUBLIC_SUPABASE_URL` e `EXPO_PUBLIC_SUPABASE_ANON_KEY` con i valori già usati dall’app. Per inizializzare il progetto EAS serve un account Expo e un login interattivo; dalla cartella `mobile`, esegui `npx eas-cli@latest build:configure -p android` se EAS richiede la configurazione, poi `npx eas-cli@latest build --platform android --profile preview`. Al primo avvio EAS può chiedere di collegare il progetto e creare/gestire la chiave di firma Android. Al termine scarica l’APK dal link fornito da Expo e installalo sul telefono per la prova. Non condividere pubblicamente il link APK: usalo solo per i tester che hai approvato. Non copiare mai `.env.local` nei messaggi o nel repository.

## Acquisizione utenti senza spam

Inizia con il carosello statico e le storie a sondaggio preparati in `marketing/primo-carosello-pronto.md` e `marketing/calendario-lancio-14-giorni.md`: non serve pubblicare video ogni giorno o automatizzare le interazioni. Condividi una missione reale, invita la crew tramite link e rispondi manualmente ai commenti. Misura visite e missioni avviate prima di investire tempo in video o strumenti aggiuntivi.
