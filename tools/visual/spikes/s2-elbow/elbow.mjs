import { chromium, firefox, webkit } from "playwright"
import { PNG } from "pngjs"
const engines = { chrome: () => chromium.launch({ channel: "chrome" }), firefox: () => firefox.launch(), webkit: () => webkit.launch() }
const only = process.argv[2]?.split(",") ?? Object.keys(engines)
const techs = ["a", "a2", "b"], dprs = [1, 1.25, 1.5, 1.75, 2]
const url = "file://" + process.cwd() + "/elbow.html"

function expected(g, px, py, dpr) { // coverage 0..1 of device pixel (px,py), 4x4 supersample
  let n = 0
  for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) {
    const x = (px + (i + .5) / 4) / dpr - g.x, y = (py + (j + .5) / 4) / dpr - g.y
    if (inside(g, x, y)) n++
  }
  return n / 16
}
function inside(g, x, y) {
  if (x < 0 || y < 0 || x > g.W || y > g.H) return false
  if (x < g.r && y < g.r && Math.hypot(x - g.r, y - g.r) > g.r) return false
  if (x > g.col && y > g.bar) {
    if (x < g.col + g.ri && y < g.bar + g.ri && Math.hypot(x - g.col - g.ri, y - g.bar - g.ri) > g.ri) return true
    return false
  }
  return true
}
const png = async (page) => PNG.sync.read(await page.screenshot())

for (const name of only) {
  const b = await engines[name]()
  for (const t of techs) {
    const row = []
    for (const dpr of dprs) {
      const ctx = await b.newContext({ deviceScaleFactor: dpr, viewport: { width: 400, height: 360 } })
      const page = await ctx.newPage()
      await page.goto(url)
      await page.evaluate((t) => { document.documentElement.className = t; document.body.className = "" }, t)
      document: { }
      await page.evaluate((t) => document.body.parentElement.classList.add(t), t)
      const g = await page.evaluate(() => {
        const e = document.querySelector(".e"), cs = getComputedStyle(e), r = e.getBoundingClientRect()
        const v = (n) => { const d = document.createElement("div"); d.style.width = `var(${n})`; e.appendChild(d); const w = d.getBoundingClientRect().width; d.remove(); return w }
        return { x: r.x, y: r.y, W: r.width, H: r.height, col: v("--col"), bar: v("--bar"), r: v("--r"), ri: v("--ri") }
      })
      // note: class on <html> so ".a .e" matches (html > body > .e)
      const img = await png(page)
      let bad = 0, checked = 0
      const m = 1.5 // css px margin around the theoretical boundary
      const offs = [[0,0],[m,0],[-m,0],[0,m],[0,-m],[m,m],[-m,-m],[m,-m],[-m,m]]
      for (let py = 0; py < img.height; py++) for (let px = 0; px < img.width; px++) {
        const cx = (px + .5) / dpr - g.x, cy = (py + .5) / dpr - g.y
        const ins = offs.map(([dx, dy]) => inside(g, cx + dx, cy + dy))
        const all = ins.every(Boolean), none = ins.every((v) => !v)
        if (!all && !none) continue
        checked++
        const k = (py * img.width + px) * 4
        const [R, G, B] = [img.data[k], img.data[k + 1], img.data[k + 2]]
        const ok = all ? (R === 255 && G === 0x99 && B === 0x33) : (R === 0 && G === 0 && B === 0)
        if (!ok) bad++
      }
      const maxErr = 0
      // transparency over a pattern
      await page.evaluate(() => document.body.classList.add("pattern"))
      const withE = await png(page)
      await page.evaluate(() => document.body.classList.add("hide"))
      const ref = await png(page)
      let leak = 0, total = 0
      const x0 = Math.ceil((g.x + g.col + g.ri + 3) * dpr), x1 = Math.floor((g.x + g.W - 3) * dpr)
      const y0 = Math.ceil((g.y + g.bar + g.ri + 3) * dpr), y1 = Math.floor((g.y + g.H - 3) * dpr)
      for (let py = y0; py < y1; py++) for (let px = x0; px < x1; px++) {
        total++
        const k = (py * ref.width + px) * 4
        if (withE.data[k] !== ref.data[k] || withE.data[k + 2] !== ref.data[k + 2]) leak++
      }
      row.push(`dpr${dpr}: seam=${bad}/${checked} leak=${leak}/${total}`)
      await ctx.close()
    }
    console.log(`${name} ${t.padEnd(2)} | ` + row.join(" | "))
  }
  await b.close()
}
