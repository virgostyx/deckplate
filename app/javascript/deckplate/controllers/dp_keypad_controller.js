import { Controller } from "@hotwired/stimulus"

// On-screen keypad for a numeric <input> (Forms::KeypadComponent). The input stays the source of truth: the physical keyboard types into it,
// the pad edits it, and every change goes through one path, an `input` event (so dp-field, form validation and host scripts see it).
// A polite live region says how many digits there are, never which (a masked code stays secret).
export default class extends Controller {
  static targets = ["input", "status"]
  static values = { statusTemplate: String }

  press(event) {
    const input = this.inputTarget
    if (input.maxLength >= 0 && input.value.length >= input.maxLength) return
    this.change(input.value + event.params.digit)
  }

  backspace() { this.change(this.inputTarget.value.slice(0, -1)) }
  clear() { this.change("") }

  // Runs on every input event: keeps only digits (typed, pasted or pressed), within the length, and announces the count
  sanitize() {
    const input = this.inputTarget
    let digits = input.value.replace(/\D/g, "")
    if (input.maxLength >= 0) digits = digits.slice(0, input.maxLength)
    if (digits !== input.value) input.value = digits
    this.statusTarget.textContent = this.statusTemplateValue.replace("%{count}", digits.length)
  }

  change(value) {
    if (value === this.inputTarget.value) return
    this.inputTarget.value = value
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
