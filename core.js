export const QUESTS = [
  {id:'faccia-casuale',emoji:'🫠',tag:'OSSERVAZIONE',title:'Questa cosa ti somiglia',prompt:'Trova un oggetto o una macchia che assomiglia a qualcuno della crew. Fagli un ritratto.',duration:'5 min',vibe:'ovunque',difficulty:'facile'},
  {id:'recensione-panchina',emoji:'🪑',tag:'CINEMA',title:'La panchina a 5 stelle',prompt:'Siediti sulla panchina più vicina e fai una recensione come se fosse un hotel di lusso.',duration:'5 min',vibe:'fuori casa',difficulty:'facile'},
  {id:'merenda-segreta',emoji:'🥨',tag:'SPEDIZIONE',title:'Merenda misteriosa',prompt:'Scegli una merenda con la confezione più strana. La crew assegna il nome da chef stellato.',duration:'10 min',vibe:'con amici',difficulty:'facile'},
  {id:'outfit-colore',emoji:'🟣',tag:'MODA?',title:'Un solo colore',prompt:'Componi un outfit usando un colore scelto dagli altri. Anche gli oggetti intorno contano.',duration:'10 min',vibe:'a casa',difficulty:'facile'},
  {id:'copertina-album',emoji:'🎧',tag:'ART DIRECTION',title:'Copertina di un album mai uscito',prompt:'Fate una foto di gruppo che potrebbe essere la copertina del disco della vostra band immaginaria.',duration:'15 min',vibe:'con amici',difficulty:'medio'},
  {id:'cartello-passivo',emoji:'🪧',tag:'RADAR',title:'Il cartello passivo-aggressivo',prompt:'Trova un cartello con un’energia inspiegabilmente personale. Fotografalo: cosa sta cercando di dirti?',duration:'10 min',vibe:'fuori casa',difficulty:'medio'},
  {id:'doppiaggio',emoji:'🎬',tag:'DOPPIAGGIO',title:'Dagli una voce',prompt:'Fai un video di 5 secondi doppiando un oggetto con il dramma di una serie TV.',duration:'5 min',vibe:'a casa',difficulty:'facile'},
  {id:'menu-immaginario',emoji:'🍝',tag:'CUCINA',title:'Il piatto che non esiste',prompt:'Inventate il piatto più assurdo del menu. Impiattatelo con quello che avete e dategli un prezzo.',duration:'15 min',vibe:'con amici',difficulty:'medio'},
  {id:'monumento-mini',emoji:'🗿',tag:'SCULTURA',title:'Monumento a una cosa inutile',prompt:'Dedica un piccolo monumento a qualcosa che usi ogni giorno e dai un discorso di inaugurazione.',duration:'10 min',vibe:'a casa',difficulty:'facile'},
  {id:'oggetto-lore',emoji:'🧴',tag:'LORE',title:'La vita segreta di questo oggetto',prompt:'Scegli un oggetto vicino a te e racconta in una foto la sua vita segreta quando non lo guardi.',duration:'5 min',vibe:'a casa',difficulty:'facile'},
  {id:'complimento-specifico',emoji:'💌',tag:'SIDEQUEST BUONA',title:'Un complimento molto preciso',prompt:'Fai un complimento ultra-specifico a qualcuno della crew. Niente “sei simpatico”: più preciso.',duration:'5 min',vibe:'con amici',difficulty:'facile'},
  {id:'saluto-insegna',emoji:'👋',tag:'CACCIA AL TESORO',title:'L’insegna che ti saluta',prompt:'Trova un’insegna, un graffito o un riflesso che oggi sembra proprio mandarti un saluto.',duration:'10 min',vibe:'fuori casa',difficulty:'medio'}
];
const durations = ['5 min','10 min','15 min','20 min'];
const vibes = ['ovunque','con amici','fuori casa','a casa'];

export function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
}

export function filterQuests(quests, filter='all') {
  return quests.filter(q => filter === 'all' || q.vibe === filter || q.duration === filter);
}

