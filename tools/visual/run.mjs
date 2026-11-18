// Visual regression: previews x themes x widths -> screenshots, compared with spec/visual/__baseline__.
// Usage (via bin/visual):  node run.mjs --base http://localhost:3099 [--update] [--only token_gallery] [--themes classic,azure] [--widths 375,1280] [--dir rtl]
import { chromium } from "playwright"
import { PNG } from "pngjs"
import pixelmatch from "pixelmatch"
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, "../..")
const dirs = Object.fromEntries(["__baseline__", "__current__", "__diff__"].map((d) => [d, path.join(root, "spec/visual", d)]))
const args = Object.fromEntries(process.argv.slice(2).reduce((acc, a, i, all) => (a.startsWith("--") ? [...acc, [a.slice(2), all[i + 1]?.startsWith("--") || all[i + 1] === undefined ? true : all[i + 1]]] : acc), []))

const base = args.base ?? "http://localhost:3099"
const update = args.update === true
const themes = args.themes ? args.themes.split(",") : JSON.parse(fs.readFileSync(path.join(here, "themes.json"), "utf8")) // themes.json: written by bin/visual from Deckplate::Configuration::BUILT_IN_THEMES
const widths = (args.widths ?? "375,768,1280").split(",").map(Number)
const rtl = args.dir === "rtl" // right-to-left run (ADR 0017): ?dir=rtl, files get an __rtl suffix; use --themes classic --widths 768 for the baseline set
const previews = JSON.parse(fs.readFileSync(args.previews ?? path.join(here, "previews.json"), "utf8")).filter((p) => !args.only || p.includes(args.only))
const THRESHOLD = 0.1          // pixelmatch colour tolerance (anti-aliasing noise)
const MAX_DIFF_RATIO = 0.0005  // fraction of pixels allowed to differ

for (const d of Object.values(dirs)) fs.mkdirSync(d, { recursive: true })
for (const d of ["__current__", "__diff__"]) for (const f of fs.readdirSync(dirs[d])) if (f.endsWith(".png")) fs.rmSync(path.join(dirs[d], f))

const browser = await chromium.launch({ channel: process.env.VISUAL_CHANNEL ?? "chrome" })
const results = { same: 0, changed: [], added: [], errors: [] }

for (const width of widths) {
  const ctx = await browser.newContext({ viewport: { width, height: 800 }, deviceScaleFactor: 1, reducedMotion: "reduce", colorScheme: "dark" })
  const page = await ctx.newPage()
  for (const preview of previews) {
    for (const theme of themes) {
      const name = `${preview.replace("/", "--")}__${theme}__${width}${rtl ? "__rtl" : ""}.png`
      const display = encodeURIComponent(JSON.stringify({ theme }))
      try {
        const res = await page.goto(`${base}/rails/view_components/${preview}?_display=${display}${rtl ? "&dir=rtl" : ""}`, { waitUntil: "networkidle" })
        if (!res.ok()) throw new Error(`HTTP ${res.status()}`)
        await page.evaluate(() => document.fonts.ready)
        await page.screenshot({ path: path.join(dirs.__current__, name), fullPage: true })
      } catch (e) {
        results.errors.push(`${name}: ${e.message}`)
        continue
      }
      const cur = path.join(dirs.__current__, name), baseline = path.join(dirs.__baseline__, name)
      if (!fs.existsSync(baseline)) { results.added.push(name); if (update) fs.copyFileSync(cur, baseline); continue }
      const a = PNG.sync.read(fs.readFileSync(baseline)), b = PNG.sync.read(fs.readFileSync(cur))
      if (a.width !== b.width || a.height !== b.height) { results.changed.push(`${name} (size ${a.width}x${a.height} -> ${b.width}x${b.height})`); if (update) fs.copyFileSync(cur, baseline); continue }
      const diff = new PNG({ width: a.width, height: a.height })
      const n = pixelmatch(a.data, b.data, diff.data, a.width, a.height, { threshold: THRESHOLD })
      if (n / (a.width * a.height) > MAX_DIFF_RATIO) {
        fs.writeFileSync(path.join(dirs.__diff__, name), PNG.sync.write(diff))
        results.changed.push(`${name} (${n} px differ)`)
        if (update) fs.copyFileSync(cur, baseline)
      } else results.same++
    }
  }
  await ctx.close()
}
await browser.close()

const total = results.same + results.changed.length + results.added.length
console.log(`\nVisual run: ${total} screenshots, ${results.same} unchanged, ${results.changed.length} changed, ${results.added.length} new, ${results.errors.length} errors`)
if (results.changed.length) console.log(`\nChanged${update ? " (baselines UPDATED, review before committing!)" : ""}:\n  ` + results.changed.join("\n  ") + `\n  diff images: spec/visual/__diff__/`)
if (results.added.length) console.log(`\nNew${update ? " (baselines created)" : " (run bin/visual --update to accept)"}:\n  ` + results.added.join("\n  "))
if (results.errors.length) console.log("\nErrors:\n  " + results.errors.join("\n  "))
process.exit(update ? (results.errors.length ? 1 : 0) : (results.changed.length || results.added.length || results.errors.length ? 1 : 0))
