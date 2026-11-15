module Deckplate
  module Concerns
    # Declares closed sets of modifiers:  variant :size, %i[sm md lg], default: :md
    # They become BEM modifier classes (dp-button--lg). Values are validated, class strings are never built from free input.
    # Use `prefix: true` when two variants share a value name (dp-block--align-start vs dp-block--start).
    module Variants
      extend ActiveSupport::Concern

      class_methods do
        def variant(name, values, default:, prefix: false)
          values = values.map(&:to_sym)
          raise ArgumentError, "default #{default.inspect} is not one of #{values.inspect}" unless values.include?(default.to_sym)

          variant_definitions[name.to_sym] = { values: values.freeze, default: default.to_sym, prefix: prefix }
        end

        def variant_definitions
          @variant_definitions ||= superclass.respond_to?(:variant_definitions) ? superclass.variant_definitions.dup : {}
        end

        # "Deckplate::Forms::TextInputComponent" -> "dp-text-input"
        def block_name
          "dp-#{name.demodulize.delete_suffix('Component').underscore.dasherize}"
        end
      end

      def block_name = self.class.block_name

      # assign_variants(size: :lg, shape: nil): nil means "use the default".
      def assign_variants(**given)
        defs = self.class.variant_definitions
        unknown = given.keys - defs.keys
        raise ArgumentError, "unknown variant #{unknown.first.inspect} (declared: #{defs.keys.map(&:inspect).join(', ')})" if unknown.any?

        @variants = defs.to_h do |name, d|
          value = given[name].nil? ? d[:default] : given[name].to_sym
          raise ArgumentError, "invalid #{name} #{given[name].inspect}; valid: #{d[:values].join(', ')}" unless d[:values].include?(value)

          [ name, value ]
        end
      end

      def variants = @variants || assign_variants

      def variant_classes
        variants.map do |name, value|
          modifier = self.class.variant_definitions.fetch(name)[:prefix] ? "#{name}-#{value}" : value.to_s
          "#{block_name}--#{modifier.tr('_', '-')}"
        end
      end
    end
  end
end
