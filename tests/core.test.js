import test from 'node:test';
import assert from 'node:assert/strict';
import {QUESTS, decodeQuest, encodeQuest, escapeHtml, filterQuests, normalizeState, normalizeSponsoredMissions} from '../core.js';

test('ships a useful set of missions with valid shareable fields', () => {
  assert.ok(QUESTS.length >= 10);
  for (const q of QUESTS) {
    assert.ok(q.title.length > 0 && q.title.length <= 55);
    assert.ok(q.prompt.length > 0 && q.prompt.length <= 180);
    assert.match(q.duration, /^\d+ min$/);
  }
});

test('filters by time or crew context', () => {
  assert.ok(filterQuests(QUESTS,'5 min').length > 0);
  assert.ok(filterQuests(QUESTS,'con amici').every(q=>q.vibe==='con amici'));
  assert.equal(filterQuests(QUESTS,'all').length,QUESTS.length);
});

test('sponsored missions require a clear sponsor label and accept HTTPS links only', () => {
  const [mission]=normalizeSponsoredMissions([{
    id:'real-partner-slot',title:'Crea con noi',prompt:'Prova una piccola missione creativa.',duration:'10 min',
    vibe:'con amici',sponsorName:'Brand vero',url:'http://example.com',cta:'Scopri'
  }]);
  assert.equal(mission.tag,'SPONSORIZZATA');
  assert.equal(mission.sponsorName,'Brand vero');
  assert.equal(mission.url,'');
  assert.equal(normalizeSponsoredMissions([{id:'fake',title:'Niente disclosure',prompt:'test',duration:'5 min',vibe:'ovunque'}]).length,0);
  assert.equal(normalizeSponsoredMissions([{id:'ok',title:'Valida',prompt:'Missione',duration:'5 min',vibe:'ovunque',sponsorName:'Partner',url:'https://example.com'}])[0].url,'https://example.com/');
});

test('mission links round-trip Italian text, emoji and allowed metadata', () => {
  const mission={id:'custom-42',title:'La cosa più scema 🍉',prompt:'Fai una foto e racconta cos’è successo.',duration:'10 min',vibe:'con amici',emoji:'🪩'};
  assert.deepEqual(decodeQuest(encodeQuest(mission)),{id:'shared-custom-42',emoji:'🪩',tag:'INVITO',title:mission.title,prompt:mission.prompt,duration:mission.duration,vibe:mission.vibe,difficulty:'facile'});
});

test('rejects corrupt, oversized and unsafe mission links', () => {
  assert.equal(decodeQuest('%%%'),null);
  assert.equal(decodeQuest('a'.repeat(2049)),null);
  assert.equal(decodeQuest(encodeQuest({title:'Oops',prompt:'Text',duration:'forever',vibe:'public'})),null);
});

test('escapes user-provided strings before inserting them into markup', () => {
  assert.equal(escapeHtml("<script a=\"x\">&'"),
    '&lt;script a=&quot;x&quot;&gt;&amp;&#39;');
});

test('recovers corrupted local state and rejects unsafe persisted content', () => {
  assert.deepEqual(normalizeState('{oops'),{custom:[],memories:[],completed:[]});
  const result=normalizeState({
    custom:[
      {id:'a',title:'Quest ok',prompt:'Fai una foto',duration:'5 min',vibe:'a casa',emoji:'🍋'},
      {id:'b',title:'<script>',prompt:'Fuori durata',duration:'domani',vibe:'ovunque'}
    ],
    memories:[{title:'Troppo grande',completedAt:'oggi',photo:'data:image/jpeg;base64,'+'A'.repeat(250001)}],
    completed:['faccia-casuale',42]
  });
  assert.equal(result.custom.length,1);
  assert.equal(result.custom[0].tag,'INVENTATA DA TE');
  assert.equal(result.memories.length,0);
  assert.deepEqual(result.completed,['faccia-casuale']);
});
