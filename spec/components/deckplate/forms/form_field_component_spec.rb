require "spec_helper"

RSpec.describe Deckplate::Forms::FormFieldComponent, type: :component do
  def render_field(**opts, &block)
    render_inline(described_class.new(control_id: "ship_name", label: "Name", **opts), &(block || proc { '<input id="ship_name">'.html_safe }))
  end

  it "renders the label associated with the control, and the control" do
    render_field
    expect(page).to have_css(".dp-field label.dp-field__label[for='ship_name']", text: "Name")
    expect(page).to have_css(".dp-field .dp-field__control input#ship_name")
    expect(page).not_to have_css(".dp-field__hint")
    expect(page).not_to have_css(".dp-field__error")
  end

  describe "required" do
    it "shows a visual marker hidden from assistive tech, and a text alternative for them" do
      render_field(required: true)
      expect(page).to have_css("label .dp-field__required[aria-hidden='true']", text: "*")
      expect(page).to have_css("label .dp-sr-only", text: "required")
    end

    it "translates the text alternative" do
      I18n.with_locale(:fr) { render_field(required: true) }
      expect(page).to have_css("label .dp-sr-only", text: "obligatoire")
    end

    it "shows nothing when optional" do
      render_field
      expect(page).not_to have_css(".dp-field__required")
    end
  end

  describe "hint" do
    it "renders the hint with the id the control points to" do
      render_field(hint: "As on the registry")
      expect(page).to have_css("p.dp-field__hint#ship_name-hint", text: "As on the registry")
    end
  end

  describe "errors" do
    it "lists every error with an icon and a text prefix, never colour alone" do
      render_field(errors: [ "can't be blank", "is too short" ])
      error = page.find("#ship_name-error")
      expect(error[:class]).to include("dp-field__error")
      expect(error).to have_css("svg.dp-icon[aria-hidden='true']")
      expect(error).to have_css(".dp-sr-only", text: "Error")
      expect(error).to have_css("li", count: 2)
      expect(error.text).to include("can't be blank", "is too short")
      expect(page).to have_css(".dp-field.dp-field--invalid")
    end

    it "translates the error prefix" do
      I18n.with_locale(:fr) { render_field(errors: [ "est vide" ]) }
      expect(page).to have_css(".dp-field__error .dp-sr-only", text: "Erreur")
    end

    it "uses role=alert only when asked (the first invalid field of a form)" do
      render_field(errors: [ "bad" ])
      expect(page).not_to have_css("[role='alert']")
      render_field(errors: [ "bad" ], alert: true)
      expect(page).to have_css("#ship_name-error[role='alert']")
    end

    it "accepts a single String and ignores blanks" do
      render_field(errors: "bad")
      expect(page).to have_css("#ship_name-error li", count: 1)
      render_field(errors: [ "", nil ])
      expect(page).not_to have_css(".dp-field__error")
    end
  end

  describe "as a fieldset" do
    it "renders fieldset and legend for groups of controls" do
      render_inline(described_class.new(control_id: "role", label: "Role", as: :fieldset, hint: "Pick one", errors: [ "bad" ])) { "radios" }
      expect(page).to have_css("fieldset.dp-field legend.dp-field__label", text: "Role")
      expect(page).not_to have_css("label.dp-field__label")
      fs = page.find("fieldset")
      expect(fs["aria-describedby"]).to eq("role-hint role-error")
    end
  end

  it "puts the hint after the control when the control draws its own label (nothing above it to describe)" do
    render_inline(described_class.new(control_id: "c", label: nil, hint: "Applies to the next jump")) { "CONTROL" }
    html = page.native.to_html
    expect(html.index("CONTROL")).to be < html.index("Applies to the next jump")
    render_inline(described_class.new(control_id: "c", label: "L", hint: "H")) { "CONTROL" }
    html = page.native.to_html
    expect(html.index("H</p>")).to be < html.index("CONTROL")
  end

  it "has no label element when the control draws its own (checkbox)" do
    render_inline(described_class.new(control_id: "c", label: nil)) { "x" }
    expect(page).not_to have_css("label")
  end

  it "wires dp-field, which protects what the user typed from a Turbo morph" do
    render_field
    field = page.find(".dp-field")
    expect(field["data-controller"]).to eq("dp-field")
    expect(field["data-action"]).to include("input->dp-field#touch", "change->dp-field#touch", "turbo:before-morph-attribute->dp-field#keepState")
  end

  it "passes class and data through to the wrapper" do
    render_field(class: "x", data: { a: 1 })
    expect(page).to have_css(".dp-field.x[data-a='1']")
  end

  it "rejects invalid input" do
    expect { described_class.new(control_id: "", label: "L") }.to raise_error(ArgumentError, /control_id/)
    expect { described_class.new(control_id: "c", label: "L", as: :table) }.to raise_error(ArgumentError, /as.*div, fieldset/)
  end
end
