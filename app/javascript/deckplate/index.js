// Identifier -> controller table (ADR 0004). Add each controller here as it is built.
import DpSlider from "deckplate/controllers/dp_slider_controller"

const controllers = {
  "dp-slider": DpSlider
}

export function registerDeckplate(application, { only, except } = {}) {
  for (const [identifier, controller] of Object.entries(controllers)) {
    if (only && !only.includes(identifier)) continue
    if (except && except.includes(identifier)) continue
    application.register(identifier, controller)
  }
}
