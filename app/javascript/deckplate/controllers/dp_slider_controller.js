import { Controller } from "@hotwired/stimulus"

// Live readout and track fill for a native range input. CSSOM only (no inline style attribute: CSP safe).
export default class extends Controller {
  static targets = ["input", "output"]
  static values = { unit: { type: String, default: "" } }

  connect() { this.update() }

  update() {
    const { value, min, max } = this.inputTarget
    const span = Number(max) - Number(min) || 1
    this.element.style.setProperty("--dp-pct", ((Number(value) - Number(min)) / span) * 100)
    if (this.hasOutputTarget) this.outputTarget.textContent = `${value}${this.unitValue}`
  }
}
