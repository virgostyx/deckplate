module Deckplate
  # Button, link-button, or button_to form depending on `href:` and `method:`.
  # Loading is visual + ARIA only (aria-busy/aria-disabled); use Turbo's data-turbo-submits-with to block double submits.
  class ButtonComponent < BaseComponent
    TYPES = %w[button submit reset].freeze
    METHODS = %i[get post put patch delete].freeze

    variant :shape, %i[pill block start end], default: :pill
    variant :size, %i[xs sm md lg xl], default: :md

    def initialize(label: nil, color: :primary, shape: nil, size: nil, type: "button", href: nil, method: nil,
                   icon: nil, loading: false, disabled: false, **html_options)
      super(**html_options)
      assign_variants(shape:, size:)
      @label = label
      @color = resolve_color(color)
      @type = validate_type(type)
      @href = href
      @http_method = validate_method(method, href)
      @icon = icon
      @loading = loading
      @disabled = disabled
    end

    def before_render
      raise ArgumentError, "label: or a block is required" if @label.blank? && !content?
    end

    private

    # a short tick on click, only when sounds are enabled (the dp-sound controller is on an ancestor)
    def sound_data = Deckplate.configuration.sounds ? { action: "click->dp-sound#play", dp_sound_tone_param: "tick" } : {}

    def unavailable? = @disabled || @loading

    def attributes
      html_attributes(
        classes: [ block_name, *variant_classes, color_class(@color), ("dp-button--loading" if @loading) ],
        data: sound_data,
        aria: { busy: (true if @loading), disabled: (true if unavailable? && !native_disabled?) }.compact
      )
    end

    # a real <button> uses the disabled attribute; links and loading buttons use aria-disabled
    def native_disabled? = @disabled && @href.nil?

    def validate_type(type)
      type = type.to_s
      raise ArgumentError, "invalid type #{type.inspect}; valid: #{TYPES.join(', ')}" unless TYPES.include?(type)

      type
    end

    def validate_method(method, href)
      return nil if method.nil? || method.to_sym == :get

      raise ArgumentError, "invalid method #{method.inspect}; valid: #{METHODS.join(', ')}" unless METHODS.include?(method.to_sym)
      raise ArgumentError, "method: #{method.inspect} needs an href (it renders a form posting to it)" if href.nil?

      method.to_sym
    end
  end
end
