require "spec_helper"

RSpec.describe Deckplate::Layout::SectionComponent, type: :component do
  it "renders a titled section with its body" do
    render_inline(described_class.new(title: "Status")) { "Body text" }
    expect(page).to have_css("section.dp-section.dp-c-secondary h2.dp-section__title", text: "Status")
    expect(page).to have_css(".dp-section__body", text: "Body text")
  end

  it "names the section by its heading when an id is given" do
    render_inline(described_class.new(title: "Status", id: "status")) { "x" }
    expect(page).to have_css("section#status[aria-labelledby='status-title'] #status-title", text: "Status")
  end

  it "leaves the section unnamed (no dangling aria-labelledby) without an id" do
    render_inline(described_class.new(title: "Status")) { "x" }
    expect(page).not_to have_css("[aria-labelledby]")
  end

  it "is render-pure: same inputs, same HTML" do
    a = render_inline(described_class.new(title: "S", id: "s")) { "x" }.to_html
    b = render_inline(described_class.new(title: "S", id: "s")) { "x" }.to_html
    expect(a).to eq(b)
  end

  it "supports colour and heading level" do
    render_inline(described_class.new(title: "T", color: :info, level: 3)) { "x" }
    expect(page).to have_css("section.dp-c-info h3.dp-section__title")
  end

  it "passes html options through" do
    render_inline(described_class.new(title: "T", class: "x", data: { a: 1 })) { "x" }
    expect(page).to have_css("section.dp-section.x[data-a='1']")
  end

  it "rejects missing titles, bad levels and unknown colours" do
    expect { described_class.new(title: "") }.to raise_error(ArgumentError, /title/)
    expect { described_class.new(title: "T", level: 0) }.to raise_error(ArgumentError, /level/)
    expect { described_class.new(title: "T", color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
