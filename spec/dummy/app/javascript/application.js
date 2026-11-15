import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { registerDeckplate } from "deckplate"

const application = Application.start()
registerDeckplate(application)
window.Stimulus = application
