// Identifier -> controller table (ADR 0004). Add each controller here as it is built; a spec compares it with the files.
import DpAutofocus from "deckplate/controllers/dp_autofocus_controller"
import DpClock from "deckplate/controllers/dp_clock_controller"
import DpDismiss from "deckplate/controllers/dp_dismiss_controller"
import DpField from "deckplate/controllers/dp_field_controller"
import DpFlicker from "deckplate/controllers/dp_flicker_controller"
import DpMenu from "deckplate/controllers/dp_menu_controller"
import DpModal from "deckplate/controllers/dp_modal_controller"
import DpSlider from "deckplate/controllers/dp_slider_controller"
import DpSound from "deckplate/controllers/dp_sound_controller"
import DpTheme from "deckplate/controllers/dp_theme_controller"
import DpTabs from "deckplate/controllers/dp_tabs_controller"
import DpToast from "deckplate/controllers/dp_toast_controller"
import DpTooltip from "deckplate/controllers/dp_tooltip_controller"
import DpValues from "deckplate/controllers/dp_values_controller"

const controllers = {
  "dp-autofocus": DpAutofocus,
  "dp-clock": DpClock,
  "dp-dismiss": DpDismiss,
  "dp-field": DpField,
  "dp-flicker": DpFlicker,
  "dp-menu": DpMenu,
  "dp-modal": DpModal,
  "dp-slider": DpSlider,
  "dp-tabs": DpTabs,
  "dp-sound": DpSound,
  "dp-theme": DpTheme,
  "dp-toast": DpToast,
  "dp-tooltip": DpTooltip,
  "dp-values": DpValues
}

export function registerDeckplate(application, { only, except } = {}) {
  for (const [identifier, controller] of Object.entries(controllers)) {
    if (only && !only.includes(identifier)) continue
    if (except && except.includes(identifier)) continue
    application.register(identifier, controller)
  }
}
