require "spec_helper"

RSpec.describe Deckplate::Forms::SelectComponent, type: :component do
  def build(**opts) = described_class.new(name: "ship[callsign]", label: "Callsign", options: [ [ "Alpha", "a" ], [ "Beta", "b" ] ], **opts)
  let(:control_css) { "select.dp-input" }

  it_behaves_like "a form control"

  it "renders options from [label, value] pairs, plain strings and Symbols" do
    render_inline(build(options: [ [ "Alpha", "a" ], "Beta", :gamma ]))
    options = page.all("option").map { [ _1.text, _1[:value] ] }
    expect(options).to eq([ %w[Alpha a], %w[Beta Beta], %w[gamma gamma] ])
  end

  it "selects the given value" do
    render_inline(build(value: "b"))
    expect(page.find("option[value='b']")[:selected]).not_to be_nil
    expect(page.find("option[value='a']")[:selected]).to be_nil
  end

  it "can start with a blank option showing the translated prompt, or a custom one" do
    render_inline(build(include_blank: true))
    first = page.all("option").first
    expect([ first[:value], first.text ]).to eq([ "", "Select…" ])
    render_inline(build(include_blank: "Pick a ship"))
    expect(page.all("option").first.text).to eq("Pick a ship")
    I18n.with_locale(:fr) { render_inline(build(include_blank: true)) }
    expect(page.all("option").first.text).to eq("Choisir…")
  end

  it "groups options" do
    render_inline(build(options: { "Fast" => [ [ "Alpha", "a" ] ], "Slow" => [ [ "Beta", "b" ] ] }))
    expect(page.all("optgroup").map { _1[:label] }).to eq(%w[Fast Slow])
    expect(page).to have_css("optgroup[label='Slow'] option[value='b']")
  end

  it "escapes labels" do
    render_inline(build(options: [ [ "<script>x</script>", "x" ] ]))
    expect(page.native.to_html).not_to include("<script>")
  end

  it "rejects missing options" do
    expect { build(options: nil) }.to raise_error(ArgumentError, /options/)
  end
end
