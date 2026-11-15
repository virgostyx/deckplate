import { Controller } from "@hotwired/stimulus"

// Focuses its element when connected. Turbo honours the `autofocus` attribute on a normal render but not when it
// morphs the page, and Stimulus connects elements that a morph adds: the form builder sets both on the first invalid field.
export default class extends Controller {
  connect() {
    this.element.focus()
  }
}
