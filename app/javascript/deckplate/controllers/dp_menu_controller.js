import { Controller } from "@hotwired/stimulus"

// Menu button on a native popover: arrow keys, Home/End, Escape and Tab close, focus returns to the trigger.
// The popover is positioned under the trigger with CSSOM custom properties (CSP safe).
export default class extends Controller {
  static targets = ["trigger", "list"]

  disconnect() {
    if (this.listTarget.matches(":popover-open")) this.listTarget.hidePopover()
  }

  get items() { return [...this.listTarget.querySelectorAll('[role="menuitem"]')] }

  toggled(event) {
    const open = event.newState === "open"
    this.triggerTarget.setAttribute("aria-expanded", String(open))
    if (!open) return
    this.position()
    this.focusItem(this.focusLast ? this.items.length - 1 : 0)
    this.focusLast = false
  }

  triggerKey(event) {
    if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return
    event.preventDefault()
    this.focusLast = event.key === "ArrowUp"
    if (this.listTarget.matches(":popover-open")) this.focusItem(this.focusLast ? this.items.length - 1 : 0)
    else this.listTarget.showPopover()
  }

  keydown(event) {
    const items = this.items
    const index = items.indexOf(document.activeElement)
    const move = {
      ArrowDown: (index + 1) % items.length,
      ArrowUp: (index - 1 + items.length) % items.length,
      Home: 0,
      End: items.length - 1
    }[event.key]
    if (move !== undefined) {
      event.preventDefault()
      this.focusItem(move)
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      this.triggerTarget.focus()
    } else if (event.key === "Tab") {
      this.close()
    }
  }

  // Turbo morph: keep what the controller owns (open state mirrored in aria-expanded, roving tabindex, position)
  keepState(event) {
    if (["aria-expanded", "tabindex", "style"].includes(event.detail.attributeName)) event.preventDefault()
  }

  close() {
    if (this.listTarget.matches(":popover-open")) this.listTarget.hidePopover()
  }

  focusItem(index) {
    const items = this.items
    items.forEach((item, i) => { item.tabIndex = i === index ? 0 : -1 })
    items[index]?.focus()
  }

  position() {
    const trigger = this.triggerTarget.getBoundingClientRect()
    const list = this.listTarget
    const left = Math.max(8, Math.min(trigger.left, window.innerWidth - list.offsetWidth - 8))
    list.style.setProperty("--dp-menu-top", `${trigger.bottom + 4}px`)
    list.style.setProperty("--dp-menu-left", `${left}px`)
  }
}
