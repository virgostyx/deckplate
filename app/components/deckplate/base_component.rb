module Deckplate
  # Base of every Deckplate component. Keep it small and boring: everything else builds on it.
  class BaseComponent < ViewComponent::Base
    include Concerns::Colorable
    include Concerns::Sizeable
    include Concerns::Variants

    # Attributes whose values are space-separated token lists: callers add to them, never replace them.
    TOKEN_DATA_KEYS = %i[controller action].freeze
    TOKEN_ARIA_KEYS = %i[describedby].freeze

    def initialize(**html_options)
      @html_options = html_options
    end

    private

    # Dynamic values for a child element (a bar of a graph, a segment...): {class:, data:, style:} without the caller's options
    def dynamic_attributes(classes: [], vars: {}, percent: nil)
      classes, data, own = dynamic_values(classes, {}, {}, vars, percent)
      { class: classes.presence, data: data.presence, style: own[:style].presence }.compact
    end

    # Merges the component's own attributes with the caller's `**html_options`:
    #  - class: appended (never replaced), blanks dropped
    #  - data / aria: deep-merged, caller wins, except data-controller / data-action / aria-describedby which are concatenated
    #  - vars: / percent: dynamic CSS custom properties: inline style, or with csp_safe_values a data attribute applied by
    #    dp-values (vars) / a quantised dp-v-N class (percent), so that no style attribute is ever emitted
    #  - style: component's declarations first, then the caller's
    #  - everything else (id, title, ...): caller wins
    def html_attributes(classes: [], data: {}, aria: {}, vars: {}, percent: nil, **own)
      opts = @html_options
      classes, data, own = dynamic_values(classes, data, own, vars, percent)
      merged = own.merge(opts.except(:class, :data, :aria))
      merged[:class] = [ *classes, *Array(opts[:class]) ].flatten.compact_blank
      merged[:data] = merge_data(data, opts[:data] || {})
      merged[:aria] = merge_tokens(aria || {}, opts[:aria] || {}, TOKEN_ARIA_KEYS)
      style = [ own[:style], opts[:style] ].map { _1.to_s.strip.delete_suffix(";").strip }.compact_blank.join("; ")
      style.empty? ? merged.delete(:style) : merged[:style] = style
      merged.delete(:data) if merged[:data].empty?
      merged.delete(:aria) if merged[:aria].empty?
      merged
    end

    # Dynamic values are the only place where a component would write an inline style. See SPEC section 11.
    def dynamic_values(classes, data, own, vars, percent)
      vars = vars.transform_keys(&:to_s).transform_values(&:to_s)
      classes = Array(classes)
      if percent
        pct = percent.to_f.clamp(0, 100)
        if csp_safe_values?
          classes += [ "dp-v-#{pct.round}" ]
          data = data.merge(dp_value: pct.round)
        else
          vars["--dp-value"] = (pct == pct.to_i ? pct.to_i : pct).to_s
        end
      end
      if vars.any?
        if csp_safe_values?
          data = merge_data(data, { controller: "dp-values", dp_values_vars_value: vars.to_json })
        else
          own = own.merge(style: [ own[:style], vars.map { |k, v| "#{k}: #{v}" }.join("; ") ].compact_blank.join("; "))
        end
      end
      [ classes, data, own ]
    end

    def csp_safe_values? = Deckplate.configuration.csp_safe_values

    def merge_data(own, theirs) = merge_tokens(own, theirs, TOKEN_DATA_KEYS)

    def merge_tokens(own, theirs, token_keys)
      own.merge(theirs) do |key, ours, other|
        token_keys.include?(key.to_sym) ? "#{ours} #{other}".strip : other
      end
    end
  end
end
