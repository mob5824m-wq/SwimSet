/*
 * SwimSet — application shell.
 * Vanilla ES modules, no build step, no dependencies. Works offline.
 */
import * as core from './core.js';
import { TEMPLATES, templateToPractice, instantiateTemplateSets } from './templates.js';
import * as store from './store.js';

/* ------------------------------------------------------------------ */
/* Icons                                                               */
/* ------------------------------------------------------------------ */

const ICONS = {
  plus: '<path d="M12 5v14M5 12h14"/>',
  trash: '<path d="M4 7h16M9 7V5h6v2M6 7l1 13h10l1-13"/>',
  copy: '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h6"/>',
  up: '<path d="M12 19V5M6 11l6-6 6 6"/>',
  down: '<path d="M12 5v14M6 13l6 6 6-6"/>',
  print: '<path d="M7 8V4h10v4M7 17H5a2 2 0 0 1-2-2v-4a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2h-2"/><rect x="7" y="14" width="10" height="6" rx="1"/>',
  download: '<path d="M12 4v11M7 10l5 5 5-5M5 20h14"/>',
  upload: '<path d="M12 20V9M7 14l5-5 5 5M5 4h14"/>',
  save: '<path d="M5 3h11l3 3v15H5z"/><path d="M8 3v6h8V3M8 21v-7h8v7"/>',
  play: '<path d="M7 4l14 8-14 8z"/>',
  pause: '<path d="M8 4v16M16 4v16"/>',
  next: '<path d="M6 5l10 7-10 7zM19 5v14"/>',
  prev: '<path d="M18 5L8 12l10 7zM5 5v14"/>',
  reset: '<path d="M4 4v6h6M4.5 15a8 8 0 1 0 .8-7.5L4 10"/>',
  mute: '<path d="M11 5L6 9H3v6h3l5 4z"/><path d="M16 9l5 6M21 9l-5 6"/>',
  sound: '<path d="M11 5L6 9H3v6h3l5 4z"/><path d="M16 8a5 5 0 0 1 0 8M19 5a9 9 0 0 1 0 14"/>',
  expand: '<path d="M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5"/>',
  close: '<path d="M6 6l12 12M18 6L6 18"/>',
  check: '<path d="M20 6L9 17l-5-5"/>',
  warning: '<path d="M12 3l10 18H2z"/><path d="M12 9v5M12 17.5v.5"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8v.5"/>',
  more: '<circle cx="5" cy="12" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="19" cy="12" r="1.4"/>',
  sliders: '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h10M18 18h2"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="16" cy="18" r="2"/>',
  template: '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
  book: '<path d="M4 5a2 2 0 0 1 2-2h14v18H6a2 2 0 0 0-2 2z"/><path d="M4 19a2 2 0 0 1 2-2h14"/>',
  share: '<circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="6" r="2.5"/><circle cx="18" cy="18" r="2.5"/><path d="M8.2 10.8l7.6-3.6M8.2 13.2l7.6 3.6"/>',
  sun: '<circle cx="12" cy="12" r="4.2"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4"/>',
  moon: '<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z"/>',
  timer: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4M9 2h6"/>',
  waves: '<path d="M2 12c3-4 6-4 9 0s6 4 9 0M2 18c3-4 6-4 9 0s6 4 9 0M2 6c3-4 6-4 9 0s6 4 9 0"/>',
  arrowLeft: '<path d="M19 12H5M11 18l-6-6 6-6"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="M16.5 16.5L21 21"/>',
  install: '<path d="M12 3v10M8 9l4 4 4-4M4 17v3h16v-3"/>',
  spark: '<path d="M12 3l2.2 5.8L20 11l-5.8 2.2L12 19l-2.2-5.8L4 11l5.8-2.2z"/>',
};

function icon(name, cls = '') {
  return `<svg class="icon ${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">${ICONS[name] || ''}</svg>`;
}

/* ------------------------------------------------------------------ */
/* Helpers                                                             */
/* ------------------------------------------------------------------ */

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

const ESCAPES = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, (ch) => ESCAPES[ch]);
}

function parseIntOrNull(value) {
  const n = Number.parseInt(String(value).replace(/[^\d-]/g, ''), 10);
  return Number.isFinite(n) ? n : null;
}

function courseOptions(selected) {
  return core.COURSE_IDS.map(
    (id) => `<option value="${id}" ${id === selected ? 'selected' : ''}>${core.COURSES[id].label} — ${core.COURSES[id].length} ${core.COURSES[id].unit}</option>`
  ).join('');
}

function typeOf(id) {
  return core.SET_TYPES.find((t) => t.id === id) || core.SET_TYPES[core.SET_TYPES.length - 1];
}

function setUnit(practice = state.practice) {
  return core.unitFor(practice);
}

/* ------------------------------------------------------------------ */
/* State                                                               */
/* ------------------------------------------------------------------ */

const prefs = store.loadPrefs();

const state = {
  practice: null,
  view: 'builder',
  dirty: false,
  savedEver: false,
  storageOk: store.storageAvailable(),
  openDetails: new Set(),
  installPrompt: null,
  prefs,
  library: { query: '', sort: 'updated' },
  paceTool: {
    base: 100,
    rest: 0,
    round: 5,
    time: 112.5,
    from: 'SCM',
    to: 'SCY',
    knownTime: 300,
    knownDistance: 400,
  },
  run: {
    steps: [],
    index: 0,
    running: false,
    remainingMs: null,
    elapsedMs: 0,
    muted: Boolean(prefs.runMuted),
    autoAdvance: prefs.autoAdvance !== false,
    beeped3: false,
    finished: false,
    timerId: null,
    wakeLock: null,
    lastTick: 0,
    fingerprint: '',
  },
};

let audioCtx = null;
let draftTimer = null;
let pendingConfirm = null;
let lastFocused = null;

/* ------------------------------------------------------------------ */
/* Toasts, modals, dialogs                                             */
/* ------------------------------------------------------------------ */

function toast(message, { tone = 'info', actionLabel = '', onAction = null, timeout = 3600 } = {}) {
  const stack = $('#toast-stack');
  if (!stack) return;
  const el = document.createElement('div');
  el.className = `toast toast-${tone}`;
  el.innerHTML = `<span class="toast-text">${esc(message)}</span>`;
  if (actionLabel) {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'toast-action';
    btn.textContent = actionLabel;
    btn.addEventListener('click', () => {
      onAction?.();
      remove();
    });
    el.append(btn);
  }
  function remove() {
    el.classList.add('toast-out');
    setTimeout(() => el.remove(), 220);
  }
  stack.append(el);
  setTimeout(remove, timeout);
}

function openModal({ title, body, wide = false }) {
  const root = $('#modal-root');
  lastFocused = document.activeElement;
  root.innerHTML = `
    <div class="modal-backdrop" data-action="close-modal">
      <div class="modal-panel ${wide ? 'modal-wide' : ''}" role="dialog" aria-modal="true" aria-labelledby="modal-title" tabindex="-1">
        <header class="modal-head">
          <h2 id="modal-title">${esc(title)}</h2>
          <button type="button" class="icon-btn" data-action="close-modal" aria-label="Close dialog">${icon('close')}</button>
        </header>
        <div class="modal-body">${body}</div>
      </div>
    </div>`;
  document.body.classList.add('modal-open');
  window.requestAnimationFrame(() => {
    root.querySelector('.modal-panel')?.focus();
  });
}

function closeModal() {
  const root = $('#modal-root');
  root.innerHTML = '';
  document.body.classList.remove('modal-open');
  if (pendingConfirm) {
    const resolve = pendingConfirm;
    pendingConfirm = null;
    resolve(false);
  }
  if (lastFocused && typeof lastFocused.focus === 'function') {
    const el = lastFocused;
    lastFocused = null;
    window.requestAnimationFrame(() => el.focus?.());
  }
}

function confirmDialog({ title, message, confirmLabel = 'Confirm', danger = false }) {
  return new Promise((resolve) => {
    pendingConfirm = resolve;
    openModal({
      title,
      body: `
        <p class="modal-text">${esc(message)}</p>
        <div class="modal-actions">
          <button type="button" class="btn" data-action="confirm-no">Cancel</button>
          <button type="button" class="btn ${danger ? 'btn-danger' : 'btn-primary'}" data-action="confirm-yes">${esc(confirmLabel)}</button>
        </div>`,
    });
  });
}

function answerConfirm(value) {
  const resolve = pendingConfirm;
  pendingConfirm = null;
  closeModal();
  resolve?.(value);
}

/* ------------------------------------------------------------------ */
/* Practice lifecycle                                                  */
/* ------------------------------------------------------------------ */

function starterPractice() {
  const p = core.createPractice({ title: 'First practice', group: 'Squad', focus: 'Getting going' });
  p.sets = [
    core.createSet({ type: 'warmup', reps: 4, distance: 100, stroke: 'Free', rest: 20, notes: 'Easy, long strokes.' }),
    core.createSet({ type: 'main', reps: 8, distance: 50, stroke: 'Free', rest: 20, notes: 'Steady pace, hold your form.' }),
    core.createSet({ type: 'cooldown', reps: 4, distance: 100, stroke: 'Choice', rest: 20, notes: 'Easy choice.' }),
  ];
  return p;
}

function comparablePractice(practice) {
  return JSON.stringify({
    title: practice.title,
    date: practice.date,
    course: practice.course,
    basePace: practice.basePace,
    roundTo: practice.roundTo,
    group: practice.group,
    focus: practice.focus,
    notes: practice.notes,
    sets: practice.sets,
  });
}

function initPractice() {
  const draft = store.loadDraft();
  if (draft) {
    state.practice = draft.practice;
    const saved = store.getPractice(draft.practice.id);
    state.savedEver = Boolean(saved);
    state.dirty = saved ? comparablePractice(saved) !== comparablePractice(draft.practice) : true;
    return;
  }
  const saved = store.loadPractices();
  if (saved.length) {
    state.practice = saved[0];
    state.savedEver = true;
    state.dirty = false;
    return;
  }
  state.practice = starterPractice();
  state.savedEver = false;
  state.dirty = true;
}

function touch() {
  state.dirty = true;
  updateSaveState();
  scheduleDraft();
}

function scheduleDraft() {
  clearTimeout(draftTimer);
  draftTimer = setTimeout(() => {
    if (state.storageOk) store.saveDraft(state.practice);
  }, 300);
}

function savePractice() {
  if (!state.storageOk) {
    toast('Local storage is blocked, so this practice cannot be saved.', { tone: 'error' });
    return;
  }
  try {
    const saved = store.savePractice(state.practice);
    state.practice = saved;
    state.dirty = false;
    state.savedEver = true;
    store.saveDraft(saved);
    updateSaveState();
    updateNavCount();
    toast('Practice saved to your library', { tone: 'success' });
  } catch (error) {
    toast(error.message || 'Could not save the practice.', { tone: 'error' });
  }
}

function updateSaveState() {
  const el = $('[data-role="save-state"]');
  if (!el) return;
  let label = 'Not saved yet';
  let key = 'new';
  if (state.savedEver && state.dirty) {
    label = 'Unsaved changes';
    key = 'dirty';
  } else if (state.savedEver) {
    label = 'Saved to library';
    key = 'saved';
  }
  el.textContent = label;
  el.dataset.state = key;
}

