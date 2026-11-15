require "action_view"

module Deckplate
  # form_with model: @ship, builder: Deckplate::FormBuilder  (or config.form_builder = true).
  # Each dp_* method renders a Deckplate form control with the label, hint, errors, required marker and current value
  # taken from the model (ActiveModel: human_attribute_name, errors, presence validators, I18n helpers.label / helpers.hint).
  class FormBuilder < ActionView::Helpers::FormBuilder
    def dp_text_field(method, **options) = dp_control(Forms::TextInputComponent, method, type: :text, value: true, **options)
    def dp_email_field(method, **options) = dp_control(Forms::TextInputComponent, method, type: :email, value: true, **options)
    def dp_password_field(method, **options) = dp_control(Forms::TextInputComponent, method, type: :password, **options)
    def dp_number_field(method, **options) = dp_control(Forms::TextInputComponent, method, type: :number, value: true, **options)
    def dp_text_area(method, **options) = dp_control(Forms::TextareaComponent, method, value: true, **options)
    def dp_select(method, choices, **options) = dp_control(Forms::SelectComponent, method, options: choices, value: true, **options)
    def dp_range(method, **options) = dp_control(Forms::RangeComponent, method, value: true, **options)
    def dp_date_field(method, **options) = dp_control(Forms::DateInputComponent, method, value: true, **options)
    def dp_radio_group(method, choices, **options) = dp_control(Forms::RadioGroupComponent, method, options: choices, value: true, autofocus: false, **options)

    def dp_file_field(method, multiple: false, **options)
      dp_control(Forms::FileInputComponent, method, multiple: multiple, name: field_name(method, multiple: multiple), **options)
    end

    # Like Rails' check_box: a hidden field submits `unchecked_value` when the box is not ticked.
    def dp_check_box(method, checked_value: "1", unchecked_value: "0", **options)
      current = dp_value(method)
      checked = current.to_s == checked_value.to_s || ActiveModel::Type::Boolean.new.cast(current) == true
      dp_control(Forms::CheckboxComponent, method, value: checked_value, checked: checked, unchecked_value: unchecked_value, **options)
    end

    def dp_submit(label = nil, color: :primary, **options)
      @template.render(ButtonComponent.new(label: label || submit_default_value, type: "submit", color: color, **options))
    end

    def dp_actions(**options, &block)
      @template.render(Forms::FormActionsComponent.new(**options)) { @template.capture(&block) }
    end

    private

    # `value: true` means "read the current value from the model"; an explicit value is passed on as is.
    def dp_control(component, method, value: nil, autofocus: true, **options)
      defaults = { name: field_name(method), id: field_id(method), label: dp_label(method), hint: dp_hint(method),
                   errors: dp_errors(method), required: dp_required?(method) }
      defaults[:value] = (value == true ? dp_value(method) : value) unless value.nil?
      if defaults[:errors].any? && !dp_state[:first_error_seen]
        dp_state[:first_error_seen] = true
        defaults[:alert] = true
        defaults[:autofocus] = true if autofocus
      end
      @template.render(component.new(**defaults, **options))
    end

    # Shared with nested builders (fields_for) so that only the first invalid field of the whole form gets role=alert
    def dp_state
      @dp_state ||= @options[:parent_builder].respond_to?(:dp_state, true) ? @options[:parent_builder].send(:dp_state) : { first_error_seen: false }
    end

    def dp_value(method) = (object.public_send(method) if object.respond_to?(method))

    def dp_errors(method) = (object.respond_to?(:errors) ? object.errors[method] : [])

    def dp_i18n_scope = (object.respond_to?(:model_name) ? object.model_name.i18n_key : object_name)

    def dp_label(method)
      human = object.class.respond_to?(:human_attribute_name) ? object.class.human_attribute_name(method) : method.to_s.humanize
      I18n.t("helpers.label.#{dp_i18n_scope}.#{method}", default: human)
    end

    def dp_hint(method) = I18n.t("helpers.hint.#{dp_i18n_scope}.#{method}", default: "").presence

    # Required when the model validates presence unconditionally
    def dp_required?(method)
      return false unless object.class.respond_to?(:validators_on)

      object.class.validators_on(method).any? { |v| v.kind == :presence && v.options[:if].nil? && v.options[:unless].nil? }
    end
  end
end
