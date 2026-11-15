module Deckplate
  # Modal dialog on the native <dialog> element (dp-modal): showModal() gives the focus trap, Esc and inertness.
  # The trigger goes in the `trigger` slot (any element with data-action="dp-modal#open"), buttons in `actions`.
  class ModalComponent < BaseComponent
    include Concerns::Headed

    variant :size, %i[sm md lg], default: :md

    renders_one :trigger
    renders_one :actions, ->(&block) { tag.div(class: "dp-modal__actions", &block) }

    def initialize(title:, size: nil, open: false, **html_options)
      super(**html_options)
      @title = validate_title!(title)
      @open = open
      assign_variants(size:)
    end

    private

    def modal_id = @html_options[:id].presence || "#{@title.to_s.parameterize}-modal"
    def title_id = "#{modal_id}-title"

    def host_attributes
      html_attributes(classes: [ "dp-modal-host" ], data: { controller: "dp-modal", action: "turbo:before-morph-attribute->dp-modal#keepState", dp_modal_open_value: (true if @open) }.compact).except(:id)
    end

    def dialog_classes = [ block_name, *variant_classes ]
  end
end