export function normalizeSponsoredMissions(source) {
  if (!Array.isArray(source)) return [];
  return source.filter(q => q && typeof q.id==='string' && typeof q.title==='string' && q.title.trim() && q.title.length<=55 &&
    typeof q.prompt==='string' && q.prompt.trim() && q.prompt.length<=180 && typeof q.sponsorName==='string' && q.sponsorName.trim() &&
    durations.includes(q.duration) && vibes.includes(q.vibe)).slice(0,8).flatMap(q => {
      let url='';
      try { const parsed=new URL(q.url); if(parsed.protocol==='https:') url=parsed.href; } catch {}
      return [{id:'sponsor-'+q.id.slice(0,60),emoji:typeof q.emoji==='string'&&[...q.emoji].length<=4?q.emoji:'✳',
        tag:'SPONSORIZZATA',title:q.title,prompt:q.prompt,duration:q.duration,vibe:q.vibe,difficulty:'missione speciale',
        sponsorName:q.sponsorName.slice(0,50),disclosure:typeof q.disclosure==='string'&&q.disclosure.trim()?q.disclosure.slice(0,120):'Contenuto sponsorizzato',url,
        cta:typeof q.cta==='string'&&q.cta.trim()?q.cta.slice(0,36):'Scopri la missione'}];
    });
}

export function encodeQuest(quest) {
  const bytes = new TextEncoder().encode(JSON.stringify(quest));
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
}

export function decodeQuest(value) {
  try {
    if (typeof value !== 'string' || value.length > 2048 || !/^[A-Za-z0-9_-]+$/.test(value)) return null;
    const base = value.replace(/-/g,'+').replace(/_/g,'/').padEnd(Math.ceil(value.length/4)*4,'=');
    const bytes = Uint8Array.from(atob(base), char => char.charCodeAt(0));
    const q = JSON.parse(new TextDecoder().decode(bytes));
    if (typeof q.title !== 'string' || !q.title.trim() || q.title.length > 55 || typeof q.prompt !== 'string' || !q.prompt.trim() || q.prompt.length > 180) return null;
    if (!durations.includes(q.duration) || !vibes.includes(q.vibe)) return null;
    const emoji = typeof q.emoji === 'string' && [...q.emoji].length <= 4 && /^[\p{Emoji}\p{Emoji_Component}\s]+$/u.test(q.emoji) ? q.emoji : '✳';
    return {id:`shared-${String(q.id||'quest').slice(0,64)}`,emoji,tag:'INVITO',title:q.title,prompt:q.prompt,duration:q.duration,vibe:q.vibe,difficulty:'facile'};
  } catch { return null; }
}

export function normalizeState(raw) {
  try {
    const state = typeof raw === 'string' ? JSON.parse(raw || '{}') : raw || {};
    const custom = Array.isArray(state.custom) ? state.custom.filter(q => q && typeof q.title === 'string' && q.title.trim() && q.title.length <= 55 && typeof q.prompt === 'string' && q.prompt.trim() && q.prompt.length <= 180 && durations.includes(q.duration) && vibes.includes(q.vibe)).slice(0,40).map((q,i) => ({id:`custom-${String(q.id||i).slice(0,64)}`,emoji:typeof q.emoji==='string'&&[...q.emoji].length<=4?q.emoji:'✳',tag:'INVENTATA DA TE',title:q.title,prompt:q.prompt,duration:q.duration,vibe:q.vibe,difficulty:'facile'})) : [];
    const memories = Array.isArray(state.memories) ? state.memories.filter(m => m && typeof m.title==='string' && m.title.length<=55 && typeof m.completedAt==='string' && (!m.photo || (typeof m.photo==='string' && m.photo.startsWith('data:image/jpeg;base64,') && m.photo.length<250000))).slice(0,18) : [];
    const completed = Array.isArray(state.completed) ? state.completed.filter(id => typeof id==='string' && id.length<=80).slice(-100) : [];
    return {custom,memories,completed};
  } catch { return {custom:[],memories:[],completed:[]}; }
}
