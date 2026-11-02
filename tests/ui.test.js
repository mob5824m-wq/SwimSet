/*
 * Browser-level smoke test.
 * Loads index.html in jsdom, boots the real app module and exercises the main
 * flows: builder edits, saving, library, templates, poolside runner, print.
 *
 * Requires the dev dependency: npm install
 */
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

let JSDOM;
try {
  ({ JSDOM } = await import('jsdom'));
} catch {
  JSDOM = null;
}

test('UI smoke test', { skip: JSDOM ? false : 'jsdom not installed — run npm install' }, async (t) => {
  const html = await readFile(new URL('../index.html', import.meta.url), 'utf8');
  const dom = new JSDOM(html, {
    url: 'http://localhost/',
    pretendToBeVisual: true,
  });
  const { window } = dom;

  window.scrollTo = () => {};
  window.print = () => {};
  window.matchMedia = (query) => ({
    matches: false,
    media: query,
    addEventListener() {},
    removeEventListener() {},
    addListener() {},
    removeListener() {},
  });
  window.HTMLElement.prototype.scrollIntoView = function scrollIntoView() {};
  globalThis.requestAnimationFrame = (cb) => window.setTimeout(() => cb(Date.now()), 0);
  globalThis.cancelAnimationFrame = (id) => window.clearTimeout(id);

  const globals = {
    window,
    document: window.document,
    location: window.location,
    navigator: window.navigator,
    HTMLElement: window.HTMLElement,
    localStorage: window.localStorage,
    HashChangeEvent: window.HashChangeEvent,
    Event: window.Event,
  };
  for (const [key, value] of Object.entries(globals)) {
    Object.defineProperty(globalThis, key, { value, configurable: true, writable: true });
  }

  const errors = [];
  window.addEventListener('error', (event) => errors.push(event.error || event.message));

  await import('../js/app.js');

  const $ = (sel) => window.document.querySelector(sel);
  const $$ = (sel) => [...window.document.querySelectorAll(sel)];

  const click = (sel) => {
    const el = typeof sel === 'string' ? $(sel) : sel;
    assert.ok(el, `element ${sel} should exist`);
    el.click();
    return el;
  };
  const type = (el, value, eventName = 'input') => {
    el.value = String(value);
    el.dispatchEvent(new window.Event(eventName, { bubbles: true }));
  };
  const flush = () => new Promise((resolve) => setTimeout(resolve, 20));

  await t.test('renders the starter practice', () => {
    assert.equal($$('.view').length, 4);
    assert.equal(window.document.querySelector('#view-builder').hidden, false);
    assert.equal($$('.set-card').length, 3);
    assert.equal($('[data-out="distance"]').textContent.trim(), '1,200');
    assert.equal($('[data-out="setcount"]').textContent.trim(), '3');
    assert.match($('[data-out="foot-summary"]').textContent, /3 sets/);
  });

  await t.test('adds, edits and recalculates sets', async () => {
    click('[data-action="add-set"]');
    await flush();
    assert.equal($$('.set-card').length, 4);

    const reps = $('.set-card [data-field="reps"]');
    type(reps, 10);
    assert.equal($('[data-out="distance"]').textContent.trim(), '2,200');
    assert.match($('[data-out="foot-summary"]').textContent, /2,200/);

    // Switch the newly added set to a custom send-off (manual interval).
    const lastCard = () => $$('.set-card').at(-1);
    const manualSelect = lastCard().querySelector('[data-field="intervalMode"]');
    assert.ok(manualSelect, 'open details are shown for new sets');
    manualSelect.value = 'manual';
    manualSelect.dispatchEvent(new window.Event('change', { bubbles: true }));
    const sendoffInput = lastCard().querySelector('[data-field="interval"]');
    assert.ok(sendoffInput, 'manual interval input appears');
    type(sendoffInput, '1:45');
    const issues = window.document.querySelector('#issue-list').textContent;
    assert.ok(issues.length > 0);
  });

  await t.test('saves to the library', async () => {
    click('[data-action="save-practice"]');
    const raw = window.localStorage.getItem('swimset.v1.practices');
    assert.ok(raw, 'practice is persisted');
    const saved = JSON.parse(raw);
    assert.equal(saved.length, 1);
    assert.equal(saved[0].sets.length, 4);
    assert.equal($('[data-role="save-state"]').textContent, 'Saved to library');
  });

  await t.test('library lists the saved practice and supports search', async () => {
    window.location.hash = '#/library';
    window.dispatchEvent(new window.HashChangeEvent('hashchange'));
    assert.equal($('#view-library').hidden, false);
    assert.equal($$('.practice-card').length, 1);
    assert.match($('.practice-card h2').textContent, /First practice/);

    const search = $('#library-search');
    type(search, 'zzzz');
    assert.equal($$('.practice-card').length, 0);
    search.value = '';
    type($('#library-search'), '');
  });

  await t.test('templates modal opens and inserts sets', async () => {
    window.location.hash = '#/builder';
    window.dispatchEvent(new window.HashChangeEvent('hashchange'));
    click('.add-row [data-action="open-templates"]');
    const cards = $$('.template-card');
    assert.ok(cards.length >= 6);
    const before = $$('.set-card').length;
    const addButton = $('[data-action="insert-template"]');
    addButton.click();
    await flush();
    assert.ok($$('.set-card').length > before, 'template sets were appended');
    assert.equal($('.modal-panel'), null, 'modal closed');
  });

  await t.test('poolside runner starts, ticks and pauses', async () => {
    click('[data-action="start-run"]');
    window.dispatchEvent(new window.HashChangeEvent('hashchange'));
    assert.ok($('.run-stage'), 'run stage rendered');
    assert.ok($$('#run-list li').length > 0);

    // Re-query after each click: a pending hashchange re-renders the runner.
    const playButton = () => $('[data-action="play-pause"]');
    playButton().click();
    await flush();
    assert.match(playButton().innerHTML, /Pause/);
    assert.match($('[data-run="remaining"]').textContent, /^\d*:\d{2}$/);
    playButton().click();
    await flush();
    assert.match(playButton().innerHTML, /Start/);

    const next = $('[data-action="run-next"]');
    const stepBefore = $('[data-run="step-number"]').textContent;
    next.click();
    assert.notEqual($('[data-run="step-number"]').textContent, stepBefore);
  });

  await t.test('print sheet and theme toggle work', async () => {
    click('[data-action="print-practice"]');
    await flush();
    const sheet = $('#print-root .sheet');
    assert.ok(sheet, 'print sheet is generated');
    assert.match(sheet.textContent, /First practice/);
    assert.ok(sheet.querySelectorAll('.sheet-table tbody tr').length > 0);

    click('[data-action="toggle-theme"]');
    assert.equal(window.document.documentElement.dataset.theme, 'dark');
    click('[data-action="toggle-theme"]');
    assert.equal(window.document.documentElement.dataset.theme, 'light');
  });

  await t.test('no uncaught errors', () => {
    assert.deepEqual(errors, []);
  });

  dom.window.close();
});
