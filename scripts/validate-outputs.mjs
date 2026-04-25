#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const packDir = path.join(root, 'prompt-packs');
const htmlDir = path.join(root, 'single-html');
const requiredDocuments = ['trend_report', 'application_report', 'rebuild_prompt'];
const requiredHtmlText = ['Why this repo is trending', 'Where it can be applied', 'Rebuild prompt'];
const snapshotArgIndex = process.argv.indexOf('--snapshot');
const snapshotPath = snapshotArgIndex >= 0 ? process.argv[snapshotArgIndex + 1] : '';
let expectedCaptureTimestamp = '';

function fail(message) {
  console.error(`Output validation failed: ${message}`);
  process.exit(1);
}

function listFiles(dir, ext) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir)
    .filter((name) => name.endsWith(ext))
    .sort();
}

const packFiles = listFiles(packDir, '.json');
const htmlFiles = listFiles(htmlDir, '.html');

if (snapshotArgIndex >= 0 && !snapshotPath) fail('--snapshot requires a file path');
if (snapshotPath) {
  let snapshot;
  try {
    snapshot = JSON.parse(fs.readFileSync(path.resolve(root, snapshotPath), 'utf8'));
  } catch (err) {
    fail(`${snapshotPath} is not valid JSON: ${err.message}`);
  }
  expectedCaptureTimestamp = snapshot.captured_at || '';
  if (!expectedCaptureTimestamp) fail(`${snapshotPath} missing captured_at`);
}

if (packFiles.length === 0) fail('no prompt-packs/*.json files found');
if (htmlFiles.length === 0) fail('no single-html/*.html files found');

let checked = 0;

for (const packFile of packFiles) {
  const base = packFile.replace(/\.json$/, '');
  const htmlFile = `${base}.html`;
  if (!htmlFiles.includes(htmlFile)) fail(`missing single-html/${htmlFile} for prompt-packs/${packFile}`);

  const packPath = path.join(packDir, packFile);
  let pack;
  try {
    pack = JSON.parse(fs.readFileSync(packPath, 'utf8'));
  } catch (err) {
    fail(`${packFile} is not valid JSON: ${err.message}`);
  }

  if (pack.generator !== 'zodiac') fail(`${packFile} missing generator=zodiac`);
  if (expectedCaptureTimestamp && pack.capture_timestamp !== expectedCaptureTimestamp) continue;
  if (!pack.source_repository?.repo) fail(`${packFile} missing source_repository.repo`);
  if (!pack.source_repository?.commit_sha) fail(`${packFile} missing source_repository.commit_sha`);
  if (!pack.source_repository?.license_key) fail(`${packFile} missing source_repository.license_key`);
  if (!Array.isArray(pack.source_notes) || pack.source_notes.length === 0) fail(`${packFile} has no source_notes`);
  for (const name of requiredDocuments) {
    const document = pack.documents?.[name];
    const body = typeof document === 'string' ? document : document?.body;
    if (typeof body !== 'string' || body.trim().length === 0) {
      fail(`${packFile} missing documents.${name}`);
    }
  }
  if (pack.verification?.status !== 'static-only') fail(`${packFile} verification.status must be static-only`);

  const html = fs.readFileSync(path.join(htmlDir, htmlFile), 'utf8');
  if (!/<!doctype html>/i.test(html)) fail(`${htmlFile} missing doctype`);
  for (const text of requiredHtmlText) {
    if (!html.includes(text)) fail(`${htmlFile} missing visible section: ${text}`);
  }
  if (!html.includes('zodiac')) fail(`${htmlFile} missing generator name zodiac`);
  if (!html.includes(pack.source_repository.repo)) fail(`${htmlFile} missing repository name`);
  if (!html.includes(pack.source_repository.commit_sha)) fail(`${htmlFile} missing commit SHA`);
  checked += 1;
}

if (checked === 0) {
  const scope = expectedCaptureTimestamp ? ` for snapshot ${expectedCaptureTimestamp}` : '';
  fail(`no valid prompt packs${scope}`);
}

console.log(`Validated ${checked} prompt pack(s) and ${htmlFiles.length} HTML page(s).`);
