import { Controller } from "@hotwired/stimulus"

// Turbo morph (page refresh in place) copies the server's values onto the live form, which would wipe what the user typed
// in a field they are not editing at that very moment. Once a field has been touched, its value, checked and selected
// state belong to the user until the form is submitted (a normal render replaces the field and resets this).
// A field the user never touched keeps following the server.
export default class extends Controller {
  static PROTECTED = ["value", "checked", "selected"]

  connect() {
    this.touched = this.touched || false
  }

  touch() {
    this.touched = true
  }

  keepState(event) {
    if (this.touched && this.constructor.PROTECTED.includes(event.detail.attributeName)) event.preventDefault()
  }
}
