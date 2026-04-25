#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const root = process.cwd();
const baseUrl = process.env.ZODIAC_TEACH_SERVER_BASE_URL || 'https://tmuh.ai';
const apiKey = process.env.ZODIAC_TEACH_SERVER_API_KEY || '';
const dir = path.join(root, 'single-html');

if (!apiKey) {
  console.error('ZODIAC_TEACH_SERVER_API_KEY is required to publish pages.');
  process.exit(1);
}

if (!fs.existsSync(dir)) {
  console.log('single-html directory does not exist; nothing to publish.');
  process.exit(0);
}

const files = fs.readdirSync(dir).filter((name) => name.endsWith('.html')).sort();

function slugForFile(file) {
  const sourceKey = file.replace(/\.html$/, '');
  const normalized = sourceKey.toLowerCase().replace(/[^a-z0-9-]+/g, '-').replace(/^-+|-+$/g, '');
  if (normalized.length <= 40) return normalized;

  const hash = crypto.createHash('sha1').update(sourceKey).digest('hex').slice(0, 8);
  const prefix = normalized.slice(0, 31).replace(/-+$/g, '');
  return `${prefix}-${hash}`;
}

for (const file of files) {
  const slug = slugForFile(file);
  if (!slug || slug.length < 3) {
    console.warn(`Skipping ${file}: cannot derive valid slug`);
    continue;
  }
  const html = fs.readFileSync(path.join(dir, file), 'utf8');
  const title = `GitHub Trend: ${file.replace(/\.html$/, '').replace(/--/g, '/')}`;
  const res = await fetch(new URL('/api/pages', baseUrl), {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ slug, title, html, has_ai: false }),
  });
  const body = await res.text();
  if (!res.ok) {
    console.error(`Failed to publish ${file}: ${res.status} ${body}`);
    process.exitCode = 1;
    continue;
  }
  console.log(`Published or updated ${file}: ${body}`);
}
