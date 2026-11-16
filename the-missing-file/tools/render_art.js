// Renders art_src/*.svg to the PNG files used by the game.
// Usage: node tools/render_art.js   (needs Playwright + Chromium)
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..');
const targets = {
  lobby: 'assets/scenes/lobby.png', erdem: 'assets/portraits/erdem.png',
  menu_bg: 'assets/ui/menu_bg.png', icon: 'assets/ui/icon.png',
  e01: 'assets/evidence/e01.png', e02: 'assets/evidence/e02.png', e03: 'assets/evidence/e03.png',
  e04: 'assets/evidence/e04.png', e05: 'assets/evidence/e05.png', e06: 'assets/evidence/e06.png',
  e15: 'assets/evidence/e15.png',
  office: 'assets/scenes/office.png', stacks: 'assets/scenes/stacks.png', director: 'assets/scenes/director.png',
  e07: 'assets/evidence/e07.png', e08: 'assets/evidence/e08.png', e09: 'assets/evidence/e09.png', e10: 'assets/evidence/e10.png',
  e11: 'assets/evidence/e11.png', e12: 'assets/evidence/e12.png', e13: 'assets/evidence/e13.png', e14: 'assets/evidence/e14.png',
  e16: 'assets/evidence/e16.png', e17: 'assets/evidence/e17.png', e18: 'assets/evidence/e18.png', e19: 'assets/evidence/e19.png',
  erdem_defensive: 'assets/portraits/erdem_defensive.png', erdem_shaken: 'assets/portraits/erdem_shaken.png', vardar_defensive: 'assets/portraits/vardar_defensive.png', vardar_shaken: 'assets/portraits/vardar_shaken.png', aras_defensive: 'assets/portraits/aras_defensive.png', aras_shaken: 'assets/portraits/aras_shaken.png', aydin_defensive: 'assets/portraits/aydin_defensive.png', aydin_shaken: 'assets/portraits/aydin_shaken.png',
  vardar: 'assets/portraits/vardar.png', aras: 'assets/portraits/aras.png', aydin: 'assets/portraits/aydin.png',
  card_testimony: 'assets/ui/card_testimony.png', card_insight: 'assets/ui/card_insight.png',
};
// Extra targets written by the per-case art generators (art_src/targets_*.json).
for (const f of fs.readdirSync(path.join(root, 'art_src'))) {
  if (/^targets_.*\.json$/.test(f)) Object.assign(targets, JSON.parse(fs.readFileSync(path.join(root, 'art_src', f), 'utf8')));
}
const only = process.argv[2];   // optional: render only names starting with this prefix
(async () => {
  const browser = await chromium.launch();
  for (const [name, out] of Object.entries(targets)) {
    if (only && !only.split(',').some(p => name.startsWith(p))) continue;
    const svg = fs.readFileSync(path.join(root, 'art_src', name + '.svg'), 'utf8');
    const m = svg.match(/width="(\d+)" height="(\d+)"/);
    const page = await browser.newPage({ viewport: { width: +m[1], height: +m[2] }, deviceScaleFactor: 1 });
    await page.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
    await page.screenshot({ path: path.join(root, out), omitBackground: true });
    await page.close();
    console.log('rendered', out);
  }
  await browser.close();
})();
