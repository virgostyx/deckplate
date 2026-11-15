// Elbow regression (ADR 0002): for all four corners, at fractional device pixel ratios, in Chrome/Firefox/WebKit:
//   seam = pixel clearly inside/outside the analytic shape that is not exactly the fill/background colour
//   edge = a straight edge whose position varies along its length (stair-step). Failing threshold 0.3 device px:
//          a real 1px stair-step measures 0.5-1.0, WebKit anti-aliasing noise stays below 0.25
//   leak = pixel of the cut-out that differs from a patterned page background (the inner arc must be transparent)
// Usage: node elbow_geometry.mjs --base http://localhost:3099 [--browsers chrome,firefox,webkit] [--dprs 1,1.25,1.5,1.75,2]
import { chromium, firefox, webkit } from "playwright"
import { PNG } from "pngjs"

const args = Object.fromEntries(process.argv.slice(2).reduce((a, x, i, all) => (x.startsWith("--") ? [...a, [x.slice(2), all[i + 1]]] : a), []))
const base = args.base ?? "http://localhost:3099"
const launchers = { chrome: () => chromium.launch({ channel: process.env.VISUAL_CHANNEL ?? "chrome" }), firefox: () => firefox.launch(), webkit: () => webkit.launch() }
const browsers = (args.browsers ?? "chrome").split(",")
const dprs = (args.dprs ?? "1,1.25,1.5,1.75,2").split(",").map(Number)
const corners = ["top_left", "top_right", "bottom_left", "bottom_right"]
const FILL = [0xff, 0x99, 0x33] // --dp-primary in the classic theme
const MARGIN = 1.5 // css px around every theoretical boundary where anti-aliasing is allowed

// Analytic shape in the element's own coordinates, for a top-left elbow; other corners are mirrored first.
function inside(g, x, y) {
  if (g.corner.endsWith("right")) x = g.W - x
  if (g.corner.startsWith("bottom")) y = g.H - y
  if (x < 0 || y < 0 || x > g.W || y > g.H) return false
  if (x < g.r && y < g.r && Math.hypot(x - g.r, y - g.r) > g.r) return false
  if (x > g.col && y > g.bar) return x < g.col + g.ri && y < g.bar + g.ri && Math.hypot(x - g.col - g.ri, y - g.bar - g.ri) > g.ri
  return true
}

