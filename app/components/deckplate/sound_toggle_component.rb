module Deckplate
  # The mute switch for config.sounds. Renders nothing when sounds are disabled. dp-sound keeps the choice in localStorage.
  class SoundToggleComponent < BaseComponent
    def initialize(label: nil, **html_options)
      super(**html_options)
      @label = label
    end

    def render? = Deckplate.configuration.sounds

    private

    def toggle_options
      html_attributes(data: { dp_sound_target: "toggle", action: "change->dp-sound#setEnabled" })
    end
  end
end