function updateNavCount() {
  const el = $('#nav-count');
  if (!el) return;
  const count = store.loadPractices().length;
  el.textContent = count ? String(count) : '';
  el.hidden = !count;
}

async function maybeDiscard() {
  if (!state.dirty || !state.practice.sets.length) return true;
  return confirmDialog({
    title: 'Discard unsaved changes?',
    message: 'The current practice has changes that are not in your library yet. Continue and they will be lost.',
    confirmLabel: 'Discard',
    danger: true,
  });
}

async function newPractice() {
  if (!(await maybeDiscard())) return;
  state.practice = core.createPractice({ title: 'Untitled practice', course: state.practice.course, basePace: state.practice.basePace });
  state.dirty = true;
  state.savedEver = false;
  state.openDetails.clear();
  store.clearDraft();
  scheduleDraft();
  render();
  navigate('builder');
  window.requestAnimationFrame(() => $('.title-input')?.select());
}

async function duplicateCurrentPractice() {
  const copy = core.clonePractice(state.practice);
  state.practice = copy;
  state.dirty = true;
  state.savedEver = false;
  store.clearDraft();
  scheduleDraft();
  render();
  navigate('builder');
  toast('Duplicated as a new practice');
}

function openPractice(id) {
  const practice = store.getPractice(id);
  if (!practice) return;
  state.practice = practice;
  state.dirty = false;
  state.savedEver = true;
  state.openDetails.clear();
  store.saveDraft(practice);
  navigate('builder');
  render();
}

/* ------------------------------------------------------------------ */
/* Builder rendering                                                   */
/* ------------------------------------------------------------------ */

function renderBuilder() {
  const p = state.practice;
  const totals = core.practiceTotals(p);
  const unit = setUnit(p);
  const storageBanner = state.storageOk
    ? ''
    : `<div class="banner banner-warn">${icon('warning')} Local storage is blocked in this browser. You can build and print practices, but saving is unavailable.</div>`;

  $('#view-builder').innerHTML = `
    ${storageBanner}
    <div class="builder-layout">
      <div class="builder-main">
        <section class="card practice-head" aria-label="Practice details">
          <div class="practice-title-row">
            <label class="title-wrap">
              <span class="sr-only">Practice title</span>
              <input class="title-input" type="text" maxlength="120" data-field="title" value="${esc(p.title)}" placeholder="Name this practice" autocomplete="off" spellcheck="false" />
            </label>
            <div class="head-actions">
              <button type="button" class="btn btn-primary" data-action="save-practice">${icon('save')}<span class="btn-label">Save</span></button>
              <button type="button" class="btn btn-accent" data-action="start-run">${icon('play')}<span class="btn-label">Poolside</span></button>
              <details class="menu">
                <summary class="btn btn-ghost" aria-label="More actions" title="More actions">${icon('more')}</summary>
                <div class="menu-panel">
                  <button type="button" data-action="new-practice">${icon('plus')} New practice</button>
                  <button type="button" data-action="duplicate-practice">${icon('copy')} Duplicate</button>
                  <button type="button" data-action="open-templates">${icon('template')} Templates</button>
                  <hr />
                  <button type="button" data-action="print-practice">${icon('print')} Print practice sheet</button>
                  <button type="button" data-action="export-text">${icon('download')} Download text</button>
                  <button type="button" data-action="export-json">${icon('download')} Download JSON</button>
                  <button type="button" data-action="copy-text">${icon('copy')} Copy as text</button>
                  <button type="button" data-action="share-practice">${icon('share')} Share</button>
                </div>
              </details>
            </div>
          </div>

          <div class="meta-grid">
            <label class="field">
              <span>Date</span>
              <input type="date" data-field="date" value="${esc(p.date)}" />
            </label>
            <label class="field">
              <span>Course</span>
              <select data-field="course">${courseOptions(p.course)}</select>
            </label>
            <label class="field">
              <span>Base pace / 100 ${unit}</span>
              <input type="text" inputmode="numeric" data-field="basePace" value="${esc(core.formatClock(p.basePace))}" placeholder="1:30" autocomplete="off" />
            </label>
            <label class="field">
              <span>Round send-offs</span>
              <select data-field="roundTo">
                ${core.ROUND_STEPS.map((s) => `<option value="${s}" ${p.roundTo === s ? 'selected' : ''}>${s === 1 ? 'No rounding' : `To ${s} sec`}</option>`).join('')}
              </select>
            </label>
            <label class="field">
              <span>Group</span>
              <input type="text" maxlength="80" data-field="group" value="${esc(p.group)}" placeholder="e.g. Senior squad" autocomplete="off" />
            </label>
            <label class="field">
              <span>Focus</span>
              <input type="text" maxlength="120" data-field="focus" value="${esc(p.focus)}" placeholder="e.g. Sprint speed" autocomplete="off" />
            </label>
          </div>

          <label class="field">
            <span>Practice notes</span>
            <textarea rows="2" data-field="notes" maxlength="2000" placeholder="Warm-up instructions, lane assignments, reminders…">${esc(p.notes)}</textarea>
          </label>

          <div class="practice-foot">
            <span class="save-state" data-role="save-state" data-state="new">Not saved yet</span>
            <span class="muted" data-out="foot-summary">${totals.setCount} sets · ${core.formatNumber(totals.distance)} ${unit} · ~${core.formatDuration(totals.seconds)}</span>
          </div>
        </section>

        <div class="set-list" id="set-list">
          ${p.sets.length ? p.sets.map((set, i) => renderSetCard(set, i, p)).join('') : emptySetsHTML()}
        </div>

        <div class="add-row">
          <button type="button" class="btn btn-dashed grow" data-action="add-set">${icon('plus')} Add set</button>
          <button type="button" class="btn" data-action="open-templates">${icon('template')} Templates</button>
          <span class="muted small add-tip">Send-offs calculate from base pace and rest.</span>
        </div>
      </div>

      <aside class="builder-side" aria-label="Practice summary">
        <div class="card summary-card">
          <div class="summary-hero">
            <span class="hero-number" data-out="distance">${core.formatNumber(totals.distance)}</span>
            <span class="hero-unit" data-out="unit">${unit}</span>
            <span class="hero-label">total volume</span>
          </div>
          <div class="summary-grid">
            <div><strong data-out="time">${core.formatDuration(totals.seconds)}</strong><span>est. session</span></div>
            <div><strong data-out="reps">${core.formatNumber(totals.reps)}</strong><span>reps</span></div>
            <div><strong data-out="setcount">${totals.setCount}</strong><span>sets</span></div>
            <div><strong data-out="pace">${esc(core.formatClock(p.basePace))}</strong><span>base /100</span></div>
          </div>
          <div class="stroke-split" id="stroke-split"></div>
          <button type="button" class="btn btn-primary btn-block" data-action="start-run">${icon('play')} Start poolside</button>
          <p class="summary-hint">Offline-ready · everything stays on this device</p>
        </div>

        <div class="card issues-card">
          <h2 class="card-title">${icon('check')} Practice check</h2>
          <div id="issue-list"></div>
        </div>
      </aside>
    </div>`;

  updateSaveState();
  refreshDerived();
  updateThemeIcon();
}

function emptySetsHTML() {
  return `
    <div class="card empty-sets">
      <div class="empty-icon">${icon('waves')}</div>
      <h2>No sets yet</h2>
      <p>Add sets one by one, or start from one of the built-in workouts.</p>
      <div class="row-gap center">
        <button type="button" class="btn btn-primary" data-action="add-set">${icon('plus')} Add a set</button>
        <button type="button" class="btn" data-action="open-templates">${icon('template')} Browse templates</button>
      </div>
    </div>`;
}

function renderSetCard(set, index, practice) {
  const type = typeOf(set.type);
  const unit = setUnit(practice);
  const sendoff = core.sendoffForSet(set, practice);
  const open = state.openDetails.has(set.id);
  const volume = set.reps * set.distance;
  const swim = core.swimSecondsForSet(set, practice);
  const isManual = set.intervalMode === 'manual';
  const isNone = set.intervalMode === 'none';

  const sendoffBox = isManual
    ? `<input class="sendoff-input" type="text" inputmode="numeric" data-set-id="${set.id}" data-field="interval"
         value="${sendoff ? esc(core.formatClock(sendoff)) : ''}" aria-label="Custom send-off" placeholder="1:30" autocomplete="off" />`
    : `<strong data-out-set="sendoff">${sendoff ? esc(core.formatClock(sendoff)) : '—'}</strong><small>${isNone ? 'continuous' : 'auto'}</small>`;

  const equipment = core.EQUIPMENT.map(
    (item) => `<button type="button" class="chip ${set.equipment.includes(item) ? 'is-on' : ''}"
      data-action="toggle-equipment" data-id="${set.id}" data-equip="${esc(item)}"
      aria-pressed="${set.equipment.includes(item)}">${esc(item)}</button>`
  ).join('');

  return `
    <article class="set-card" data-set-id="${set.id}" style="--set-color:${type.color}" aria-label="Set ${index + 1}">
      <header class="set-head">
        <span class="set-badge" aria-hidden="true">${type.short}</span>
        <label class="type-field">
          <span class="sr-only">Set type</span>
          <select class="type-select" data-set-id="${set.id}" data-field="type">
            ${core.SET_TYPES.map((t) => `<option value="${t.id}" ${t.id === set.type ? 'selected' : ''}>${t.label}</option>`).join('')}
          </select>
        </label>
        <span class="set-index">Set ${index + 1}</span>
        <div class="set-buttons">
          <button type="button" class="icon-btn" data-action="move-set-up" data-id="${set.id}" aria-label="Move set ${index + 1} up" title="Move up" ${index === 0 ? 'disabled' : ''}>${icon('up')}</button>
          <button type="button" class="icon-btn" data-action="move-set-down" data-id="${set.id}" aria-label="Move set ${index + 1} down" title="Move down" ${index === state.practice.sets.length - 1 ? 'disabled' : ''}>${icon('down')}</button>
          <button type="button" class="icon-btn" data-action="duplicate-set" data-id="${set.id}" aria-label="Duplicate set ${index + 1}" title="Duplicate">${icon('copy')}</button>
          <button type="button" class="icon-btn" data-action="toggle-details" data-id="${set.id}" aria-label="Options for set ${index + 1}" title="More options" aria-expanded="${open}">${icon('sliders')}</button>
          <button type="button" class="icon-btn danger" data-action="delete-set" data-id="${set.id}" aria-label="Delete set ${index + 1}" title="Delete">${icon('trash')}</button>
        </div>
      </header>

      <div class="set-grid">
        <label class="field compact reps-field">
          <span>Reps</span>
          <input type="number" min="1" max="999" inputmode="numeric" value="${set.reps}" data-set-id="${set.id}" data-field="reps" />
        </label>
        <span class="times" aria-hidden="true">×</span>
        <label class="field compact distance-field">
          <span>Distance</span>
          <div class="with-suffix">
            <input type="number" min="1" max="10000" step="25" inputmode="numeric" value="${set.distance}" data-set-id="${set.id}" data-field="distance" />
            <span class="suffix">${unit}</span>
          </div>
        </label>
        <label class="field compact stroke-field">
          <span>Stroke</span>
          <select data-set-id="${set.id}" data-field="stroke">
            ${core.STROKES.map((s) => `<option value="${s}" ${s === set.stroke ? 'selected' : ''}>${s}</option>`).join('')}
          </select>
        </label>
        <div class="field compact sendoff-field">
          <span>Send-off</span>
          <div class="sendoff-box ${isManual ? 'manual' : ''}">${sendoffBox}</div>
        </div>
      </div>

      <div class="set-foot">
        <span data-out-set="volume">${core.formatNumber(volume)} ${unit}</span>
        <span data-out-set="swim">swim ${core.formatDuration(swim)}</span>
        <span data-out-set="rest">rest ${set.rest}s</span>
        ${set.equipment.length ? `<span class="equip-inline">${set.equipment.map(esc).join(' + ')}</span>` : ''}
        ${open ? '' : `<span class="set-hint">${set.notes ? esc(set.notes) : ''}</span>`}
      </div>

      ${open ? renderSetDetails(set, practice) : ''}
    </article>`;
}

