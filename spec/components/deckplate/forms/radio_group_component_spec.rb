require "spec_helper"

RSpec.describe Deckplate::Forms::RadioGroupComponent, type: :component do
  def build(**opts) = described_class.new(name: "ship[callsign]", label: "Callsign", options: [ [ "Alpha", "a" ], [ "Beta", "b" ], "Gamma ray" ], **opts)
  let(:control_css) { "input[type='radio']" }

  # A group has one legend and several controls: the shared examples run against the first radio / the fieldset.
  def control = page.all("input[type='radio']", visible: :all).first

  it "renders a fieldset named by its legend with one radio per option" do
    render_inline(build)
    expect(page).to have_css("fieldset.dp-field legend.dp-field__label", text: "Callsign")
    expect(page.all("input[type='radio']", visible: :all).map { _1[:value] }).to eq(%w[a b Gamma\ ray])
    expect(page.all("input[type='radio']", visible: :all).map { _1[:name] }.uniq).to eq([ "ship[callsign]" ])
  end

  it "labels each radio and gives unique, deterministic ids" do
    render_inline(build)
    ids = page.all("input[type='radio']", visible: :all).map { _1[:id] }
    expect(ids).to eq(%w[ship_callsign_a ship_callsign_b ship_callsign_gamma_ray])
    expect(page).to have_css("label.dp-choice[for='ship_callsign_b'] .dp-choice__text", text: "Beta", visible: :all)
  end

  it "checks the radio matching the value" do
    render_inline(build(value: "b"))
    expect(page.find("#ship_callsign_b", visible: :all)).to be_checked
    expect(page.find("#ship_callsign_a", visible: :all)).not_to be_checked
  end

  it "describes the whole group by its hint and errors (on the fieldset)" do
    render_inline(build(hint: "Pick one", errors: [ "can't be blank" ], alert: true))
    fs = page.find("fieldset")
    expect(fs["aria-describedby"]).to eq("ship_callsign-hint ship_callsign-error")
    expect(page).to have_css("#ship_callsign-error[role='alert']")
    expect(page.all("input[type='radio']", visible: :all).first["aria-invalid"]).to eq("true")
  end

  it "marks the group required for assistive tech through the legend, and the radios as required" do
    render_inline(build(required: true))
    expect(page).to have_css("legend .dp-field__required[aria-hidden='true']")
    expect(page).to have_css("legend .dp-sr-only", text: "required")
    expect(page.all("input[type='radio']", visible: :all).first[:required]).not_to be_nil
  end

  it "disables every radio" do
    render_inline(build(disabled: true))
    expect(page.all("input[type='radio']", visible: :all).map { _1[:disabled] }).to all(be_truthy)
  end

  it "supports stacked and inline layouts" do
    render_inline(build)
    expect(page).to have_css(".dp-radio-group--stack")
    render_inline(build(layout: :inline))
    expect(page).to have_css(".dp-radio-group--inline")
  end

  it "passes html options to the group wrapper and is render-pure" do
    render_inline(build(class: "x", data: { a: 1 }))
    expect(page).to have_css(".dp-radio-group.x[data-a='1']")
    expect(render_inline(build(errors: [ "e" ])).to_html).to eq(render_inline(build(errors: [ "e" ])).to_html)
  end

  it "rejects invalid input" do
    expect { build(name: "") }.to raise_error(ArgumentError, /name/)
    expect { build(label: "") }.to raise_error(ArgumentError, /label/)
    expect { build(options: []) }.to raise_error(ArgumentError, /options/)
    expect { build(layout: :grid) }.to raise_error(ArgumentError, /layout.*stack, inline/)
  end
end
