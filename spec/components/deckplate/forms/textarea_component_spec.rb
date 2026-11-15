require "spec_helper"

RSpec.describe Deckplate::Forms::TextareaComponent, type: :component do
  def build(**opts) = described_class.new(name: "ship[callsign]", label: "Callsign", **opts)
  let(:control_css) { "textarea.dp-input" }

  it_behaves_like "a form control"

  it "renders the value as content, escaped" do
    render_inline(build(value: "Line 1\n<b>2</b>"))
    area = page.find("textarea")
    expect(area.value).to eq("Line 1\n<b>2</b>")
    expect(page.native.to_html).not_to include("<b>2</b></textarea>")
  end

  it "has 4 rows by default and accepts rows and maxlength" do
    render_inline(build)
    expect(page.find("textarea")[:rows]).to eq("4")
    render_inline(build(rows: 8, maxlength: 200))
    expect([ page.find("textarea")[:rows], page.find("textarea")[:maxlength] ]).to eq(%w[8 200])
  end
end
