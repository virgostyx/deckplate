import { Controller } from "@hotwired/stimulus"

// Hover/focus tooltip on a manual popover. Dismissable with Escape and hoverable (WCAG 1.4.13); never essential content.
export default class extends Controller {
  static targets = ["bubble"]
  static values = { placement: { type: String, default: "bottom" }, delay: { type: Number, default: 0 } }

  connect() {
    const trigger = this.element.querySelector('a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])')
    if (!trigger) return
    const ids = (trigger.getAttribute("aria-describedby") || "").split(" ").filter(Boolean)
    if (!ids.includes(this.bubbleTarget.id)) trigger.setAttribute("aria-describedby", [...ids, this.bubbleTarget.id].join(" "))
  }

  disconnect() { this.hide() }

  show(event) {
    clearTimeout(this.timer)
    if (this.bubbleTarget.matches(":popover-open")) return
    const delay = event?.type === "focusin" ? 0 : this.delayValue // keyboard users never wait
    if (delay > 0) this.timer = setTimeout(() => this.open(), delay)
    else this.open()
  }

  open() {
    this.bubbleTarget.showPopover()
    const host = this.element.getBoundingClientRect()
    const width = this.bubbleTarget.offsetWidth
    const height = this.bubbleTarget.offsetHeight
    const gap = 6
    const margin = 8
    const rtl = getComputedStyle(this.element).direction === "rtl"
    const clamp = (value, size, limit) => Math.max(margin, Math.min(value, limit - size - margin))
    const fits = (value, size, limit) => value >= margin && value + size <= limit - margin
    let placement = this.placementValue
    let top, left

    if (placement === "start" || placement === "end") {
      const left_ = rtl === (placement === "start") // true when the bubble goes to the physical right
      const place = (right) => right ? host.right + gap : host.left - width - gap
      let right = left_
      if (!fits(place(right), width, window.innerWidth) && fits(place(!right), width, window.innerWidth)) right = !right
      left = clamp(place(right), width, window.innerWidth)
      top = clamp(host.top + (host.height - height) / 2, height, window.innerHeight)
    } else {
      const place = (above) => above ? host.top - height - gap : host.bottom + gap
      let above = placement === "top"
      if (!fits(place(above), height, window.innerHeight) && fits(place(!above), height, window.innerHeight)) above = !above
      top = clamp(place(above), height, window.innerHeight)
      const start = rtl ? host.right - width : host.left // aligned on the side where the text starts
      left = clamp(start, width, window.innerWidth)
    }
    this.bubbleTarget.style.setProperty("--dp-tip-top", `${top}px`)
    this.bubbleTarget.style.setProperty("--dp-tip-left", `${left}px`)
  }

  hide() {
    clearTimeout(this.timer)
    if (this.bubbleTarget.matches(":popover-open")) this.bubbleTarget.hidePopover()
  }

  key(event) {
    if (event.key === "Escape") this.hide()
  }
}
