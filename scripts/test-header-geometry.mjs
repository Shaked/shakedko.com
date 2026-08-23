#!/usr/bin/env node

import { readFileSync } from 'node:fs';
import { spawn } from 'node:child_process';

const [siteDir = '_site'] = process.argv.slice(2);
const chrome = process.env.CHROME_BIN || 'google-chrome';
const css = readFileSync(`${siteDir}/assets/css/style.css`, 'utf8');

function fail(message) {
  throw new Error(message);
}

function headerDocument(page, language, styles = css) {
  const html = readFileSync(`${siteDir}/${page}`, 'utf8');
  const header = html.match(/<header class="site-header"[\s\S]*?<\/header>/)?.[0];
  if (!header) fail(`${page}: generated header is missing`);
  return `data:text/html;base64,${Buffer.from(`<!doctype html><html dir="${language}"><head><meta charset="utf-8"><style>${styles}</style></head><body>${header}</body></html>`).toString('base64')}`;
}

function startBrowser() {
  const child = spawn(chrome, ['--headless=new', '--disable-gpu', '--remote-debugging-pipe', 'about:blank'], {
    stdio: ['ignore', 'ignore', 'pipe', 'pipe', 'pipe'],
  });
  const reader = child.stdio[4];
  const writer = child.stdio[3];
  let buffer = Buffer.alloc(0);
  let nextId = 1;
  const pending = new Map();

  reader.on('data', (chunk) => {
    buffer = Buffer.concat([buffer, chunk]);
    let delimiter;
    while ((delimiter = buffer.indexOf(0)) !== -1) {
      const message = JSON.parse(buffer.subarray(0, delimiter).toString());
      buffer = buffer.subarray(delimiter + 1);
      const request = pending.get(message.id);
      if (request) {
        pending.delete(message.id);
        message.error ? request.reject(new Error(message.error.message)) : request.resolve(message.result);
      }
    }
  });

  const call = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
    const id = nextId++;
    pending.set(id, { resolve, reject });
    writer.write(`${JSON.stringify({ id, method, params, sessionId })}\0`);
  });

  return { child, call };
}

const probe = `(() => {
  const rect = (selector) => document.querySelector(selector).getBoundingClientRect().toJSON();
  const intersects = (a, b) => a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
  const nav = rect('.site-nav');
  const header = rect('.site-header');
  const title = rect('.site-title');
  const quote = rect('.header-quote');
  const trigger = rect('.trigger');
  return JSON.stringify({
    width: innerWidth,
    scrollWidth: document.documentElement.scrollWidth,
    documentHeight: document.documentElement.scrollHeight,
    direction: document.documentElement.dir,
    checked: document.querySelector('.nav-trigger').checked,
    links: document.querySelectorAll('.trigger a').length,
    overflowing: [...document.querySelectorAll('*')].map((element) => ({ name: element.className || element.tagName, right: element.getBoundingClientRect().right })).filter((item) => item.right > innerWidth),
    headerZ: getComputedStyle(document.querySelector('.site-header')).zIndex,
    navZ: getComputedStyle(document.querySelector('.site-nav')).zIndex,
    rowHeights: [...document.querySelectorAll('.trigger > .page-link')].map((link) => link.getBoundingClientRect().height),
    socialRowHeight: document.querySelector('.mobile-social-links').getBoundingClientRect().height,
    header, nav, title, quote, trigger, panel: trigger,
    titleOverlap: intersects(trigger, title),
    quoteOverlap: intersects(trigger, quote),
  });
})()`;

async function measure(browser, url, width, expanded) {
  const target = await browser.call('Target.createTarget', { url });
  const attachment = await browser.call('Target.attachToTarget', { targetId: target.targetId, flatten: true });
  const sessionId = attachment.sessionId;
  await browser.call('Emulation.setDeviceMetricsOverride', { width, height: 900, deviceScaleFactor: 1, mobile: false }, sessionId);
  if (expanded) {
    await browser.call('Runtime.evaluate', { expression: "document.querySelector('.nav-toggle').click()" }, sessionId);
  }
  const result = await browser.call('Runtime.evaluate', { expression: probe, returnByValue: true }, sessionId);
  await browser.call('Target.closeTarget', { targetId: target.targetId });
  return JSON.parse(result.result.value);
}

function assertGeometry(measurement, width, language, expanded) {
  const state = `${language} ${width}px ${expanded ? 'expanded' : 'collapsed'}`;
  if (measurement.width !== width || measurement.scrollWidth > width) fail(`${state}: viewport overflow (${measurement.scrollWidth}px; panel ${measurement.panel.left}-${measurement.panel.right}; ${JSON.stringify(measurement.overflowing)})`);
  if (measurement.direction !== language) fail(`${state}: wrong document direction`);
  if (measurement.checked !== expanded) fail(`${state}: wrong menu state`);
  if (measurement.links !== 5) fail(`${state}: expected five links`);
  if (measurement.nav.left < 0 || measurement.nav.right > width) fail(`${state}: navigation exceeds viewport`);
  if (measurement.titleOverlap) fail(`${state}: panel intersects title row`);
  if (measurement.headerZ !== '1' || measurement.navZ !== '3') fail(`${state}: stacking contract changed`);
  if (expanded) {
    if (measurement.trigger.top < measurement.title.bottom) fail(`${state}: expanded links are not below the title row`);
    if (measurement.panel.width > 242 || measurement.panel.height > 235) fail(`${state}: panel is not compact`);
    if (measurement.socialRowHeight !== 44 || measurement.rowHeights.some((height) => height !== 44)) fail(`${state}: rows lost their shared touch rhythm`);
  }
}

const browser = startBrowser();
try {
  for (const [page, language] of [['index.html', 'ltr'], ['he/index.html', 'rtl']]) {
    for (const width of [393, 500]) {
      const collapsed = await measure(browser, headerDocument(page, language), width, false);
      const expanded = await measure(browser, headerDocument(page, language), width, true);
      assertGeometry(collapsed, width, language, false);
      assertGeometry(expanded, width, language, true);
      if (Math.abs(collapsed.header.top - expanded.header.top) > 0.5 || Math.abs(collapsed.quote.top - expanded.quote.top) > 0.5 || Math.abs(collapsed.documentHeight - expanded.documentHeight) > 0.5) fail(`${language} ${width}px: opening menu caused document reflow`);
      if (!expanded.quoteOverlap) fail(`${language} ${width}px: overlay must cover content while open`);
    }
  }
  const brokenCss = `${css}\n@media screen and (max-width: 600px) { .header-top:has(.nav-trigger:checked) { padding-block-end: 240px; } }`;
  if (brokenCss === css) fail('geometry mutation did not change the compiled CSS');
  let mutationRejected = false;
  for (const [page, language] of [['index.html', 'ltr'], ['he/index.html', 'rtl']]) {
    const mutated = await measure(browser, headerDocument(page, language, brokenCss), 393, true);
    if (mutated.quoteOverlap) fail(`${language} mutation did not recreate push-down behavior`);
    mutationRejected = true;
    try {
      assertGeometry(mutated, 393, language, true);
    } catch {
      mutationRejected = true;
      break;
    }
  }
  if (!mutationRejected) fail('geometry mutation did not recreate the header overlap');
  process.stdout.write('header geometry checks passed\n');
} finally {
  browser.child.kill();
}
