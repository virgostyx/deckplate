import { Controller } from "@hotwired/stimulus"

// Theme switcher: sets data-dp-theme on <html> and stores the choice in a cookie (the server reads it for the first paint).
// The name comes from the DOM, so it is checked against the list of themes the server allowed.
export default class extends Controller {
  static values = { themes: Array, cookie: { type: String, default: "dp_theme" } }

  select(event) {
    const name = event.params.name
    if (!this.themesValue.includes(name)) return
    document.documentElement.dataset.dpTheme = name
    this.persist(name)
    this.markPressed(name)
    this.dispatch("change", { detail: { theme: name } })
  }

  persist(name) {
    const secure = window.location.protocol === "https:" ? "; Secure" : ""
    document.cookie = `${this.cookieValue}=${encodeURIComponent(name)}; path=/; max-age=31536000; SameSite=Lax${secure}`
  }

  markPressed(name) {
    this.element.querySelectorAll("[data-dp-theme-name-param]").forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.dpThemeNameParam === name))
    })
  }

  // Turbo morph: the pressed state was just set from the user's choice
  keepState(event) {
    if (event.detail.attributeName === "aria-pressed") event.preventDefault()
  }
}
