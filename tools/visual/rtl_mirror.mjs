// Mirror check (ADR 0017): a text-free preview rendered with dir=rtl must equal the LTR render flipped horizontally.
// Usage: node rtl_mirror.mjs --base http://localhost:3099 [--theme classic]
import { chromium } from "playwright"
import fs from "fs"
import { PNG } from "pngjs"
import pixelmatch from "pixelmatch"

const args = Object.fromEntries(process.argv.slice(2).reduce((a, v, i, all) => (v.startsWith("--") ? [...a, [v.slice(2), all[i + 1]]] : a), []))
const base = args.base ?? "http://localhost:3099"
const display = encodeURIComponent(JSON.stringify({ theme: args.theme ?? "classic" }))
const TARGETS = [ { preview: "rtl/shapes", selector: "#mirror" } ]
const MAX_DIFF = 150 // pixels: anti-aliasing of curves placed at a fractional position (about 76 today); a real mirror bug differs by thousands

const browser = await chromium.launch({ channel: process.env.VISUAL_CHANNEL ?? "chrome" })
let failed = false
for (const width of [ 375, 768, 1280 ]) {
  const page = await (await browser.newContext({ viewport: { width, height: 900 }, reducedMotion: "reduce" })).newPage()
  for (const { preview, selector } of TARGETS) {
    const shot = async (dir) => {
      await page.goto(`${base}/rails/view_components/${preview}?dir=${dir}&_display=${display}`, { waitUntil: "networkidle" })
      return PNG.sync.read(await page.locator(selector).screenshot())
    }
    const ltr = await shot("ltr"), rtl = await shot("rtl")
    const flipped = new PNG({ width: ltr.width, height: ltr.height })
    for (let y = 0; y < ltr.height; y++) for (let x = 0; x < ltr.width; x++) {
      const from = (y * ltr.width + (ltr.width - 1 - x)) * 4, to = (y * ltr.width + x) * 4
      for (let c = 0; c < 4; c++) flipped.data[to + c] = ltr.data[from + c]
    }
    const same = rtl.width === ltr.width && rtl.height === ltr.height
    const out = new PNG({ width: ltr.width, height: ltr.height })
    const diff = same ? pixelmatch(flipped.data, rtl.data, out.data, ltr.width, ltr.height, { threshold: 0.1 }) : Infinity
    const ok = diff <= MAX_DIFF
    if (!ok && same) { // keep the evidence: the diff image (red = pixels that differ)
      fs.mkdirSync("../../tmp", { recursive: true })
      const file = `../../tmp/rtl_mirror_${preview.replace("/", "-")}_${width}.png`
      fs.writeFileSync(file, PNG.sync.write(out))
      console.log(`     diff image: ${file.replace("../../", "")}`)
    }
    console.log(`${ok ? "ok  " : "FAIL"} ${preview} at ${width}px: ${diff} pixels differ from the flipped LTR render (max ${MAX_DIFF})`)
    failed ||= !ok
  }
}
await browser.close()
process.exit(failed ? 1 : 0)
