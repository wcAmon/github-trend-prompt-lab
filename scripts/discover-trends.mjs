#!/usr/bin/env node

const API = 'https://api.github.com/search/repositories';

const licenses = [
  'mit',
  'apache-2.0',
  'bsd-2-clause',
  'bsd-3-clause',
  'mpl-2.0',
];

const sinceDays = Number(process.env.SINCE_DAYS || 14);
const minStars = Number(process.env.MIN_STARS || 100);
const maxSizeKb = Number(process.env.MAX_SIZE_KB || 5000);
const perPage = Number(process.env.PER_PAGE || 20);
const token = process.env.GITHUB_TOKEN || '';

function isoDateDaysAgo(days) {
  const d = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
  return d.toISOString().slice(0, 10);
}

async function githubGet(url) {
  const headers = {
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'github-trend-prompt-lab',
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(url, { headers });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${res.status} ${res.statusText}: ${text}`);
  }
  return res.json();
}

function candidateFromRepo(repo, license) {
  return {
    repo: repo.full_name,
    url: repo.html_url,
    description: repo.description,
    language: repo.language,
    stars: repo.stargazers_count,
    forks: repo.forks_count,
    open_issues: repo.open_issues_count,
    size_kb: repo.size,
    license_key: repo.license?.key || license,
    default_branch: repo.default_branch,
    pushed_at: repo.pushed_at,
    created_at: repo.created_at,
    captured_at: new Date().toISOString(),
  };
}

async function discover() {
  const pushedSince = isoDateDaysAgo(sinceDays);
  const all = [];

  for (const license of licenses) {
    const q = [
      'is:public',
      'fork:false',
      'archived:false',
      'mirror:false',
      'template:false',
      `pushed:>=${pushedSince}`,
      `stars:>=${minStars}`,
      `size:<${maxSizeKb}`,
      `license:${license}`,
    ].join(' ');
    const url = new URL(API);
    url.searchParams.set('q', q);
    url.searchParams.set('sort', 'stars');
    url.searchParams.set('order', 'desc');
    url.searchParams.set('per_page', String(perPage));

    const data = await githubGet(url);
    all.push(...data.items.map((repo) => candidateFromRepo(repo, license)));
  }

  const unique = new Map();
  for (const item of all) unique.set(item.repo, item);

  console.log(JSON.stringify({
    captured_at: new Date().toISOString(),
    query: {
      since_days: sinceDays,
      min_stars: minStars,
      max_size_kb: maxSizeKb,
      licenses,
      note: 'This is candidate discovery. Store daily snapshots to compute real trend deltas.',
    },
    candidates: [...unique.values()].sort((a, b) => b.stars - a.stars),
  }, null, 2));
}

discover().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