function renderSetDetails(set, practice) {
  return `
    <div class="set-details">
      <label class="field">
        <span>Interval</span>
        <select data-set-id="${set.id}" data-field="intervalMode">
          <option value="pace" ${set.intervalMode === 'pace' ? 'selected' : ''}>Auto — pace + rest</option>
          <option value="manual" ${set.intervalMode === 'manual' ? 'selected' : ''}>Custom send-off</option>
          <option value="none" ${set.intervalMode === 'none' ? 'selected' : ''}>No interval</option>
        </select>
      </label>
      <label class="field">
        <span>Target pace / 100 ${setUnit(practice)}</span>
        <input type="text" inputmode="numeric" data-set-id="${set.id}" data-field="pace100"
          value="${set.pace100 ? esc(core.formatClock(set.pace100)) : ''}"
          placeholder="Base ${core.formatClock(practice.basePace)}" autocomplete="off" />
      </label>
      <label class="field">
        <span>Rest (sec)</span>
        <input type="number" min="0" max="3600" inputmode="numeric" data-set-id="${set.id}" data-field="rest" value="${set.rest}" />
      </label>
      <label class="field notes-field">
        <span>Set notes</span>
        <input type="text" maxlength="500" data-set-id="${set.id}" data-field="notes" value="${esc(set.notes)}" placeholder="e.g. descend 1–4, no paddles" autocomplete="off" />
      </label>
      <div class="field chips-field">
        <span>Equipment</span>
        <div class="chips">${core.EQUIPMENT.map(
          (item) => `<button type="button" class="chip ${set.equipment.includes(item) ? 'is-on' : ''}"
            data-action="toggle-equipment" data-id="${set.id}" data-equip="${esc(item)}"
            aria-pressed="${set.equipment.includes(item)}">${esc(item)}</button>`
        ).join('')}</div>
      </div>
      <div class="detail-actions">
        <button type="button" class="btn btn-sm" data-action="duplicate-set" data-id="${set.id}">${icon('copy')} Duplicate set</button>
      </div>
    </div>`;
}

/* ------------------------------------------------------------------ */
/* Derived / summary refresh                                           */
/* ------------------------------------------------------------------ */

function refreshDerived() {
  const p = state.practice;
  const totals = core.practiceTotals(p);
  const unit = setUnit(p);

  const setText = (selector, text) => $$(selector).forEach((el) => { el.textContent = text; });
  setText('[data-out="distance"]', core.formatNumber(totals.distance));
  setText('[data-out="unit"]', unit);
  setText('[data-out="time"]', core.formatDuration(totals.seconds));
  setText('[data-out="reps"]', core.formatNumber(totals.reps));
  setText('[data-out="setcount"]', String(totals.setCount));
  setText('[data-out="pace"]', core.formatClock(p.basePace));
  setText('[data-out="foot-summary"]', `${totals.setCount} sets · ${core.formatNumber(totals.distance)} ${unit} · ~${core.formatDuration(totals.seconds)}`);
  setText('[data-out="swim"]', core.formatDuration(totals.swimSeconds));

  const split = $('#stroke-split');
  if (split) {
    split.innerHTML = totals.byStroke.length
      ? totals.byStroke.slice(0, 4).map((row) => {
        const pct = Math.round((row.distance / Math.max(1, totals.distance)) * 100);
        return `<div class="split-row"><span class="split-name">${esc(row.stroke)}</span>
          <span class="split-bar"><i style="width:${pct}%"></i></span>
          <span class="split-value">${core.formatNumber(row.distance)}</span></div>`;
      }).join('')
      : '<p class="muted small">Volume by stroke appears here.</p>';
  }

  $$('.set-card').forEach((card) => {
    const set = p.sets.find((s) => s.id === card.dataset.setId);
    if (!set) return;
    const sendoff = core.sendoffForSet(set, p);
    const volume = set.reps * set.distance;
    const swim = core.swimSecondsForSet(set, p);

    const volEl = card.querySelector('[data-out-set="volume"]');
    if (volEl) volEl.textContent = `${core.formatNumber(volume)} ${unit}`;
    const swimEl = card.querySelector('[data-out-set="swim"]');
    if (swimEl) swimEl.textContent = `swim ${core.formatDuration(swim)}`;
    const restEl = card.querySelector('[data-out-set="rest"]');
    if (restEl) restEl.textContent = `rest ${set.rest}s`;

    const sendoffBox = card.querySelector('.sendoff-box');
    if (sendoffBox) {
      if (set.intervalMode === 'manual') {
        const input = sendoffBox.querySelector('input');
        if (input && document.activeElement !== input) input.value = sendoff ? core.formatClock(sendoff) : '';
      } else {
        const strong = sendoffBox.querySelector('[data-out-set="sendoff"]');
        const small = sendoffBox.querySelector('small');
        if (strong) strong.textContent = sendoff ? core.formatClock(sendoff) : '—';
        if (small) small.textContent = set.intervalMode === 'none' ? 'continuous' : 'auto';
      }
    }
  });

  renderIssues();
  updateSaveState();
}

function renderIssues() {
  const target = $('#issue-list');
  if (!target) return;
  const issues = core.validatePractice(state.practice);
  if (!issues.length) {
    target.innerHTML = `<p class="ok-note">${icon('check')} Looks good — ready to swim.</p>`;
    return;
  }
  target.innerHTML = issues.slice(0, 6).map((issue) => `
    <p class="issue issue-${issue.level}">
      ${icon(issue.level === 'error' ? 'warning' : issue.level === 'warn' ? 'warning' : 'info')}
      <span>${esc(issue.message)}</span>
    </p>`).join('');
}

/* ------------------------------------------------------------------ */
/* Library rendering                                                   */
/* ------------------------------------------------------------------ */

function renderLibrary() {
  const practices = store.loadPractices();
  const query = state.library.query.trim().toLowerCase();
  const filtered = practices
    .filter((p) => {
      if (!query) return true;
      return [p.title, p.group, p.focus, ...(p.sets || []).map((s) => s.stroke)]
        .join(' ').toLowerCase().includes(query);
    })
    .sort((a, b) => {
      if (state.library.sort === 'name') return a.title.localeCompare(b.title);
      if (state.library.sort === 'date') return String(b.date).localeCompare(String(a.date));
      if (state.library.sort === 'distance') return core.practiceTotals(b).distance - core.practiceTotals(a).distance;
      return String(b.updatedAt).localeCompare(String(a.updatedAt));
    });

  $('#view-library').innerHTML = `
    <div class="page-head">
      <div>
        <h1>Practice library</h1>
        <p class="muted">${practices.length} saved practice${practices.length === 1 ? '' : 's'} · stored privately on this device</p>
      </div>
      <div class="row-gap">
        <button type="button" class="btn" data-action="import-practices">${icon('upload')} Import</button>
        <button type="button" class="btn" data-action="export-all">${icon('download')} Export all</button>
        <button type="button" class="btn btn-primary" data-action="new-practice">${icon('plus')} New practice</button>
      </div>
    </div>

    <div class="library-toolbar card">
      <label class="search-field">
        <span class="sr-only">Search practices</span>
        ${icon('search')}
        <input type="search" id="library-search" placeholder="Search title, group, focus…" value="${esc(state.library.query)}" autocomplete="off" />
      </label>
      <label class="field inline-field">
        <span>Sort</span>
        <select id="library-sort">
          <option value="updated" ${state.library.sort === 'updated' ? 'selected' : ''}>Recently updated</option>
          <option value="date" ${state.library.sort === 'date' ? 'selected' : ''}>Practice date</option>
          <option value="distance" ${state.library.sort === 'distance' ? 'selected' : ''}>Longest first</option>
          <option value="name" ${state.library.sort === 'name' ? 'selected' : ''}>Name A–Z</option>
        </select>
      </label>
    </div>

    ${practices.length === 0 ? emptyLibraryHTML() : filtered.length === 0 ? `
      <div class="card empty-sets">
        <div class="empty-icon">${icon('search')}</div>
        <h2>No matches</h2>
        <p>No saved practice matches “${esc(state.library.query)}”.</p>
        <button type="button" class="btn" data-action="clear-search">Clear search</button>
      </div>` : `<div class="library-grid">${filtered.map(renderPracticeCard).join('')}</div>`}

    <p class="storage-note muted small">Library uses about ${(store.storageUsageBytes() / 1024).toFixed(0)} KB of browser storage. Export a backup before clearing browser data.</p>`;

  updateNavCount();
}

function emptyLibraryHTML() {
  return `
    <div class="card empty-sets">
      <div class="empty-icon">${icon('book')}</div>
      <h2>Your library is empty</h2>
      <p>Save a practice here to reuse it, print it, or run it at the pool. Nothing leaves this device.</p>
      <div class="row-gap center">
        <button type="button" class="btn btn-primary" data-action="new-practice">${icon('plus')} Create a practice</button>
        <button type="button" class="btn" data-action="open-templates">${icon('template')} Use a template</button>
      </div>
    </div>`;
}

function renderPracticeCard(p) {
  const totals = core.practiceTotals(p);
  return `
    <article class="practice-card card" data-practice-id="${esc(p.id)}">
      <div class="practice-card-top">
        <div>
          <h2>${esc(p.title)}</h2>
          <p class="muted small">${esc(core.formatDate(p.date))}${p.group ? ` · ${esc(p.group)}` : ''}</p>
        </div>
        <span class="course-pill">${esc(p.course)}</span>
      </div>
      ${p.focus ? `<p class="practice-focus">${esc(p.focus)}</p>` : ''}
      <div class="mini-stats">
        <span><strong>${core.formatNumber(totals.distance)}</strong> ${totals.unit}</span>
        <span><strong>${core.formatDuration(totals.seconds)}</strong></span>
        <span><strong>${totals.setCount}</strong> sets</span>
        <span><strong>${esc(core.formatClock(p.basePace))}</strong>/100</span>
      </div>
      <div class="practice-card-actions">
        <button type="button" class="btn btn-primary btn-sm" data-action="open-practice" data-id="${esc(p.id)}">${icon('play')} Open</button>
        <button type="button" class="icon-btn" data-action="duplicate-practice" data-id="${esc(p.id)}" aria-label="Duplicate ${esc(p.title)}" title="Duplicate">${icon('copy')}</button>
        <button type="button" class="icon-btn" data-action="export-practice" data-id="${esc(p.id)}" aria-label="Export ${esc(p.title)} as JSON" title="Export JSON">${icon('download')}</button>
        <button type="button" class="icon-btn danger" data-action="delete-practice" data-id="${esc(p.id)}" aria-label="Delete ${esc(p.title)}" title="Delete">${icon('trash')}</button>
      </div>
    </article>`;
}

