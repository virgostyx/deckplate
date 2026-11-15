module Deckplate
  module Data
    # Progress bar (role="progressbar"). value: 0..100, or nil for an indeterminate bar. segments: N draws a segmented bar.
    class ProgressComponent < BaseComponent
      def initialize(label:, value:, segments: nil, show_value: false, color: :primary, **html_options)
        super(**html_options)
        raise ArgumentError, "label is required (a progress bar needs an accessible name)" if label.to_s.strip.empty?
        raise ArgumentError, "value must be a number from 0 to 100, or nil for an indeterminate bar (got #{value.inspect})" unless value.nil? || (value.is_a?(Numeric) && (0..100).cover?(value))
        raise ArgumentError, "segments must be an Integer >= 1 (got #{segments.inspect})" unless segments.nil? || (segments.is_a?(Integer) && segments >= 1)

        @label = label
        @value = value
        @segments = segments
        @show_value = show_value
        @color = resolve_color(color)
      end

      private

      def indeterminate? = @value.nil?
      def number = (@value == @value.to_i ? @value.to_i : @value)
      def label_id = "#{@html_options[:id].presence || "#{@label.to_s.parameterize}-progress"}-label"
      def lit_segments = (@value / 100.0 * @segments).round

      def progress_attributes
        html_attributes(
          classes: [ block_name, color_class(@color), ("dp-progress--segmented" if @segments), ("dp-progress--indeterminate" if indeterminate?) ],
          percent: @value,
          role: "progressbar",
          aria: { valuemin: 0, valuemax: 100, valuenow: (number unless indeterminate?), valuetext: ("#{number}%" unless indeterminate?), labelledby: label_id }.compact
        )
      end
    end
  end
end
