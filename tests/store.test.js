import test from 'node:test';
import assert from 'node:assert/strict';

/* Minimal localStorage stub so store.js can run outside the browser. */
class MemoryStorage {
  constructor() {
    this.map = new Map();
  }
  getItem(key) {
    return this.map.has(key) ? this.map.get(key) : null;
  }
  setItem(key, value) {
    this.map.set(key, String(value));
  }
  removeItem(key) {
    this.map.delete(key);
  }
  clear() {
    this.map.clear();
  }
}

globalThis.window = { localStorage: new MemoryStorage() };

const core = await import('../js/core.js');
const store = await import('../js/store.js');

test.beforeEach(() => {
  window.localStorage.clear();
});

test('storage availability and empty library', () => {
  assert.equal(store.storageAvailable(), true);
  assert.deepEqual(store.loadPractices(), []);
  assert.equal(store.getPractice('missing'), null);
});

test('save, update, reload and delete a practice', () => {
  const p = core.createPractice({ title: '  Threshold  ' });
  p.sets = [core.createSet({ reps: 5, distance: 200 })];
  const saved = store.savePractice(p);
  assert.equal(saved.title, 'Threshold');
  assert.equal(store.loadPractices().length, 1);

  saved.title = 'Threshold v2';
  store.savePractice(saved);
  const list = store.loadPractices();
  assert.equal(list.length, 1);
  assert.equal(list[0].title, 'Threshold v2');

  store.deletePractice(saved.id);
  assert.equal(store.loadPractices().length, 0);
});

test('duplicate practice gets a new id', () => {
  const saved = store.savePractice(core.createPractice({ title: 'Base' }));
  const copy = store.duplicatePractice(saved.id);
  assert.notEqual(copy.id, saved.id);
  assert.match(copy.title, /\(copy\)/);
  assert.equal(store.loadPractices().length, 2);
});

test('draft round-trips and respects normalisation', () => {
  const p = core.createPractice({ title: 'Draft work', basePace: 95 });
  p.sets = [core.createSet({ reps: 3, distance: 100 })];
  store.saveDraft(p);
  const draft = store.loadDraft();
  assert.equal(draft.practice.title, 'Draft work');
  assert.equal(draft.practice.sets[0].reps, 3);
  store.clearDraft();
  assert.equal(store.loadDraft(), null);
});

test('preferences merge with defaults', () => {
  const prefs = store.loadPrefs();
  assert.equal(prefs.autoAdvance, true);
  store.savePrefs({ theme: 'dark' });
  const saved = store.loadPrefs();
  assert.equal(saved.theme, 'dark');
  assert.equal(saved.autoAdvance, true);
});

test('export/import bundle round-trips with collision handling', () => {
  const one = store.savePractice(core.createPractice({ title: 'One' }));
  const bundle = store.buildExportBundle([one]);
  const parsed = JSON.parse(bundle);
  assert.equal(parsed.app, 'SwimSet');
  assert.equal(parsed.practices.length, 1);

  const imported = store.importBundle(bundle);
  assert.equal(imported.length, 1);
  assert.notEqual(imported[0].id, one.id, 'colliding id is replaced');
  assert.equal(store.loadPractices().length, 2);
});

test('import accepts a bare array and a single practice object', () => {
  const single = core.createPractice({ title: 'Solo' });
  store.importBundle(JSON.stringify(single));
  assert.equal(store.loadPractices().length, 1);

  const two = [core.createPractice({ title: 'A' }), core.createPractice({ title: 'B' })];
  store.importBundle(JSON.stringify(two));
  assert.equal(store.loadPractices().length, 3);
});

test('import rejects invalid input', () => {
  assert.throws(() => store.importBundle('not json'), /valid JSON/);
  assert.throws(() => store.importBundle('{"hello":true}'), /No SwimSet practices/);
});