/* ------------------------------------------------------------------ */
/* Pace tools                                                          */
/* ------------------------------------------------------------------ */

function renderPace() {
  const tool = state.paceTool;
  $('#view-pace').innerHTML = `
    <div class="page-head">
      <div>
        <h1>Pace &amp; send-off tools</h1>
        <p class="muted">Turn a target pace into send-offs, convert between courses, or work out a pace from a swim time.</p>
      </div>
    </div>

    <div class="pace-grid">
      <section class="card pace-card">
        <h2 class="card-title">${icon('timer')} Send-off ladder</h2>
        <div class="form-row three">
          <label class="field"><span>Pace /100</span>
            <input type="text" inputmode="numeric" data-pace="base" value="${esc(core.formatClock(tool.base))}" autocomplete="off" />
          </label>
          <label class="field"><span>Rest (sec)</span>
            <input type="number" min="0" max="600" data-pace="rest" value="${tool.rest}" />
          </label>
          <label class="field"><span>Round up to</span>
            <select data-pace="round">
              ${core.ROUND_STEPS.map((s) => `<option value="${s}" ${tool.round === s ? 'selected' : ''}>${s === 1 ? 'No rounding' : `${s} sec`}</option>`).join('')}
            </select>
          </label>
        </div>
        <table class="data-table">
          <thead><tr><th>Rep distance</th><th>Swim target</th><th>Send-off</th></tr></thead>
          <tbody id="pace-ladder-body">${paceLadderRows(tool)}</tbody>
        </table>
        <p class="muted small">${icon('info')} Send-off = swim target + rest, rounded up. The same maths powers the builder.</p>
      </section>

      <section class="card pace-card">
        <h2 class="card-title">${icon('waves')} Course converter</h2>
        <div class="form-row three">
          <label class="field"><span>Swim time</span>
            <input type="text" inputmode="numeric" data-pace="time" value="${esc(core.formatClockDecimal(tool.time))}" autocomplete="off" />
          </label>
          <label class="field"><span>From</span>
            <select data-pace="from">${core.COURSE_IDS.map((id) => `<option value="${id}" ${id === tool.from ? 'selected' : ''}>${core.COURSES[id].label}</option>`).join('')}</select>
          </label>
          <label class="field"><span>To</span>
            <select data-pace="to">${core.COURSE_IDS.map((id) => `<option value="${id}" ${id === tool.to ? 'selected' : ''}>${core.COURSES[id].label}</option>`).join('')}</select>
          </label>
        </div>
        <div id="pace-convert">${paceConvertHTML(tool)}</div>
        <p class="muted small">${icon('info')} Approximate training estimate (SCY → SCM ×1.11, SCY → LCM ×1.13). Not an official conversion — use it as a starting point.</p>
      </section>

      <section class="card pace-card">
        <h2 class="card-title">${icon('spark')} Pace from a swim</h2>
        <div class="form-row">
          <label class="field"><span>Time swum</span>
            <input type="text" inputmode="numeric" data-pace="knownTime" value="${esc(core.formatClockDecimal(tool.knownTime))}" autocomplete="off" />
          </label>
          <label class="field"><span>Distance</span>
            <input type="number" min="25" step="25" data-pace="knownDistance" value="${tool.knownDistance}" />
          </label>
        </div>
        <div id="pace-known">${paceKnownHTML(tool)}</div>
        <p class="muted small">${icon('info')} Gives the pace per 100 for that swim. Use it as a base pace or a per-set target.</p>
      </section>

      <section class="card pace-card explainer-card">
        <h2 class="card-title">${icon('book')} How it works</h2>
        <ul class="explain-list">
          <li><strong>Base pace</strong> is the practice anchor: the time you want each 100 swum in (e.g. 1:40).</li>
          <li><strong>Target pace</strong> on a set overrides the base pace for that set only.</li>
          <li><strong>Auto send-off</strong> = target time for the rep + rest, rounded up to your chosen step.</li>
          <li><strong>Custom send-off</strong> lets you write the interval exactly, e.g. <span class="mono">1:30</span>.</li>
          <li><strong>No interval</strong> is for continuous swims; the runner counts the estimated swim time instead.</li>
        </ul>
      </section>
    </div>`;
  updateThemeIcon();
}

function paceLadderRows(tool) {
  if (!(tool.base > 0)) return `<tr><td colspan="3" class="muted">Enter a base pace like 1:40.</td></tr>`;
  return core.paceLadder(tool.base, { roundTo: tool.round, rest: tool.rest })
    .map((row) => `
      <tr>
        <td>${row.distance}</td>
        <td>${esc(core.formatClock(row.swim))}</td>
        <td><strong>${esc(core.formatClock(row.sendoff))}</strong></td>
      </tr>`)
    .join('');
}

function paceConvertHTML(tool) {
  if (!(tool.time > 0)) return '<p class="muted">Enter a swim time like 1:52.5.</p>';
  const selected = core.convertTime(tool.time, tool.from, tool.to);
  const rows = core.COURSE_IDS.map((id) => {
    const converted = core.convertTime(tool.time, tool.from, id);
    return `<tr class="${id === tool.to ? 'is-current' : ''}">
      <td>${core.COURSES[id].label}<span class="muted small"> · ${core.COURSES[id].length} ${core.COURSES[id].unit}</span></td>
      <td><strong>${esc(core.formatClockDecimal(converted))}</strong></td>
    </tr>`;
  }).join('');
  return `
    <div class="convert-hero">
      <span class="convert-label">${esc(core.COURSES[tool.from].label)} → ${esc(core.COURSES[tool.to].label)}</span>
      <span class="convert-result">${esc(core.formatClockDecimal(selected))}</span>
    </div>
    <table class="data-table compact-table">
      <thead><tr><th>Course</th><th>Equivalent</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>`;
}

function paceKnownHTML(tool) {
  if (!(tool.knownTime > 0) || !(tool.knownDistance > 0)) {
    return '<p class="muted">Enter a time and a distance.</p>';
  }
  const per100 = (tool.knownTime / tool.knownDistance) * 100;
  const sendoff = (distance) => core.roundUpTo((distance / 100) * per100, tool.round);
  return `
    <div class="convert-hero">
      <span class="convert-label">Pace per 100</span>
      <span class="convert-result">${esc(core.formatClockDecimal(per100))}</span>
    </div>
    <div class="mini-stats known-stats">
      <span><strong>${esc(core.formatClock(sendoff(50)))}</strong> /50 send-off</span>
      <span><strong>${esc(core.formatClock(sendoff(100)))}</strong> /100 send-off</span>
      <span><strong>${esc(core.formatClock(sendoff(200)))}</strong> /200 send-off</span>
    </div>`;
}

function refreshPace() {
  const tool = state.paceTool;
  const ladder = $('#pace-ladder-body');
  if (ladder) ladder.innerHTML = paceLadderRows(tool);
  const convert = $('#pace-convert');
  if (convert) convert.innerHTML = paceConvertHTML(tool);
  const known = $('#pace-known');
  if (known) known.innerHTML = paceKnownHTML(tool);
}

/* ------------------------------------------------------------------ */
/* Poolside runner                                                     */
/* ------------------------------------------------------------------ */

function fingerprintPractice() {
  return JSON.stringify({
    sets: state.practice.sets,
    basePace: state.practice.basePace,
    roundTo: state.practice.roundTo,
    course: state.practice.course,
  });
}

function resetRunState() {
  stopTimer();
  const run = state.run;
  run.steps = core.compileSteps(state.practice);
  run.index = 0;
  run.elapsedMs = 0;
  run.running = false;
  run.finished = false;
  run.beeped3 = false;
  run.fingerprint = fingerprintPractice();
  run.remainingMs = run.steps.length ? stepDuration(run.steps[0]) * 1000 : 0;
}

function stepDuration(step) {
  if (!step) return 0;
  return step.sendoff || step.swim || 0;
}

function renderRun() {
  const view = $('#view-run');
  const run = state.run;
  const p = state.practice;

  if (!p.sets.length) {
    view.innerHTML = `
      <div class="card empty-sets">
        <div class="empty-icon">${icon('waves')}</div>
        <h2>Nothing to swim yet</h2>
        <p>Add sets to the practice, then come back to run it poolside.</p>
        <a class="btn btn-primary" href="#/builder">${icon('arrowLeft')} Back to builder</a>
      </div>`;
    return;
  }

  if (!run.running && run.fingerprint !== fingerprintPractice()) {
    resetRunState();
  }
  if (!run.steps.length) resetRunState();

  const step = run.steps[run.index] || run.steps[0];
  const type = typeOf(step.type);

  view.innerHTML = `
    <div class="run-wrap">
      <div class="run-header">
        <a class="btn btn-ghost" href="#/builder">${icon('arrowLeft')} Builder</a>
        <div class="run-title">
          <h1>${esc(p.title)}</h1>
          <p class="muted small">${esc(core.COURSES[p.course].label)} · ${esc(core.formatNumber(core.practiceTotals(p).distance))} ${esc(core.unitFor(p))} · ${run.steps.length} reps</p>
        </div>
        <div class="run-header-actions">
          <button type="button" class="icon-btn" data-action="toggle-mute" aria-pressed="${run.muted}" title="${run.muted ? 'Unmute' : 'Mute'} beeps" aria-label="Toggle sound">${icon(run.muted ? 'mute' : 'sound')}</button>
          <button type="button" class="icon-btn" data-action="toggle-fullscreen" title="Fullscreen" aria-label="Toggle fullscreen">${icon('expand')}</button>
        </div>
      </div>

      <div class="run-stage">
        <div class="card run-main">
          <div class="run-set-head">
            <span class="set-badge" data-run="type-badge" style="--set-color:${type.color}">${type.short}</span>
            <span class="run-set-label" data-run="setnum">Set ${step.setIndex + 1} of ${p.sets.length}</span>
            <span class="run-rep" data-run="rep">Rep ${step.rep} of ${step.reps}</span>
          </div>
          <h2 class="run-label" data-run="label">${esc(step.label)}</h2>
          <p class="run-notes" data-run="notes">${step.notes ? esc(step.notes) : ''}</p>

          <div class="timer-wrap">
            <svg class="timer-ring" viewBox="0 0 220 220" aria-hidden="true">
              <circle class="ring-track" cx="110" cy="110" r="96"></circle>
              <circle class="ring-progress" cx="110" cy="110" r="96" data-run="ring"></circle>
            </svg>
            <div class="timer-center">
              <span class="timer-time" data-run="remaining">—</span>
              <span class="timer-caption" data-run="caption">send-off</span>
            </div>
          </div>

          <div class="run-progress">
            <div class="progress-bar"><i data-run="overall-bar" style="width:0%"></i></div>
            <div class="progress-meta">
              <span>Rep <strong data-run="step-number">1</strong> / ${run.steps.length}</span>
              <span>Elapsed <strong data-run="elapsed">0:00</strong></span>
            </div>
          </div>

          <div class="run-controls">
            <button type="button" class="btn btn-round" data-action="run-prev" aria-label="Previous rep" title="Previous rep">${icon('prev')}</button>
            <button type="button" class="btn btn-primary btn-play" data-action="play-pause" data-run="play">
              ${icon('play')}<span>Start</span>
            </button>
            <button type="button" class="btn btn-round" data-action="run-next" aria-label="Next rep" title="Next rep">${icon('next')}</button>
            <button type="button" class="btn btn-round" data-action="run-reset" aria-label="Reset run" title="Reset">${icon('reset')}</button>
          </div>

          <div class="run-options">
            <button type="button" class="chip ${run.autoAdvance ? 'is-on' : ''}" data-action="toggle-auto" aria-pressed="${run.autoAdvance}">
              ${icon('check')} Auto-advance
            </button>
            <span class="muted small">Beeps at 3-2-1 and at the end of each send-off.</span>
          </div>

          <p class="up-next" data-run="upnext"></p>
        </div>

        <aside class="card run-list-card">
          <div class="run-list-head">
            <h2 class="card-title">${icon('book')} Practice plan</h2>
            <span class="muted small">${p.sets.length} sets</span>
          </div>
          <ol class="run-list" id="run-list">${runListHTML()}</ol>
        </aside>
      </div>
    </div>`;

  updateThemeIcon();
  syncRun();
}

