/*
 * SwimSet — local persistence.
 * Everything stays in the browser: no accounts, no network, no tracking.
 * localStorage is used (small, synchronous, works in every target browser).
 */
import { normalizePractice, uid } from './core.js';

const KEY_PRACTICES = 'swimset.v1.practices';
const KEY_DRAFT = 'swimset.v1.draft';
const KEY_PREFS = 'swimset.v1.prefs';

const DEFAULT_PREFS = {
  theme: 'auto',
  runMuted: false,
  autoAdvance: true,
  seenInstallHint: false,
};

function storage() {
  try {
    const s = window.localStorage;
    const probe = '__swimset_probe__';
    s.setItem(probe, '1');
    s.removeItem(probe);
    return s;
  } catch {
    return null;
  }
}

export function storageAvailable() {
  return storage() !== null;
}

function readJSON(key, fallback) {
  const s = storage();
  if (!s) return fallback;
  try {
    const raw = s.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw);
  } catch {
    return fallback;
  }
}

function writeJSON(key, value) {
  const s = storage();
  if (!s) return false;
  try {
    s.setItem(key, JSON.stringify(value));
    return true;
  } catch {
    return false;
  }
}

/* ------------------------------------------------------------------ */
/* Practices                                                           */
/* ------------------------------------------------------------------ */

export function loadPractices() {
  const raw = readJSON(KEY_PRACTICES, []);
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((item) => item && typeof item === 'object')
    .map(normalizePractice)
    .sort((a, b) => String(b.updatedAt).localeCompare(String(a.updatedAt)));
}

export function getPractice(id) {
  return loadPractices().find((p) => p.id === id) || null;
}

/** Insert or update a practice. Returns the saved practice. */
export function savePractice(practice) {
  const practices = loadPractices();
  const saved = normalizePractice({
    ...practice,
    updatedAt: new Date().toISOString(),
    createdAt: practice.createdAt || new Date().toISOString(),
  });
  const index = practices.findIndex((p) => p.id === saved.id);
  if (index >= 0) practices[index] = saved;
  else practices.unshift(saved);
  const ok = writeJSON(KEY_PRACTICES, practices);
  if (!ok) throw new Error('Could not save to local storage (storage full or blocked).');
  return saved;
}

export function deletePractice(id) {
  const practices = loadPractices().filter((p) => p.id !== id);
  writeJSON(KEY_PRACTICES, practices);
  return practices;
}

export function duplicatePractice(id) {
  const original = getPractice(id);
  if (!original) return null;
  const copy = normalizePractice(JSON.parse(JSON.stringify(original)));
  copy.id = uid('p');
  copy.title = `${original.title} (copy)`;
  copy.createdAt = new Date().toISOString();
  copy.updatedAt = new Date().toISOString();
  return savePractice(copy);
}

/* ------------------------------------------------------------------ */
/* Working draft (crash protection)                                    */
/* ------------------------------------------------------------------ */

export function saveDraft(practice) {
  return writeJSON(KEY_DRAFT, { savedAt: new Date().toISOString(), practice });
}

export function loadDraft() {
  const raw = readJSON(KEY_DRAFT, null);
  if (!raw || typeof raw !== 'object' || !raw.practice) return null;
  try {
    return { savedAt: raw.savedAt, practice: normalizePractice(raw.practice) };
  } catch {
    return null;
  }
}

export function clearDraft() {
  const s = storage();
  if (s) s.removeItem(KEY_DRAFT);
}

/* ------------------------------------------------------------------ */
/* Preferences                                                         */
/* ------------------------------------------------------------------ */

export function loadPrefs() {
  const raw = readJSON(KEY_PREFS, {});
  return { ...DEFAULT_PREFS, ...(raw && typeof raw === 'object' ? raw : {}) };
}

export function savePrefs(patch) {
  const prefs = { ...loadPrefs(), ...patch };
  writeJSON(KEY_PREFS, prefs);
  return prefs;
}

/* ------------------------------------------------------------------ */
/* Import / export                                                     */
/* ------------------------------------------------------------------ */

export function buildExportBundle(practices) {
  return JSON.stringify(
    {
      app: 'SwimSet',
      format: 'swimset-practices',
      version: 1,
      exportedAt: new Date().toISOString(),
      practices,
    },
    null,
    2
  );
}

/**
 * Accepts a SwimSet bundle, a bare array of practices, or a single practice.
 * Imported practices get a fresh id when they collide with existing ones.
 */
export function importBundle(text) {
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error('That file is not valid JSON.');
  }

  let incoming;
  if (Array.isArray(data)) incoming = data;
  else if (data && Array.isArray(data.practices)) incoming = data.practices;
  else if (data && typeof data === 'object' && Array.isArray(data.sets)) incoming = [data];
  else throw new Error('No SwimSet practices found in that file.');

  const existing = loadPractices();
  const existingIds = new Set(existing.map((p) => p.id));
  const imported = [];
  for (const item of incoming) {
    if (!item || typeof item !== 'object') continue;
    const practice = normalizePractice(item);
    if (existingIds.has(practice.id)) practice.id = uid('p');
    existingIds.add(practice.id);
    imported.push(practice);
  }
  if (!imported.length) throw new Error('No valid practices found in that file.');
  writeJSON(KEY_PRACTICES, [...imported, ...existing]);
  return imported;
}

export function storageUsageBytes() {
  const s = storage();
  if (!s) return 0;
  let bytes = 0;
  for (const key of [KEY_PRACTICES, KEY_DRAFT, KEY_PREFS]) {
    const value = s.getItem(key);
    if (value) bytes += key.length + value.length;
  }
  return bytes * 2; // UTF-16 code units
}
