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
  vardar: 'assets/portraits/vardar.png', aras: 'assets/portraits/aras.png', aydin: 'assets/portraits/aydin.png',
  card_testimony: 'assets/ui/card_testimony.png', card_insight: 'assets/ui/card_insight.png',
};
(async () => {
  const browser = await chromium.launch();
  for (const [name, out] of Object.entries(targets)) {
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
