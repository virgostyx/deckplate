require "spec_helper"

RSpec.describe Deckplate::SliderComponent, type: :component do
  def input = page.find("input[type='range']", visible: :all)

  it "renders a native range input with a visible label and a live value readout" do
    render_inline(described_class.new(name: "power", label: "Power", min: 0, max: 100, value: 72))
    expect(page).to have_css(".dp-slider[data-controller='dp-slider']", visible: :all)
    expect(page).to have_css("label.dp-slider__label", text: "Power")
    expect(input[:name]).to eq("power")
    expect(input[:min]).to eq("0")
    expect(input[:max]).to eq("100")
    expect(input[:value]).to eq("72")
    expect(page).to have_css("output.dp-slider__value", text: "72")
  end

  it "associates the label and the output with the input" do
    render_inline(described_class.new(name: "power", label: "Power", value: 10))
    id = input[:id]
    expect(id).to eq("power-slider")
    expect(page.find("label")[:for]).to eq(id)
    expect(page.find("output")[:for]).to eq(id)
  end

  it "wires the controller targets and action" do
    render_inline(described_class.new(name: "p", label: "P", value: 1))
    expect(input["data-dp-slider-target"]).to eq("input")
    expect(input["data-action"]).to eq("input->dp-slider#update")
    expect(page.find("output", visible: :all)["data-dp-slider-target"]).to eq("output")
  end

  it "supports step and defaults to 0..100" do
    render_inline(described_class.new(name: "p", label: "P", step: 5))
    expect([ input[:min], input[:max], input[:step] ]).to eq(%w[0 100 5])
    expect(input[:value]).to eq("0")
  end

  it "can hide the readout (the value is still available to assistive tech through the input)" do
    render_inline(described_class.new(name: "p", label: "P", show_value: false))
    expect(page).not_to have_css("output", visible: :all)
  end

  it "shows a unit next to the readout" do
    render_inline(described_class.new(name: "p", label: "P", value: 3, unit: "%"))
    expect(page).to have_css("output", text: "3%")
    expect(page).to have_css(".dp-slider[data-dp-slider-unit-value='%']", visible: :all)
  end

  it "can be disabled and coloured; passes html options to the wrapper" do
    render_inline(described_class.new(name: "p", label: "P", disabled: true, color: :info, class: "x"))
    expect(input[:disabled]).not_to be_nil
    expect(page).to have_css(".dp-slider.dp-c-info.x", visible: :all)
  end

  it "merges input_html into the native input (class, data, aria), keeping the controller wiring" do
    render_inline(described_class.new(name: "p", label: "P", value: 1,
      input_html: { class: "extra", data: { action: "focus->x#y", foo: 1 }, aria: { invalid: "true", describedby: "p-hint" }, required: true }))
    expect(input[:class].split).to include("dp-slider__input", "extra")
    expect(input["data-action"]).to eq("input->dp-slider#update focus->x#y")
    expect(input["data-foo"]).to eq("1")
    expect(input["aria-invalid"]).to eq("true")
    expect(input["aria-describedby"]).to eq("p-hint")
    expect(input[:required]).not_to be_nil
    expect(input["data-dp-slider-target"]).to eq("input")
  end

  it "rejects inconsistent input" do
    expect { described_class.new(name: "", label: "P") }.to raise_error(ArgumentError, /name/)
    expect { described_class.new(name: "p", label: "") }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(name: "p", label: "P", min: 10, max: 5) }.to raise_error(ArgumentError, /min.*max/)
    expect { described_class.new(name: "p", label: "P", step: 0) }.to raise_error(ArgumentError, /step/)
    expect { described_class.new(name: "p", label: "P", value: 500) }.to raise_error(ArgumentError, /value/)
    expect { described_class.new(name: "p", label: "P", color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
