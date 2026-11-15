require "spec_helper"

RSpec.describe Deckplate::ToggleComponent, type: :component do
  def input = page.find("input.dp-toggle__input", visible: :all)

  it "renders a native checkbox with the switch role, wrapped by its label" do
    render_inline(described_class.new(name: "ship[shields]", label: "Shields"))
    expect(page).to have_css("label.dp-toggle input[type='checkbox'][role='switch'][name='ship[shields]']", visible: :all)
    expect(page).to have_css("label.dp-toggle .dp-toggle__label", text: "Shields")
    expect(page).to have_css(".dp-toggle__track[aria-hidden='true'] .dp-toggle__thumb", visible: :all)
  end

  it "is unchecked by default and can be checked" do
    render_inline(described_class.new(name: "n", label: "L"))
    expect(input).not_to be_checked
    render_inline(described_class.new(name: "n", label: "L", checked: true))
    expect(input).to be_checked
  end

  it "submits value 1 by default, or a custom value" do
    render_inline(described_class.new(name: "n", label: "L"))
    expect(input[:value]).to eq("1")
    render_inline(described_class.new(name: "n", label: "L", value: "on"))
    expect(input[:value]).to eq("on")
  end

  it "sends an unchecked value through a hidden field when asked (Rails check_box style)" do
    render_inline(described_class.new(name: "n", label: "L", unchecked_value: "0"))
    hidden = page.find("input[type='hidden'][name='n']", visible: :all)
    expect(hidden[:value]).to eq("0")
  end

  it "can be disabled" do
    render_inline(described_class.new(name: "n", label: "L", disabled: true))
    expect(input[:disabled]).not_to be_nil
    expect(page).to have_css("label.dp-toggle--disabled")
  end

  it "takes the label from the block" do
    render_inline(described_class.new(name: "n")) { "Block label" }
    expect(page).to have_css(".dp-toggle__label", text: "Block label")
  end

  it "applies a colour and passes html options to the input" do
    render_inline(described_class.new(name: "n", label: "L", color: :success, class: "x", id: "t1", data: { a: 1 }))
    expect(page).to have_css("label.dp-toggle.dp-c-success", visible: :all)
    expect(page).to have_css("input#t1.x[data-a='1']", visible: :all)
  end

  it "needs a name and a label" do
    expect { described_class.new(name: "", label: "L") }.to raise_error(ArgumentError, /name/)
    expect { render_inline(described_class.new(name: "n")) }.to raise_error(ArgumentError, /label/)
  end

  it "rejects unknown colours" do
    expect { described_class.new(name: "n", label: "L", color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