function runListHTML() {
  const run = state.run;
  return run.steps.map((step, i) => `
    <li class="${i === run.index ? 'current' : ''} ${i < run.index ? 'done' : ''}">
      <button type="button" data-action="run-jump" data-index="${i}">
        <span class="step-num">${i + 1}</span>
        <span class="step-body">
          <span class="step-label">${esc(step.label)}</span>
          <span class="step-sub">${step.reps > 1 ? `Rep ${step.rep}/${step.reps}` : 'Single rep'}${step.equipment?.length ? ` · ${esc(step.equipment.join(' + '))}` : ''}</span>
        </span>
      </button>
    </li>`).join('');
}

function syncRun() {
  const run = state.run;
  const step = run.steps[run.index];
  if (!step) return;
  const type = typeOf(step.type);
  const badge = $('[data-run="type-badge"]');
  if (badge) {
    badge.textContent = type.short;
    badge.style.setProperty('--set-color', type.color);
  }
  const setnum = $('[data-run="setnum"]');
  if (setnum) setnum.textContent = `Set ${step.setIndex + 1} of ${state.practice.sets.length} · ${type.label}`;
  const rep = $('[data-run="rep"]');
  if (rep) rep.textContent = `Rep ${step.rep} of ${step.reps}`;
  const label = $('[data-run="label"]');
  if (label) label.textContent = step.label;
  const notes = $('[data-run="notes"]');
  if (notes) notes.textContent = step.notes || (step.equipment?.length ? `Equipment: ${step.equipment.join(', ')}` : '');
  const caption = $('[data-run="caption"]');
  if (caption) caption.textContent = step.sendoff ? 'on the send-off' : 'estimated swim';
  const stepNumber = $('[data-run="step-number"]');
  if (stepNumber) stepNumber.textContent = String(run.index + 1);
  const upnext = $('[data-run="upnext"]');
  if (upnext) {
    const next = run.steps[run.index + 1];
    upnext.innerHTML = run.finished
      ? `${icon('check')} Practice complete. Nice work.`
      : next
        ? `Up next: <strong>${esc(next.label)}</strong>${next.reps > 1 ? ` · rep ${next.rep}/${next.reps}` : ''}`
        : 'Last rep — finish strong.';
  }
  const list = $('#run-list');
  if (list) {
    list.innerHTML = runListHTML();
    const card = list.closest('.run-list-card');
    const row = list.querySelector('li.current');
    if (row) {
      const listRect = list.getBoundingClientRect();
      const rowRect = row.getBoundingClientRect();
      if (rowRect.top < listRect.top) list.scrollTop -= listRect.top - rowRect.top + 4;
      else if (rowRect.bottom > listRect.bottom) list.scrollTop += rowRect.bottom - listRect.bottom + 4;
    }
    if (card) card.classList.toggle('is-scrollable', list.scrollHeight > list.clientHeight + 4);
  }
  const bar = $('[data-run="overall-bar"]');
  if (bar) bar.style.width = `${Math.round((run.index / run.steps.length) * 100)}%`;
  updateRunButtons();
  updateTimerDisplay();
}

function updateRunButtons() {
  const run = state.run;
  const play = $('[data-run="play"]');
  if (play) {
    play.classList.toggle('is-running', run.running);
    play.innerHTML = run.running ? `${icon('pause')}<span>Pause</span>` : run.finished ? `${icon('reset')}<span>Restart</span>` : `${icon('play')}<span>Start</span>`;
    play.setAttribute('aria-label', run.running ? 'Pause timer' : 'Start timer');
  }
  const mute = $('[data-action="toggle-mute"]');
  if (mute) {
    mute.setAttribute('aria-pressed', String(run.muted));
    mute.innerHTML = icon(run.muted ? 'mute' : 'sound');
  }
  const auto = $('[data-action="toggle-auto"]');
  if (auto) {
    auto.classList.toggle('is-on', run.autoAdvance);
    auto.setAttribute('aria-pressed', String(run.autoAdvance));
  }
  const prev = $('[data-action="run-prev"]');
  if (prev) prev.disabled = run.index === 0;
}

const RING_CIRCUMFERENCE = 2 * Math.PI * 96;

function formatElapsed(seconds) {
  const text = core.formatClock(seconds);
  return text.startsWith(':') ? `0${text}` : text;
}

function updateTimerDisplay() {
  const run = state.run;
  const step = run.steps[run.index];
  if (!step) return;
  const dur = stepDuration(step);
  const remaining = Math.max(0, run.remainingMs ?? dur * 1000);
  const remainingSec = Math.ceil(remaining / 1000);
  const remainingEl = $('[data-run="remaining"]');
  if (remainingEl) remainingEl.textContent = dur > 0 ? core.formatClock(remainingSec) : '—';
  const ring = $('[data-run="ring"]');
  if (ring) {
    const ratio = dur > 0 ? Math.min(1, Math.max(0, remaining / (dur * 1000))) : 0;
    ring.style.strokeDasharray = String(RING_CIRCUMFERENCE);
    ring.style.strokeDashoffset = String(RING_CIRCUMFERENCE * (1 - ratio));
    ring.classList.toggle('is-urgent', dur > 0 && remaining <= 5000 && remaining > 0);
  }
  const timerWrap = $('.timer-wrap');
  if (timerWrap) timerWrap.classList.toggle('is-paused', !run.running && !run.finished);
  const elapsed = $('[data-run="elapsed"]');
  if (elapsed) elapsed.textContent = formatElapsed(Math.floor(run.elapsedMs / 1000));
}

function playPause() {
  const run = state.run;
  if (run.finished) {
    resetRunState();
    renderRun();
    return;
  }
  if (run.running) {
    pauseRun();
    return;
  }
  if (!run.steps[run.index]) return;
  if (!(run.remainingMs > 0)) {
    // The previous send-off already finished. Advance rather than repeat it.
    if (run.index < run.steps.length - 1) run.index += 1;
    run.finished = false;
    run.beeped3 = false;
    syncRun();
  }
  const step = run.steps[run.index];
  ensureAudio();
  if (!(run.remainingMs > 0)) run.remainingMs = stepDuration(step) * 1000;
  run.lastTick = performance.now();
  run.running = true;
  clearInterval(run.timerId);
  run.timerId = setInterval(tickRun, 200);
  requestWakeLock();
  updateRunButtons();
  updateTimerDisplay();
}

function pauseRun() {
  const run = state.run;
  run.running = false;
  clearInterval(run.timerId);
  run.timerId = null;
  releaseWakeLock();
  updateRunButtons();
  updateTimerDisplay();
}

function stopTimer() {
  const run = state.run;
  run.running = false;
  if (run.timerId) clearInterval(run.timerId);
  run.timerId = null;
  releaseWakeLock();
}

function tickRun() {
  const run = state.run;
  const step = run.steps[run.index];
  if (!step) return;
  const now = performance.now();
  const dt = Math.min(1200, now - (run.lastTick || now));
  run.lastTick = now;
  run.elapsedMs += dt;
  const dur = stepDuration(step);

  if (dur > 0) {
    run.remainingMs = Math.max(0, run.remainingMs - dt);
    const secondsLeft = run.remainingMs / 1000;
    if (!run.beeped3 && secondsLeft <= 3.05 && secondsLeft > 0 && dur > 4) {
      run.beeped3 = true;
      chime(880, 0.07);
    }
    if (run.remainingMs <= 0) {
      chime(1320, 0.22);
      if (run.autoAdvance) {
        if (run.index < run.steps.length - 1) {
          advanceRun(1);
          return;
        }
        finishRun();
        return;
      }
      run.running = false;
      clearInterval(run.timerId);
      run.timerId = null;
      releaseWakeLock();
      updateRunButtons();
    }
  }
  updateTimerDisplay();
}

function advanceRun(delta) {
  const run = state.run;
  const next = Math.min(run.steps.length - 1, Math.max(0, run.index + delta));
  if (next === run.index) return;
  run.index = next;
  run.remainingMs = stepDuration(run.steps[next]) * 1000;
  run.beeped3 = false;
  run.lastTick = performance.now();
  syncRun();
}

function finishRun() {
  const run = state.run;
  run.running = false;
  run.finished = true;
  run.remainingMs = 0;
  clearInterval(run.timerId);
  run.timerId = null;
  releaseWakeLock();
  chime(1320, 0.18);
  setTimeout(() => chime(1568, 0.18), 180);
  setTimeout(() => chime(1976, 0.24), 360);
  syncRun();
  toast('Practice complete — nice work!', { tone: 'success' });
}

function jumpToStep(index) {
  const run = state.run;
  if (!run.steps[index]) return;
  run.index = index;
  run.remainingMs = stepDuration(run.steps[index]) * 1000;
  run.beeped3 = false;
  run.lastTick = performance.now();
  run.finished = false;
  syncRun();
}

/* Audio + wake lock */

function ensureAudio() {
  if (audioCtx) {
    if (audioCtx.state === 'suspended') audioCtx.resume();
    return;
  }
  const Ctx = window.AudioContext || window.webkitAudioContext;
  if (!Ctx) return;
  try {
    audioCtx = new Ctx();
  } catch {
    audioCtx = null;
  }
}

