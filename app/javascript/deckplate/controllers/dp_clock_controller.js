import { Controller } from "@hotwired/stimulus"

// Updates a server-rendered clock once a second from the server's epoch (offset measured once at connect), pauses while
// the tab is hidden, and leaves no timer behind on disconnect (Turbo cache and morph safe).
export default class extends Controller {
  static values = { epoch: Number, zone: String, format: { type: String, default: "time" } }

  connect() {
    this.offset = this.epochValue - Date.now()
    this.onVisibility = () => (document.hidden ? this.stop() : this.start())
    document.addEventListener("visibilitychange", this.onVisibility)
    if (!document.hidden) this.start()
  }

  disconnect() {
    this.stop()
    document.removeEventListener("visibilitychange", this.onVisibility)
  }

  start() {
    this.stop()
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  stop() {
    clearInterval(this.timer)
    this.timer = null
  }

  tick() {
    this.element.textContent = this.format(new Date(Date.now() + this.offset))
  }

  // Same digits as the server's strftime: 24 h, zero padded, ISO date order
  format(date) {
    const parts = Object.fromEntries(
      new Intl.DateTimeFormat("en-GB", {
        timeZone: this.zoneValue, year: "numeric", month: "2-digit", day: "2-digit",
        hour: "2-digit", minute: "2-digit", second: "2-digit", hourCycle: "h23"
      }).formatToParts(date).map((p) => [p.type, p.value])
    )
    const day = `${parts.year}-${parts.month}-${parts.day}`
    const time = `${parts.hour}:${parts.minute}:${parts.second}`
    return { date: day, datetime: `${day} ${time}`, time }[this.formatValue] ?? time
  }
}
