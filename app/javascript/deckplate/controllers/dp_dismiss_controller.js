import { Controller } from "@hotwired/stimulus"

// Removes its element (an Alert) and, when the focus was inside it, hands the focus to the next focusable element
// so that a keyboard user is not sent back to the top of the page.
export default class extends Controller {
  dismiss() {
    const hadFocus = this.element.contains(document.activeElement)
    const next = hadFocus ? this.nextFocusable() : null
    this.element.remove()
    next?.focus()
  }

  nextFocusable() {
    const focusable = [...document.querySelectorAll('a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select, textarea, [tabindex]:not([tabindex="-1"])')]
      .filter((el) => !this.element.contains(el) && el.offsetParent !== null)
    const after = focusable.find((el) => this.element.compareDocumentPosition(el) & Node.DOCUMENT_POSITION_FOLLOWING)
    return after ?? focusable.at(-1)
  }
}
