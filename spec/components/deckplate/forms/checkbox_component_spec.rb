require "spec_helper"

RSpec.describe Deckplate::Forms::CheckboxComponent, type: :component do
  def build(**opts) = described_class.new(name: "ship[callsign]", label: "Callsign", **opts)
  let(:control_css) { "input[type='checkbox'].dp-choice__input" }

  it_behaves_like "a form control"

  it "wraps the box and the label text in one label, so the whole row is clickable" do
    render_inline(build)
    expect(page).to have_css("label.dp-choice input[type='checkbox'] ~ .dp-choice__mark[aria-hidden='true']", visible: :all)
    expect(page).to have_css("label.dp-choice .dp-choice__text", text: "Callsign")
  end

  it "is unchecked by default, can be checked, and submits 1 or a custom value" do
    render_inline(build)
    expect(page.find("input[type='checkbox']", visible: :all)).not_to be_checked
    expect(page.find("input[type='checkbox']", visible: :all)[:value]).to eq("1")
    render_inline(build(checked: true, value: "yes"))
    expect(page.find("input[type='checkbox']", visible: :all)).to be_checked
    expect(page.find("input[type='checkbox']", visible: :all)[:value]).to eq("yes")
  end

  it "adds a hidden field for the unchecked value, like Rails' check_box" do
    render_inline(build(unchecked_value: "0"))
    expect(page).to have_css("input[type='hidden'][name='ship[callsign]'][value='0']", visible: :all)
  end
end