function chime(frequency, duration) {
  if (state.run.muted) return;
  ensureAudio();
  if (!audioCtx) return;
  try {
    const now = audioCtx.currentTime;
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(frequency, now);
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(0.16, now + 0.01);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + duration);
    osc.connect(gain).connect(audioCtx.destination);
    osc.start(now);
    osc.stop(now + duration + 0.03);
  } catch {
    /* audio is a nice-to-have */
  }
}

async function requestWakeLock() {
  if (!('wakeLock' in navigator) || state.run.wakeLock) return;
  try {
    state.run.wakeLock = await navigator.wakeLock.request('screen');
    state.run.wakeLock.addEventListener('release', () => {
      state.run.wakeLock = null;
    });
  } catch {
    /* unsupported or denied */
  }
}

function releaseWakeLock() {
  const lock = state.run.wakeLock;
  state.run.wakeLock = null;
  lock?.release?.().catch(() => {});
}

function toggleFullscreen() {
  if (document.fullscreenElement) {
    document.exitFullscreen?.().catch(() => {});
  } else {
    document.documentElement.requestFullscreen?.().catch(() => toast('Fullscreen is not available here.', { tone: 'warn' }));
  }
}

/* ------------------------------------------------------------------ */
/* Print sheet                                                         */
/* ------------------------------------------------------------------ */

function renderPrintSheet(practice) {
  const totals = core.practiceTotals(practice);
  const unit = core.unitFor(practice);
  const rows = practice.sets.map((set, index) => {
    const type = typeOf(set.type);
    const sendoff = core.sendoffForSet(set, practice);
    const checks = Array.from({ length: Math.min(set.reps, 20) }, () => '<i class="check-box"></i>').join('');
    return `<tr>
      <td class="num">${index + 1}</td>
      <td><span class="sheet-type">${esc(type.label)}</span></td>
      <td class="set-cell"><strong>${set.reps} × ${set.distance} ${unit} ${esc(set.stroke)}</strong>
        ${set.equipment?.length ? `<span class="sheet-equip">w/ ${esc(set.equipment.join(' + '))}</span>` : ''}
        ${set.notes ? `<span class="sheet-note">${esc(set.notes)}</span>` : ''}
      </td>
      <td class="sendoff">${sendoff ? esc(core.formatClock(sendoff)) : '—'}</td>
      <td class="checks">${checks}</td>
    </tr>`;
  }).join('');

  return `
    <div class="sheet">
      <header class="sheet-head">
        <div>
          <h1>${esc(practice.title)}</h1>
          <p class="sheet-sub">${esc(core.formatDate(practice.date))} · ${esc(core.COURSES[practice.course].label)}${practice.group ? ` · ${esc(practice.group)}` : ''}${practice.focus ? ` · ${esc(practice.focus)}` : ''}</p>
        </div>
        <div class="sheet-total">
          <strong>${core.formatNumber(totals.distance)} ${unit}</strong>
          <span>${totals.setCount} sets · ${core.formatNumber(totals.reps)} reps · ~${core.formatDuration(totals.seconds)}</span>
          <span>Base pace ${core.formatClock(practice.basePace)} / 100 ${unit}</span>
        </div>
      </header>
      <table class="sheet-table">
        <thead>
          <tr><th>#</th><th>Type</th><th>Set</th><th>On</th><th>Completed</th></tr>
        </thead>
        <tbody>${rows || '<tr><td colspan="5">No sets.</td></tr>'}</tbody>
      </table>
      ${practice.notes ? `<div class="sheet-notes"><h2>Notes</h2><p>${esc(practice.notes).replace(/\n/g, '<br />')}</p></div>` : ''}
      <footer class="sheet-foot">
        <span>SwimSet · swimset</span>
        <span>Base pace and send-offs are targets; adjust on deck as needed.</span>
      </footer>
    </div>`;
}

function printPractice() {
  const root = $('#print-root');
  root.innerHTML = renderPrintSheet(state.practice);
  setTimeout(() => window.print(), 60);
}

/* ------------------------------------------------------------------ */
/* Export / import                                                     */
/* ------------------------------------------------------------------ */

function download(filename, text, type = 'application/json') {
  const blob = new Blob([text], { type: `${type};charset=utf-8` });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}

function practiceFilename(practice) {
  return `${core.slugify(practice.title)}-${practice.date || core.todayISO()}`;
}

function exportPracticeJSON() {
  download(`${practiceFilename(state.practice)}.json`, store.buildExportBundle([state.practice]));
  toast('JSON downloaded');
}

function exportPracticeText() {
  download(`${practiceFilename(state.practice)}.txt`, core.practiceToText(state.practice), 'text/plain');
  toast('Text sheet downloaded');
}

async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text);
    toast('Copied to clipboard', { tone: 'success' });
    return;
  } catch {
    /* fall through */
  }
  const area = document.createElement('textarea');
  area.value = text;
  area.setAttribute('readonly', '');
  area.style.position = 'fixed';
  area.style.opacity = '0';
  document.body.append(area);
  area.select();
  try {
    document.execCommand('copy');
    toast('Copied to clipboard', { tone: 'success' });
  } catch {
    toast('Could not copy automatically. Select the text and copy manually.', { tone: 'warn' });
  }
  area.remove();
}

async function sharePractice() {
  const text = core.practiceToText(state.practice);
  if (navigator.share) {
    try {
      await navigator.share({ title: state.practice.title, text });
      return;
    } catch (error) {
      if (error?.name === 'AbortError') return;
    }
  }
  await copyText(text);
}

function openImportPicker() {
  const input = $('#import-file');
  if (input) {
    input.value = '';
    input.click();
  }
}

async function handleImportFile(file) {
  if (!file) return;
  try {
    const text = await file.text();
    const imported = store.importBundle(text);
    toast(`${imported.length} practice${imported.length === 1 ? '' : 's'} imported`, { tone: 'success' });
    updateNavCount();
    if (state.view === 'library') renderLibrary();
  } catch (error) {
    toast(error.message || 'Import failed.', { tone: 'error' });
  }
}

/* ------------------------------------------------------------------ */
/* Templates                                                           */
/* ------------------------------------------------------------------ */

function openTemplatesModal() {
  const cards = TEMPLATES.map((template) => {
    const preview = templateToPractice(template);
    const totals = core.practiceTotals(preview);
    return `
      <article class="template-card">
        <div class="template-top">
          <h3>${esc(template.name)}</h3>
          <span class="course-pill">${esc(template.course)}</span>
        </div>
        <p>${esc(template.description)}</p>
        <div class="mini-stats">
          <span><strong>${core.formatNumber(totals.distance)}</strong> ${totals.unit}</span>
          <span><strong>${core.formatDuration(totals.seconds)}</strong></span>
          <span><strong>${totals.setCount}</strong> sets</span>
          <span><strong>${esc(core.formatClock(template.basePace))}</strong>/100</span>
        </div>
        <div class="template-tags">${(template.tags || []).map((tag) => `<span>${esc(tag)}</span>`).join('')}</div>
        <div class="template-actions">
          <button type="button" class="btn btn-primary btn-sm" data-action="use-template" data-template="${template.id}">Use template</button>
          <button type="button" class="btn btn-sm" data-action="insert-template" data-template="${template.id}">Add sets</button>
        </div>
      </article>`;
  }).join('');

  openModal({
    title: 'Workout templates',
    wide: true,
    body: `<p class="muted modal-text">Start a new practice from a template, or add its sets to the one you are building. All templates are fully editable.</p>
      <div class="template-grid">${cards}</div>`,
  });
}

async function useTemplate(id) {
  const template = TEMPLATES.find((t) => t.id === id);
  if (!template) return;
  closeModal();
  if (!(await maybeDiscard())) return;
  state.practice = templateToPractice(template);
  state.dirty = true;
  state.savedEver = false;
  state.openDetails.clear();
  store.clearDraft();
  scheduleDraft();
  render();
  navigate('builder');
  toast(`“${template.name}” loaded — customise and save`, { tone: 'success' });
}

function insertTemplate(id) {
  const template = TEMPLATES.find((t) => t.id === id);
  if (!template) return;
  const sets = instantiateTemplateSets(template);
  state.practice.sets.push(...sets);
  closeModal();
  touch();
  renderBuilder();
  window.requestAnimationFrame(() => {
    $$('.set-card').at(-sets.length)?.scrollIntoView({ behavior: 'smooth', block: 'center' });
  });
  toast(`${sets.length} sets added from “${template.name}”`);
}

/* ------------------------------------------------------------------ */
/* Help                                                                */
/* ------------------------------------------------------------------ */

function openHelp() {
  openModal({
    title: 'SwimSet help',
    wide: true,
    body: `
      <div class="help-grid">
        <section>
          <h3>Build a practice</h3>
          <p>Set the <strong>course</strong> and a <strong>base pace</strong> per 100. Add sets with reps, distance, stroke and rest — SwimSet calculates the send-off for each rep automatically. Open a set’s slider button for target pace, equipment and notes.</p>
          <h3>Run it poolside</h3>
          <p>The <strong>Poolside</strong> view turns the practice into a rep-by-rep timer with audio cues, auto-advance and an estimated finish. Keep the screen awake while it runs. Press <span class="kbd">Space</span> to start or pause.</p>
          <h3>Print or share</h3>
          <p>Print a clean deck sheet from the <strong>More</strong> menu, download a text sheet, or share via your device’s share sheet. JSON exports are the backup format.</p>
        </section>
        <section>
          <h3>Install on a Chromebook or Android</h3>
          <ol>
            <li>Open the app in Chrome.</li>
            <li>Tap the <strong>Install</strong> button in the header, or Chrome’s menu → <em>Install app</em> / <em>Add to Home screen</em>.</li>
            <li>It opens full-screen and works offline after the first load.</li>
          </ol>
          <h3>Install on Debian</h3>
          <p>Use the packaged <span class="mono">.deb</span> (see the README), or open the app from any local web server in Chrome and install it the same way. The package adds a launcher to your applications menu.</p>
          <h3>Where is my data?</h3>
          <p>Everything lives in this browser’s local storage. Nothing is uploaded. Export your library regularly if you clear site data or switch devices.</p>
          <h3>Keyboard shortcuts</h3>
          <ul class="shortcut-list">
            <li><span class="kbd">Ctrl</span> + <span class="kbd">S</span> save practice</li>
            <li><span class="kbd">Ctrl</span> + <span class="kbd">P</span> print practice sheet</li>
            <li><span class="kbd">Space</span> start / pause poolside timer</li>
            <li><span class="kbd">←</span> <span class="kbd">→</span> previous / next rep</li>
          </ul>
        </section>
      </div>
      <p class="muted small modal-foot">SwimSet works offline. Course conversions are approximate training estimates, not official results. Version 1.0.0.</p>`,
  });
}

/* ------------------------------------------------------------------ */
/* Theme + install                                                     */
/* ------------------------------------------------------------------ */

function effectiveDark() {
  const theme = state.prefs.theme;
  if (theme === 'light') return false;
  if (theme === 'dark') return true;
  return window.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false;
}

