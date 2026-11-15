# Behaviour every Deckplate form control must have. The including spec defines:
#   def build(**opts)  -> a component with name "ship[callsign]" and label "Callsign" (opts override)
#   let(:control_css)  -> CSS selector of the native control inside the rendered field
RSpec.shared_examples "a form control" do |supports_required: true| # a range always has a value: `required` means nothing for it
  def control = page.find(control_css, visible: :all)
  def render_control(**opts, &block) = render_inline(build(**opts), &block)

  it "associates the label with the control through for/id, deriving the id from the Rails-style name" do
    render_control
    expect(control[:id]).to eq("ship_callsign")
    expect(page).to have_css("label[for='ship_callsign']", text: "Callsign", visible: :all)
    expect(control[:name]).to eq("ship[callsign]") unless control[:type] == "radio"
  end

  it "lets the caller choose the id" do
    render_control(id: "custom-id")
    expect(page).to have_css("#{control_css}#custom-id, label[for='custom-id']", visible: :all)
    expect(page).to have_css("label[for='custom-id']", visible: :all)
  end

  it "renders no hint, no error and no aria-invalid when the field is valid" do
    render_control
    expect(page).not_to have_css(".dp-field__hint", visible: :all)
    expect(page).not_to have_css(".dp-field__error", visible: :all)
    expect(control["aria-invalid"]).to be_nil
    expect(control["aria-describedby"]).to be_nil
  end

  it "points the control at its hint" do
    render_control(hint: "Three letters")
    expect(page).to have_css("#ship_callsign-hint.dp-field__hint", text: "Three letters", visible: :all)
    expect(control["aria-describedby"]).to eq("ship_callsign-hint")
  end

  it "flags the control invalid and points it at the error (and the hint, in that order)" do
    render_control(hint: "Three letters", errors: [ "can't be blank" ])
    expect(control["aria-invalid"]).to eq("true")
    expect(control["aria-describedby"]).to eq("ship_callsign-hint ship_callsign-error")
    expect(page).to have_css("#ship_callsign-error.dp-field__error", text: "can't be blank", visible: :all)
    expect(page).to have_css(".dp-field--invalid", visible: :all)
  end

  it "marks the first invalid field of a form as an alert when asked" do
    render_control(errors: [ "bad" ], alert: true)
    expect(page).to have_css("#ship_callsign-error[role='alert']", visible: :all)
  end

  it "marks the field required, visually and for assistive tech" do
    skip "required does not apply to this control" unless supports_required
    render_control(required: true)
    expect(control[:required]).not_to be_nil
    expect(page).to have_css("label .dp-field__required[aria-hidden='true'], legend .dp-field__required[aria-hidden='true']", visible: :all)
    expect(page).to have_css(".dp-sr-only", text: "required", visible: :all)
  end

  it "can be disabled" do
    render_control(disabled: true)
    expect(control[:disabled]).not_to be_nil
  end

  it "passes class and data to the control and adds to its aria-describedby instead of replacing it" do
    render_control(hint: "H", class: "extra", data: { turbo_permanent: true }, aria: { describedby: "mine" })
    expect(control[:class].split).to include("extra")
    expect(control["data-turbo-permanent"]).to eq("true")
    expect(control["aria-describedby"]).to eq("ship_callsign-hint mine")
  end

  it "needs a name and a label" do
    expect { build(name: "") }.to raise_error(ArgumentError, /name/)
    expect { build(label: "") }.to raise_error(ArgumentError, /label/)
  end

  it "is render-pure" do
    expect(render_control(hint: "h", errors: [ "e" ]).to_html).to eq(render_control(hint: "h", errors: [ "e" ]).to_html)
  end
end
