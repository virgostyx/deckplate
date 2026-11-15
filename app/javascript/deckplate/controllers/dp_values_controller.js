import { Controller } from "@hotwired/stimulus"

// CSP-safe replacement for inline `style="--dp-x: 1"`: the server sends the custom properties in a data attribute
// (csp_safe_values = true) and they are applied through the CSSOM, which a strict `style-src` allows.
export default class extends Controller {
  static values = { vars: Object }

  connect() { this.apply() }
  varsValueChanged() { this.apply() }

  apply() {
    for (const [name, value] of Object.entries(this.varsValue)) this.element.style.setProperty(name, value)
  }

  // Turbo morph would remove the style attribute the CSSOM wrote (the server markup has none)
  keepState(event) {
    if (event.detail.attributeName === "style") event.preventDefault()
  }
}
