// Identifier -> controller table (ADR 0004). Add each controller here as it is built.
import DpAutofocus from "deckplate/controllers/dp_autofocus_controller"
import DpField from "deckplate/controllers/dp_field_controller"
import DpMenu from "deckplate/controllers/dp_menu_controller"
import DpModal from "deckplate/controllers/dp_modal_controller"
import DpSlider from "deckplate/controllers/dp_slider_controller"
import DpValues from "deckplate/controllers/dp_values_controller"
import DpTabs from "deckplate/controllers/dp_tabs_controller"
import DpTooltip from "deckplate/controllers/dp_tooltip_controller"

const controllers = {
  "dp-autofocus": DpAutofocus,
  "dp-field": DpField,
  "dp-menu": DpMenu,
  "dp-modal": DpModal,
  "dp-slider": DpSlider,
  "dp-tabs": DpTabs,
  "dp-values": DpValues,
  "dp-tooltip": DpTooltip
}

export function registerDeckplate(application, { only, except } = {}) {
  for (const [identifier, controller] of Object.entries(controllers)) {
    if (only && !only.includes(identifier)) continue
    if (except && except.includes(identifier)) continue
    application.register(identifier, controller)
  }
}
