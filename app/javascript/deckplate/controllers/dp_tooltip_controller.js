import { Controller } from "@hotwired/stimulus"

// Hover/focus tooltip on a manual popover. Dismissable with Escape and hoverable (WCAG 1.4.13); never essential content.
export default class extends Controller {
  static targets = ["bubble"]

  connect() {
    const trigger = this.element.querySelector('a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])')
    if (!trigger) return
    const ids = (trigger.getAttribute("aria-describedby") || "").split(" ").filter(Boolean)
    if (!ids.includes(this.bubbleTarget.id)) trigger.setAttribute("aria-describedby", [...ids, this.bubbleTarget.id].join(" "))
  }

  disconnect() { this.hide() }

  show() {
    if (this.bubbleTarget.matches(":popover-open")) return
    this.bubbleTarget.showPopover()
    const host = this.element.getBoundingClientRect()
    const left = Math.max(8, Math.min(host.left, window.innerWidth - this.bubbleTarget.offsetWidth - 8))
    this.bubbleTarget.style.setProperty("--dp-tip-top", `${host.bottom + 6}px`)
    this.bubbleTarget.style.setProperty("--dp-tip-left", `${left}px`)
  }

  hide() {
    if (this.bubbleTarget.matches(":popover-open")) this.bubbleTarget.hidePopover()
  }

  key(event) {
    if (event.key === "Escape") this.hide()
  }
}