function applyTheme() {
  const root = document.documentElement;
  if (state.prefs.theme === 'auto') delete root.dataset.theme;
  else root.dataset.theme = state.prefs.theme;
  updateThemeIcon();
}

function updateThemeIcon() {
  const target = $('.theme-icon');
  if (!target) return;
  target.innerHTML = icon(effectiveDark() ? 'sun' : 'moon');
  const btn = target.closest('button');
  if (btn) btn.title = effectiveDark() ? 'Switch to light theme' : 'Switch to dark theme';
  const meta = $('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', effectiveDark() ? '#041b26' : '#062a3a');
}

function toggleTheme() {
  state.prefs.theme = effectiveDark() ? 'light' : 'dark';
  store.savePrefs({ theme: state.prefs.theme });
  applyTheme();
}

function setupInstall() {
  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault();
    state.installPrompt = event;
    const btn = $('#install-btn');
    if (btn) btn.hidden = false;
  });
  window.addEventListener('appinstalled', () => {
    state.installPrompt = null;
    const btn = $('#install-btn');
    if (btn) btn.hidden = true;
    toast('SwimSet installed — open it from your app drawer', { tone: 'success' });
  });
  if (window.matchMedia?.('(display-mode: standalone)').matches) {
    const btn = $('#install-btn');
    if (btn) btn.hidden = true;
  }
}

async function installApp() {
  if (state.installPrompt?.prompt) {
    state.installPrompt.prompt();
    try {
      const choice = await state.installPrompt.userChoice;
      if (choice?.outcome === 'accepted') {
        state.installPrompt = null;
        const btn = $('#install-btn');
        if (btn) btn.hidden = true;
      }
    } catch {
      /* ignore */
    }
    return;
  }
  openHelp();
}

/* ------------------------------------------------------------------ */
/* Actions                                                             */
/* ------------------------------------------------------------------ */

async function handleAction(action, el, event) {
  switch (action) {
    /* global */
    case 'close-modal':
      if (el.classList.contains('modal-backdrop') && event.target.closest('.modal-panel')) return;
      closeModal();
      return;
    case 'confirm-yes':
      answerConfirm(true);
      return;
    case 'confirm-no':
      answerConfirm(false);
      return;
    case 'toggle-theme':
      toggleTheme();
      return;
    case 'open-help':
      openHelp();
      return;
    case 'install-app':
      await installApp();
      return;

    /* builder */
    case 'save-practice':
      savePractice();
      return;
    case 'new-practice':
      await newPractice();
      return;
    case 'duplicate-practice':
      if (el.dataset.id) {
        const copy = store.duplicatePractice(el.dataset.id);
        if (copy) {
          updateNavCount();
          renderLibrary();
          toast('Practice duplicated');
        }
      } else {
        await duplicateCurrentPractice();
      }
      return;
    case 'open-templates':
      openTemplatesModal();
      return;
    case 'start-run':
      if (!state.practice.sets.length) {
        toast('Add at least one set before starting poolside mode.', { tone: 'warn' });
        return;
      }
      resetRunState();
      navigate('run');
      return;
    case 'print-practice':
      printPractice();
      return;
    case 'export-json':
      exportPracticeJSON();
      return;
    case 'export-text':
      exportPracticeText();
      return;
    case 'copy-text':
      await copyText(core.practiceToText(state.practice));
      return;
    case 'share-practice':
      await sharePractice();
      return;
    case 'add-set': {
      if (state.practice.sets.length >= 80) {
        toast('A practice can hold up to 80 sets.', { tone: 'warn' });
        return;
      }
      const set = core.createSet({ type: state.practice.sets.length === 0 ? 'warmup' : 'main' });
      state.practice.sets.push(set);
      state.openDetails.add(set.id);
      touch();
      renderBuilder();
      window.requestAnimationFrame(() => {
        const card = document.querySelector(`.set-card[data-set-id="${set.id}"]`);
        card?.scrollIntoView({ behavior: 'smooth', block: 'center' });
        card?.querySelector('[data-field="reps"]')?.focus();
      });
      return;
    }
    case 'delete-set': {
      const index = state.practice.sets.findIndex((s) => s.id === el.dataset.id);
      if (index < 0) return;
      const [removed] = state.practice.sets.splice(index, 1);
      state.openDetails.delete(removed.id);
      touch();
      renderBuilder();
      toast('Set removed', {
        actionLabel: 'Undo',
        onAction: () => {
          state.practice.sets.splice(Math.min(index, state.practice.sets.length), 0, removed);
          touch();
          renderBuilder();
        },
      });
      return;
    }
    case 'duplicate-set': {
      if (state.practice.sets.length >= 80) {
        toast('A practice can hold up to 80 sets.', { tone: 'warn' });
        return;
      }
      const index = state.practice.sets.findIndex((s) => s.id === el.dataset.id);
      if (index < 0) return;
      const copy = core.cloneSet(state.practice.sets[index]);
      state.practice.sets.splice(index + 1, 0, copy);
      touch();
      renderBuilder();
      toast('Set duplicated');
      return;
    }
    case 'move-set-up':
    case 'move-set-down': {
      const index = state.practice.sets.findIndex((s) => s.id === el.dataset.id);
      const target = action === 'move-set-up' ? index - 1 : index + 1;
      if (index < 0 || target < 0 || target >= state.practice.sets.length) return;
      const [set] = state.practice.sets.splice(index, 1);
      state.practice.sets.splice(target, 0, set);
      touch();
      renderBuilder();
      window.requestAnimationFrame(() => {
        document.querySelector(`[data-action="${action}"][data-id="${set.id}"]`)?.focus();
      });
      return;
    }
    case 'toggle-details': {
      const id = el.dataset.id;
      if (state.openDetails.has(id)) state.openDetails.delete(id);
      else state.openDetails.add(id);
      renderBuilder();
      window.requestAnimationFrame(() => {
        document.querySelector(`[data-action="toggle-details"][data-id="${id}"]`)?.focus();
      });
      return;
    }
    case 'toggle-equipment': {
      const set = state.practice.sets.find((s) => s.id === el.dataset.id);
      if (!set) return;
      const item = el.dataset.equip;
      if (set.equipment.includes(item)) set.equipment = set.equipment.filter((e) => e !== item);
      else set.equipment = [...set.equipment, item];
      el.classList.toggle('is-on', set.equipment.includes(item));
      el.setAttribute('aria-pressed', String(set.equipment.includes(item)));
      const foot = el.closest('.set-card')?.querySelector('.set-foot');
      if (foot) {
        let equipEl = foot.querySelector('.equip-inline');
        if (set.equipment.length) {
          if (!equipEl) {
            equipEl = document.createElement('span');
            equipEl.className = 'equip-inline';
            foot.insertBefore(equipEl, foot.querySelector('.set-hint'));
          }
          equipEl.textContent = set.equipment.join(' + ');
        } else {
          equipEl?.remove();
        }
      }
      touch();
      return;
    }
    case 'use-template':
      await useTemplate(el.dataset.template);
      return;
    case 'insert-template':
      insertTemplate(el.dataset.template);
      return;

    /* library */
    case 'open-practice':
      if (await maybeDiscard()) openPractice(el.dataset.id);
      return;
    case 'delete-practice': {
      const practice = store.getPractice(el.dataset.id);
      if (!practice) return;
      const confirmed = await confirmDialog({
        title: 'Delete practice?',
        message: `“${practice.title}” will be removed from this device. This cannot be undone.`,
        confirmLabel: 'Delete',
        danger: true,
      });
      if (!confirmed) return;
      store.deletePractice(practice.id);
      if (state.practice.id === practice.id) {
        state.savedEver = false;
        state.dirty = true;
      }
      updateNavCount();
      renderLibrary();
      toast('Practice deleted');
      return;
    }
    case 'export-practice': {
      const practice = store.getPractice(el.dataset.id);
      if (!practice) return;
      download(`${practiceFilename(practice)}.json`, store.buildExportBundle([practice]));
      toast('Practice exported');
      return;
    }
    case 'export-all': {
      const practices = store.loadPractices();
      if (!practices.length) {
        toast('There is nothing to export yet.', { tone: 'warn' });
        return;
      }
      download(`swimset-library-${core.todayISO()}.json`, store.buildExportBundle(practices));
      toast(`${practices.length} practices exported`);
      return;
    }
    case 'import-practices':
      openImportPicker();
      return;
    case 'clear-search':
      state.library.query = '';
      renderLibrary();
      return;

    /* poolside */
    case 'play-pause':
      playPause();
      return;
    case 'run-next':
      if (state.run.finished) return;
      if (state.run.index >= state.run.steps.length - 1) {
        finishRun();
        return;
      }
      advanceRun(1);
      if (!state.run.running) state.run.remainingMs = stepDuration(state.run.steps[state.run.index]) * 1000;
      return;
    case 'run-prev':
      if (state.run.index > 0) jumpToStep(state.run.index - 1);
      return;
    case 'run-reset':
      stopTimer();
      resetRunState();
      renderRun();
      return;
    case 'run-jump':
      jumpToStep(Number(el.dataset.index));
      return;
    case 'toggle-mute':
      state.run.muted = !state.run.muted;
      store.savePrefs({ runMuted: state.run.muted });
      updateRunButtons();
      toast(state.run.muted ? 'Timer sounds off' : 'Timer sounds on');
      return;
    case 'toggle-auto':
      state.run.autoAdvance = !state.run.autoAdvance;
      store.savePrefs({ autoAdvance: state.run.autoAdvance });
      updateRunButtons();
      return;
    case 'toggle-fullscreen':
      toggleFullscreen();
      return;

    default:
      return;
  }
}

/* ------------------------------------------------------------------ */
/* Input handling                                                      */
/* ------------------------------------------------------------------ */

function focusField(setId, field) {
  window.requestAnimationFrame(() => {
    const selector = setId
      ? `[data-set-id="${setId}"][data-field="${field}"]`
      : `[data-field="${field}"]`;
    document.querySelector(selector)?.focus();
  });
}

