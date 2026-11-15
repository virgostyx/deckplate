require "spec_helper"

RSpec.describe Deckplate::Forms::FormActionsComponent, type: :component do
  it "groups the submit and cancel controls in a row" do
    render_inline(described_class.new) { '<button>Save</button><a href="/">Cancel</a>'.html_safe }
    expect(page).to have_css("div.dp-form-actions.dp-form-actions--start button", text: "Save")
    expect(page).to have_css(".dp-form-actions a", text: "Cancel")
  end

  it "can align to the end" do
    render_inline(described_class.new(align: :end)) { "x" }
    expect(page).to have_css(".dp-form-actions--end")
  end

  it "passes html options through" do
    render_inline(described_class.new(class: "x", data: { a: 1 })) { "x" }
    expect(page).to have_css(".dp-form-actions.x[data-a='1']")
  end

  it "rejects an invalid alignment" do
    expect { described_class.new(align: :middle) }.to raise_error(ArgumentError, /align.*start, end/)
  end
end
