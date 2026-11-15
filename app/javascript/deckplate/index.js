import DpProbe from "deckplate/controllers/dp_probe_controller"

export function registerDeckplate(application) {
  application.register("dp-probe", DpProbe)
}
