import { Controller } from "@hotwired/stimulus"

// Modal on <dialog>: showModal() provides the focus trap, Esc and inert background; this adds backdrop click,
// scroll lock, focus return, closing after a successful Turbo form submission, and cleanup before Turbo caches the page.
export default class extends Controller {
  static targets = ["dialog"]
  static values = { open: Boolean }

  connect() {
    if (this.openValue) this.open()
  }

  disconnect() {
    if (this.dialogTarget.open) this.dialogTarget.close()
    this.unlock()
  }

  open(event) {
    this.opener = event?.currentTarget ?? document.activeElement
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
    document.documentElement.classList.add("dp-scroll-lock")
    this.makeScrollableBodyFocusable()
  }

  // A scrolling region must be reachable with the keyboard (WCAG 2.1.1). Only when it actually scrolls, to avoid an extra tab stop.
  makeScrollableBodyFocusable() {
    const body = this.dialogTarget.querySelector(".dp-modal__body")
    if (!body) return
    if (body.scrollHeight > body.clientHeight) body.tabIndex = 0
    else body.removeAttribute("tabindex")
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  // A click on the backdrop targets the dialog element itself (the panel inside covers the rest)
  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  closed() {
    this.unlock()
    if (this.opener?.isConnected) this.opener.focus()
    this.opener = null
  }

  submitEnd(event) {
    if (event.detail?.success) this.close()
  }

  // Turbo morph would remove the `open` attribute that showModal() set, closing the dialog under the user
  keepState(event) {
    if (event.detail.attributeName === "open") event.preventDefault()
  }

  unlock() {
    if (!document.querySelector("dialog[open]")) document.documentElement.classList.remove("dp-scroll-lock")
  }
}