function handleFieldInput(el, field, live) {
  const p = state.practice;
  const setId = el.dataset.setId;
  const set = setId ? p.sets.find((s) => s.id === setId) : null;

  if (set) {
    switch (field) {
      case 'reps': {
        const value = parseIntOrNull(el.value);
        if (value != null) set.reps = core.clamp(value, 1, 999);
        else if (!live) el.value = String(set.reps);
        break;
      }
      case 'distance': {
        const value = parseIntOrNull(el.value);
        if (value != null) set.distance = core.clamp(value, 1, 10000);
        else if (!live) el.value = String(set.distance);
        break;
      }
      case 'stroke':
        set.stroke = el.value;
        break;
      case 'type':
        set.type = el.value;
        touch();
        renderBuilder();
        focusField(setId, 'type');
        return;
      case 'intervalMode':
        set.intervalMode = el.value;
        if (el.value === 'manual' && !set.interval) {
          set.interval = core.sendoffForSet({ ...set, intervalMode: 'pace' }, p);
        }
        touch();
        renderBuilder();
        focusField(setId, 'intervalMode');
        return;
      case 'interval': {
        const value = core.parseTime(el.value);
        if (value != null && value > 0) {
          set.interval = value;
          set.intervalMode = 'manual';
        } else if (!live) {
          el.value = set.interval ? core.formatClock(set.interval) : '';
          toast('Use a send-off like 1:30 or 90 seconds', { tone: 'warn' });
        }
        break;
      }
      case 'pace100': {
        if (el.value.trim() === '') {
          set.pace100 = null;
        } else {
          const value = core.parseTime(el.value);
          if (value != null && value > 0) set.pace100 = value;
          else if (!live) {
            el.value = set.pace100 ? core.formatClock(set.pace100) : '';
            toast('Target pace should look like 1:30', { tone: 'warn' });
          } else {
            return;
          }
        }
        break;
      }
      case 'rest': {
        const value = parseIntOrNull(el.value);
        if (value != null) set.rest = core.clamp(value, 0, 3600);
        else if (!live) el.value = String(set.rest);
        break;
      }
      case 'notes':
        set.notes = el.value.slice(0, 500);
        touch();
        return;
      default:
        return;
    }
    touch();
    refreshDerived();
    return;
  }

  switch (field) {
    case 'title':
      p.title = el.value.slice(0, 120);
      document.title = `${p.title || 'Untitled practice'} — SwimSet`;
      touch();
      return;
    case 'date':
      if (/^\d{4}-\d{2}-\d{2}$/.test(el.value)) {
        p.date = el.value;
        touch();
      }
      return;
    case 'course':
      p.course = core.COURSE_IDS.includes(el.value) ? el.value : p.course;
      touch();
      renderBuilder();
      focusField(null, 'course');
      return;
    case 'roundTo':
      p.roundTo = core.ROUND_STEPS.includes(Number(el.value)) ? Number(el.value) : 5;
      touch();
      renderBuilder();
      focusField(null, 'roundTo');
      return;
    case 'basePace': {
      const value = core.parseTime(el.value);
      if (value != null && value > 0) {
        p.basePace = value;
        touch();
        refreshDerived();
      } else if (!live) {
        el.value = core.formatClock(p.basePace);
        toast('Base pace should look like 1:40', { tone: 'warn' });
      }
      return;
    }
    case 'group':
      p.group = el.value.slice(0, 80);
      touch();
      return;
    case 'focus':
      p.focus = el.value.slice(0, 120);
      touch();
      return;
    case 'notes':
      p.notes = el.value.slice(0, 2000);
      touch();
      return;
    default:
      return;
  }
}

function onInput(event) {
  const el = event.target;
  if (!(el instanceof HTMLElement)) return;
  if (el.tagName === 'SELECT' || el.type === 'date' || el.type === 'file' || el.type === 'checkbox') return;

  if (el.dataset.pace) {
    handlePaceInput(el, true);
    return;
  }
  if (el.id === 'library-search') {
    state.library.query = el.value;
    const position = el.selectionStart;
    renderLibrary();
    const search = $('#library-search');
    if (search) {
      search.focus();
      search.setSelectionRange(position, position);
    }
    return;
  }
  const field = el.dataset.field;
  if (!field) return;
  handleFieldInput(el, field, true);
}

function onChange(event) {
  const el = event.target;
  if (!(el instanceof HTMLElement)) return;

  if (el.dataset.pace) {
    handlePaceInput(el, false);
    return;
  }
  if (el.id === 'library-sort') {
    state.library.sort = el.value;
    renderLibrary();
    return;
  }
  const field = el.dataset.field;
  if (!field) return;
  if (el.tagName === 'SELECT' || el.type === 'date' || el.type === 'number' || field === 'basePace' || field === 'pace100' || field === 'interval') {
    handleFieldInput(el, field, false);
  }
}

function handlePaceInput(el, live) {
  const key = el.dataset.pace;
  const tool = state.paceTool;

  if (key === 'base') {
    const value = core.parseTime(el.value);
    if (value != null && value > 0) tool.base = value;
    else if (!live) {
      el.value = core.formatClock(tool.base);
      toast('Use a pace like 1:40', { tone: 'warn' });
    }
  } else if (key === 'rest') {
    const value = parseIntOrNull(el.value);
    if (value != null) tool.rest = core.clamp(value, 0, 600);
  } else if (key === 'round') {
    tool.round = Number(el.value) || 5;
  } else if (key === 'time') {
    const value = core.parseTimeFloat(el.value);
    if (value != null && value > 0) tool.time = value;
    else if (!live) {
      el.value = core.formatClockDecimal(tool.time);
      toast('Use a time like 1:52.5', { tone: 'warn' });
    }
  } else if (key === 'from') {
    tool.from = core.COURSE_IDS.includes(el.value) ? el.value : tool.from;
  } else if (key === 'to') {
    tool.to = core.COURSE_IDS.includes(el.value) ? el.value : tool.to;
  } else if (key === 'knownTime') {
    const value = core.parseTimeFloat(el.value);
    if (value != null && value > 0) tool.knownTime = value;
    else if (!live) {
      el.value = core.formatClockDecimal(tool.knownTime);
      toast('Use a time like 5:00', { tone: 'warn' });
    }
  } else if (key === 'knownDistance') {
    const value = parseIntOrNull(el.value);
    if (value != null && value > 0) tool.knownDistance = core.clamp(value, 25, 10000);
  }
  refreshPace();
}

/* ------------------------------------------------------------------ */
/* Routing + render                                                    */
/* ------------------------------------------------------------------ */

const VIEWS = ['builder', 'library', 'pace', 'run'];

function viewFromHash() {
  const match = location.hash.match(/^#\/([a-z]+)/);
  return VIEWS.includes(match?.[1]) ? match[1] : 'builder';
}

function navigate(view) {
  if (location.hash === `#/${view}`) {
    state.view = view;
    render();
  } else {
    location.hash = `#/${view}`;
  }
}

function render() {
  const view = state.view;
  $$('.view').forEach((section) => {
    section.hidden = section.dataset.view !== view;
  });
  $$('.nav-link').forEach((link) => {
    const active = link.dataset.nav === view;
    link.classList.toggle('active', active);
    if (active) link.setAttribute('aria-current', 'page');
    else link.removeAttribute('aria-current');
  });

  if (view === 'builder') renderBuilder();
  else if (view === 'library') renderLibrary();
  else if (view === 'pace') renderPace();
  else if (view === 'run') renderRun();

  updateNavCount();
  updateThemeIcon();
}

function onRouteChange() {
  const next = viewFromHash();
  const changed = next !== state.view;
  if (state.view === 'run' && next !== 'run') {
    pauseRun();
    if (document.fullscreenElement) document.exitFullscreen?.().catch(() => {});
  }
  state.view = next;
  render();
  if (changed) window.scrollTo({ top: 0, behavior: 'auto' });
}

/* ------------------------------------------------------------------ */
/* Events                                                              */
/* ------------------------------------------------------------------ */

function onClick(event) {
  $$('details.menu[open]').forEach((details) => {
    if (!details.contains(event.target)) details.removeAttribute('open');
  });

  const actionEl = event.target.closest('[data-action]');
  if (!actionEl) return;
  const action = actionEl.dataset.action;
  if (action === 'close-modal' && actionEl.classList.contains('modal-backdrop') && event.target.closest('.modal-panel')) return;
  if (actionEl.tagName === 'SUMMARY') return;

  handleAction(action, actionEl, event).catch((error) => {
    console.error(error);
    toast('Something went wrong with that action.', { tone: 'error' });
  });
}

function isTypingTarget(target) {
  if (!(target instanceof HTMLElement)) return false;
  return ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName) || target.isContentEditable;
}

function onKeyDown(event) {
  if (event.key === 'Escape' && $('#modal-root').children.length) {
    closeModal();
    return;
  }

  const mod = event.ctrlKey || event.metaKey;
  if (mod && event.key.toLowerCase() === 's') {
    event.preventDefault();
    savePractice();
    return;
  }
  if (mod && event.key.toLowerCase() === 'p') {
    event.preventDefault();
    printPractice();
    return;
  }

  if ($('#modal-root').children.length) {
    if (event.key === 'Tab') trapModalFocus(event);
    return;
  }
  if (isTypingTarget(event.target)) return;

  if (state.view === 'run') {
    if (event.code === 'Space') {
      event.preventDefault();
      playPause();
      return;
    }
    if (event.key === 'ArrowRight') {
      event.preventDefault();
      if (state.run.index < state.run.steps.length - 1) advanceRun(1);
      else if (!state.run.finished) finishRun();
      return;
    }
    if (event.key === 'ArrowLeft') {
      event.preventDefault();
      if (state.run.index > 0) jumpToStep(state.run.index - 1);
      return;
    }
    if (event.key.toLowerCase() === 'f') {
      event.preventDefault();
      toggleFullscreen();
      return;
    }
  }

  if (event.key === '?' || (event.key === '/' && event.shiftKey)) {
    event.preventDefault();
    openHelp();
  }
}

function trapModalFocus(event) {
  const panel = $('.modal-panel');
  if (!panel) return;
  const focusable = $$('button, [href], input, select, textarea, summary, [tabindex]:not([tabindex="-1"])', panel)
    .filter((el) => !el.disabled && el.offsetParent !== null);
  if (!focusable.length) return;
  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
}

/* ------------------------------------------------------------------ */
/* Init                                                                */
/* ------------------------------------------------------------------ */

function init() {
  initPractice();
  setupInstall();
  applyTheme();

  const themeQuery = window.matchMedia?.('(prefers-color-scheme: dark)');
  themeQuery?.addEventListener?.('change', () => {
    if (state.prefs.theme === 'auto') updateThemeIcon();
  });

  state.paceTool.base = state.practice.basePace;
  state.paceTool.round = state.practice.roundTo;
  state.paceTool.from = state.practice.course;
  state.paceTool.to = state.practice.course === 'SCY' ? 'LCM' : 'SCY';
  state.paceTool.time = Math.round(state.practice.basePace * 2 * 10) / 10;
  state.paceTool.knownTime = Math.round(state.practice.basePace * 5 * 10) / 10;
  state.paceTool.knownDistance = 500;

  document.addEventListener('click', onClick);
  document.addEventListener('input', onInput);
  document.addEventListener('change', onChange);
  document.addEventListener('keydown', onKeyDown);
  window.addEventListener('hashchange', onRouteChange);

  document.addEventListener('visibilitychange', () => {
    if (document.hidden && state.run.running) pauseRun();
  });

  const importInput = document.createElement('input');
  importInput.type = 'file';
  importInput.accept = '.json,application/json';
  importInput.id = 'import-file';
  importInput.hidden = true;
  importInput.addEventListener('change', () => handleImportFile(importInput.files?.[0]));
  document.body.append(importInput);

  if (!state.storageOk) {
    setTimeout(() => toast('Local storage is blocked — saving is disabled.', { tone: 'warn', timeout: 6000 }), 800);
  }

  if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('./sw.js').catch(() => {
        /* offline cache is optional */
      });
    });
  }

  state.view = viewFromHash();
  render();
  document.title = `${state.practice.title || 'Untitled practice'} — SwimSet`;
}

init();
