module Deckplate
  # Base of every Deckplate component. Keep it small and boring: everything else builds on it.
  class BaseComponent < ViewComponent::Base
    include Concerns::Colorable
    include Concerns::Sizeable
    include Concerns::Variants

    # Attributes whose values are space-separated token lists: callers add to them, never replace them.
    TOKEN_DATA_KEYS = %i[controller action].freeze

    def initialize(**html_options)
      @html_options = html_options
    end

    private

    # Merges the component's own attributes with the caller's `**html_options`:
    #  - class: appended (never replaced), blanks dropped
    #  - data / aria: deep-merged, caller wins, except data-controller / data-action which are concatenated
    #  - everything else (id, title, ...): caller wins
    def html_attributes(classes: [], data: {}, aria: {}, **own)
      opts = @html_options
      merged = own.merge(opts.except(:class, :data, :aria))
      merged[:class] = [ *classes, *Array(opts[:class]) ].flatten.compact_blank
      merged[:data] = merge_data(data, opts[:data] || {})
      merged[:aria] = (aria || {}).merge(opts[:aria] || {})
      merged.delete(:data) if merged[:data].empty?
      merged.delete(:aria) if merged[:aria].empty?
      merged
    end

    def merge_data(own, theirs)
      own.merge(theirs) do |key, ours, other|
        TOKEN_DATA_KEYS.include?(key.to_sym) ? "#{ours} #{other}".strip : other
      end
    end
  end
end
