# Live dashboard demo: stable DOM ids + turbo_stream.replace update components in place (Phase 5, task 6).
class DashboardsController < ApplicationController
  READINGS = [ { id: 1, name: "Hull", value: 12.5 }, { id: 2, name: "Core", value: 98.25 }, { id: 3, name: "Deck 7", value: 3.0 } ].freeze
  SORTABLE = %w[name value].freeze

  class << self
    attr_accessor :power, :temp, :step

    def reset! = (self.power = 72; self.temp = 18.4; self.step = 1)
  end
  reset!

  def show
    load_state
  end

  def update
    self.class.power = (self.class.power + 5) % 105
    self.class.temp = (self.class.temp + 1.3).round(1)
    self.class.step = [ self.class.step + 1, 4 ].min
    load_state
    render turbo_stream: [
      turbo_stream.replace("power-gauge", Deckplate::Data::GaugeComponent.new(label: "Power", value: [ @power, 100 ].min, id: "power-gauge")),
      turbo_stream.replace("mission", partial: "dashboards/mission", locals: { step: self.class.step }),
      turbo_stream.replace("temp-readout", Deckplate::Data::ReadoutComponent.new(label: "Coolant", value: @temp, unit: "°C", trend: :up, id: "temp-readout", flicker: true))
    ]
  end

  private

  def load_state
    @power = self.class.power
    @temp = self.class.temp
    @step = self.class.step
    @sort = (params[:sort] if SORTABLE.include?(params[:sort]))
    @dir = (params[:dir] == "desc" ? "desc" : "asc")
    @readings = @sort ? READINGS.sort_by { |r| r[@sort.to_sym] } : READINGS
    @readings = @readings.reverse if @sort && @dir == "desc"
  end
end