async function measure(page, corner, dpr) {
  const sel = `[data-geometry-elbow='${corner}']`
  const g = await page.evaluate((sel) => {
    const el = document.querySelector(sel), r = el.getBoundingClientRect()
    const len = (name) => { const d = document.createElement("div"); d.style.cssText = `position:absolute;visibility:hidden;width:var(${name})`; el.appendChild(d); const w = d.getBoundingClientRect().width; d.remove(); return w }
    return { x: r.x + scrollX, y: r.y + scrollY, W: r.width, H: r.height, col: len("--_col"), bar: len("--_bar"), r: len("--_r"), ri: len("--_ri") }
  }, sel)
  g.corner = corner
  const box = { x: Math.floor(g.x) - 4, y: Math.floor(g.y) - 4, width: Math.ceil(g.W) + 8, height: Math.ceil(g.H) + 8 }
  const shoot = async () => PNG.sync.read(await page.screenshot({ fullPage: true, clip: box }))

  // 1) seams on a plain black background
  await page.evaluate(() => document.body.classList.add("gx-flat"))
  const flat = await shoot()
  const offs = [[0, 0], [MARGIN, 0], [-MARGIN, 0], [0, MARGIN], [0, -MARGIN], [MARGIN, MARGIN], [-MARGIN, -MARGIN], [MARGIN, -MARGIN], [-MARGIN, MARGIN]]
  let seams = 0, checked = 0
  for (let py = 0; py < flat.height; py++) for (let px = 0; px < flat.width; px++) {
    const cx = (px + 0.5) / dpr + box.x - g.x, cy = (py + 0.5) / dpr + box.y - g.y
    const ins = offs.map(([dx, dy]) => inside(g, cx + dx, cy + dy))
    const all = ins.every(Boolean), none = ins.every((v) => !v)
    if (!all && !none) continue
    checked++
    const k = (py * flat.width + px) * 4, rgb = [flat.data[k], flat.data[k + 1], flat.data[k + 2]]
    const ok = all ? rgb.every((v, i) => v === FILL[i]) : rgb.every((v) => v === 0)
    if (!ok) seams++
  }

  // 1b) straight edges must be straight: position (from coverage sums) constant along the edge
  const edges = [
    { h: true, c: 0, a: g.r + 2, b: g.W - 2 }, { h: false, c: 0, a: g.r + 2, b: g.H - 2 },       // top, left (outer)
    { h: true, c: g.H, a: 2, b: g.col - 2 }, { h: false, c: g.W, a: 2, b: g.bar - 2 },           // bottom of the vertical arm, end of the horizontal arm
    { h: false, c: g.col, a: g.bar + g.ri + 2, b: g.H - 2 }, { h: true, c: g.bar, a: g.col + g.ri + 2, b: g.W - 2 } // inner edges
  ]
  const flipX = corner.endsWith("right"), flipY = corner.startsWith("bottom")
  let edgeSpread = 0
  for (const e of edges) {
    const positions = []
    const coord = e.h ? (flipY ? g.H - e.c : e.c) : (flipX ? g.W - e.c : e.c)
    const [a, b] = e.h ? (flipX ? [g.W - e.b, g.W - e.a] : [e.a, e.b]) : (flipY ? [g.H - e.b, g.H - e.a] : [e.a, e.b])
    const insideSide = e.h ? inside(g, (e.a + e.b) / 2 , e.c + (e.c === 0 || e.c === g.bar ? 1 : -1)) : inside(g, e.c + (e.c === 0 || e.c === g.col ? 1 : -1), (e.a + e.b) / 2)
    for (let t = Math.ceil(a * dpr); t < Math.floor(b * dpr); t++) {
      let sum = 0
      const w0 = Math.floor((coord - 2.5) * dpr), w1 = Math.ceil((coord + 2.5) * dpr)
      for (let u = w0; u < w1; u++) {
        const X = Math.round((e.h ? g.x + t / dpr - 0 : g.x + u / dpr) * dpr) , Y = Math.round((e.h ? g.y + u / dpr : g.y + t / dpr) * dpr)
        const ix = X - Math.round(box.x * dpr), iy = Y - Math.round(box.y * dpr)
        if (ix < 0 || iy < 0 || ix >= flat.width || iy >= flat.height) continue
        sum += flat.data[(iy * flat.width + ix) * 4] / 255
      }
      positions.push(sum)
    }
    if (positions.length) edgeSpread = Math.max(edgeSpread, Math.max(...positions) - Math.min(...positions))
  }

  // 2) transparency over the checker pattern: compare with the same page without the elbow
  await page.evaluate(() => document.body.classList.remove("gx-flat"))
  const withElbow = await shoot()
  await page.evaluate((sel) => { document.querySelector(sel).style.visibility = "hidden" }, sel)
  const without = await shoot()
  await page.evaluate((sel) => { document.querySelector(sel).style.visibility = "" }, sel)
  let leak = 0, total = 0
  for (let py = 0; py < withElbow.height; py++) for (let px = 0; px < withElbow.width; px++) {
    const cx = (px + 0.5) / dpr + box.x - g.x, cy = (py + 0.5) / dpr + box.y - g.y
    const deep = offs.every(([dx, dy]) => cx + dx > 0 && cy + dy > 0 && cx + dx < g.W && cy + dy < g.H && !inside(g, cx + dx, cy + dy))
    if (!deep) continue
    total++
    const k = (py * withElbow.width + px) * 4
    if (withElbow.data[k] !== without.data[k] || withElbow.data[k + 1] !== without.data[k + 1] || withElbow.data[k + 2] !== without.data[k + 2]) leak++
  }
  return { seams, checked, leak, total, edgeSpread }
}

let failed = false
for (const name of browsers) {
  const browser = await launchers[name]()
  for (const dpr of dprs) {
    const ctx = await browser.newContext({ deviceScaleFactor: dpr, viewport: { width: 900, height: 700 }, reducedMotion: "reduce" })
    const page = await ctx.newPage()
    await page.goto(`${base}/rails/view_components/elbow/geometry?_display=${encodeURIComponent(JSON.stringify({ theme: "classic" }))}`)
    await page.evaluate(() => document.fonts.ready)
    const row = []
    for (const corner of corners) {
      const m = await measure(page, corner, dpr)
      if (m.seams || m.leak || m.edgeSpread > 0.3 || !m.checked || !m.total) failed = true
      row.push(`${corner}: seams ${m.seams}, leak ${m.leak}, edge spread ${m.edgeSpread.toFixed(2)}px`)
    }
    console.log(`${name.padEnd(8)} dpr ${String(dpr).padEnd(4)} ${row.join(" | ")}`)
    await ctx.close()
  }
  await browser.close()
}
console.log(failed ? "\nFAIL: seams or leaks found" : "\nOK: no seams, inner arc transparent")
process.exit(failed ? 1 : 0)
