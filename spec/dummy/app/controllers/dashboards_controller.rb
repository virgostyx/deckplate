# Live dashboard demo: stable DOM ids + turbo_stream.replace update components in place (Phase 5, task 6).
class DashboardsController < ApplicationController
  READINGS = [ { id: 1, name: "Hull", value: 12.5 }, { id: 2, name: "Core", value: 98.25 }, { id: 3, name: "Deck 7", value: 3.0 } ].freeze
  SORTABLE = %w[name value].freeze

  class << self
    attr_accessor :power, :temp

    def reset! = (self.power = 72; self.temp = 18.4)
  end
  reset!

  def show
    load_state
  end

  def update
    self.class.power = (self.class.power + 5) % 105
    self.class.temp = (self.class.temp + 1.3).round(1)
    load_state
    render turbo_stream: [
      turbo_stream.replace("power-gauge", Deckplate::Data::GaugeComponent.new(label: "Power", value: [ @power, 100 ].min, id: "power-gauge")),
      turbo_stream.replace("temp-readout", Deckplate::Data::ReadoutComponent.new(label: "Coolant", value: @temp, unit: "°C", trend: :up, id: "temp-readout"))
    ]
  end

  private

  def load_state
    @power = self.class.power
    @temp = self.class.temp
    @sort = (params[:sort] if SORTABLE.include?(params[:sort]))
    @dir = (params[:dir] == "desc" ? "desc" : "asc")
    @readings = @sort ? READINGS.sort_by { |r| r[@sort.to_sym] } : READINGS
    @readings = @readings.reverse if @sort && @dir == "desc"
  end
end
