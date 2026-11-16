import { Controller } from "@hotwired/stimulus"

// Toast: auto-dismiss after `duration` ms (0 = stays), paused while hovered or focused (WCAG 2.2.1), no timer left behind on
// disconnect, and the stack is capped by the container's data-dp-toast-max (the oldest toasts are removed first).
export default class extends Controller {
  static values = { duration: Number }

  connect() {
    this.remaining = this.durationValue
    this.limitStack()
    if (this.remaining > 0) this.start()
  }

  disconnect() { this.stop() }

  start() {
    this.stop()
    this.startedAt = Date.now()
    this.timer = setTimeout(() => this.dismiss(), this.remaining)
  }

  stop() {
    clearTimeout(this.timer)
    this.timer = null
  }

  pause() {
    if (!this.timer) return
    this.remaining -= Date.now() - this.startedAt
    this.stop()
  }

  resume(event) {
    if (this.durationValue <= 0 || this.timer) return
    if (event?.type === "focusout" && this.element.contains(event.relatedTarget)) return // focus moves within the toast
    if (this.element.matches(":hover, :focus-within") && event?.type !== "focusout") return
    this.start()
  }

  dismiss() {
    this.stop()
    this.element.remove()
  }

  limitStack() {
    const container = this.element.parentElement
    const max = Number(container?.dataset.dpToastMax) || 5
    const toasts = [...container.children].filter((el) => el.matches("[data-controller~='dp-toast']"))
    toasts.slice(0, Math.max(0, toasts.length - max)).forEach((el) => el.remove())
  }
}
