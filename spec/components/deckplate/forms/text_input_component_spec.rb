require "spec_helper"

RSpec.describe Deckplate::Forms::TextInputComponent, type: :component do
  def build(**opts) = described_class.new(name: "ship[callsign]", label: "Callsign", **opts)
  let(:control_css) { "input.dp-input" }

  it_behaves_like "a form control"

  it "renders a text input with the current value by default" do
    render_inline(build(value: "NCC-1"))
    expect(page).to have_css("input.dp-input[type='text'][value='NCC-1']")
  end

  it "supports the textual input types" do
    %i[text email password number search tel url].each do |type|
      render_inline(build(type:))
      expect(page).to have_css("input[type='#{type}']")
    end
  end

  it "never echoes a password back into the page" do
    render_inline(build(type: :password, value: "secret"))
    expect(page.find("input[type='password']")[:value]).to be_nil
    expect(page.native.to_html).not_to include("secret")
  end

  it "passes native attributes through to the input (placeholder, autocomplete, min/max/step, maxlength)" do
    render_inline(build(type: :number, min: 0, max: 9, step: 1, placeholder: "p", autocomplete: "off", maxlength: 3, inputmode: "numeric"))
    input = page.find("input")
    expect([ input[:min], input[:max], input[:step], input[:placeholder], input[:autocomplete], input[:maxlength], input[:inputmode] ]).to eq(%w[0 9 1 p off 3 numeric])
  end

  it "can be read-only" do
    render_inline(build(readonly: true))
    expect(page.find("input")[:readonly]).not_to be_nil
  end

  it "rejects an unknown type" do
    expect { build(type: :color) }.to raise_error(ArgumentError, /type.*text, email, password, number, search, tel, url/)
  end
end
