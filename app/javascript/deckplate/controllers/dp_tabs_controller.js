import { Controller } from "@hotwired/stimulus"

// WAI-ARIA tabs: roving tabindex, ArrowLeft/Right (wrapping), Home/End, automatic activation.
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { hash: Boolean }

  connect() {
    if (!this.hashValue) return
    const tab = this.tabTargets.find((t) => `#${this.slug(t)}` === window.location.hash)
    if (tab) this.activate(tab, { focus: false, updateHash: false })
  }

  select(event) {
    this.activate(event.currentTarget, { focus: false })
  }

  keydown(event) {
    const last = this.tabTargets.length - 1
    const index = this.tabTargets.indexOf(event.currentTarget)
    const target = {
      ArrowRight: index === last ? 0 : index + 1,
      ArrowLeft: index === 0 ? last : index - 1,
      Home: 0,
      End: last
    }[event.key]
    if (target === undefined) return
    event.preventDefault()
    this.activate(this.tabTargets[target], { focus: true })
  }

  activate(tab, { focus, updateHash = true }) {
    this.tabTargets.forEach((t) => {
      const selected = t === tab
      t.setAttribute("aria-selected", String(selected))
      t.tabIndex = selected ? 0 : -1
    })
    this.panelTargets.forEach((panel) => { panel.hidden = panel.id !== tab.getAttribute("aria-controls") })
    if (focus) tab.focus()
    if (this.hashValue && updateHash) window.history.replaceState(window.history.state, "", `#${this.slug(tab)}`)
  }

  // Turbo morph: the selection lives in the DOM, so a refresh must not reset it to what the server rendered
  keepState(event) {
    if (["aria-selected", "tabindex", "hidden"].includes(event.detail.attributeName)) event.preventDefault()
  }

  slug(tab) { return tab.id.replace(/-tab$/, "") }
}
