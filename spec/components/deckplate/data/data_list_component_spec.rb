require "spec_helper"

RSpec.describe Deckplate::Data::DataListComponent, type: :component do
  it "renders key/value pairs as a description list" do
    render_inline(described_class.new(items: [ [ "Class", "Explorer" ], [ "Crew", 212 ] ]))
    expect(page).to have_css("dl.dp-data-list dt", count: 2)
    expect(page).to have_css("dt", text: "Class")
    expect(page).to have_css("dd", text: "Explorer")
    expect(page).to have_css("dd", text: "212")
  end

  it "accepts a Hash and escapes values" do
    render_inline(described_class.new(items: { "A" => "<b>x</b>" }))
    expect(page).to have_css("dt", text: "A")
    expect(page.native.to_html).to include("&lt;b&gt;x&lt;/b&gt;")
  end

  it "accepts items from slots, with rich content" do
    render_inline(described_class.new) do |l|
      l.with_item(label: "Status") { '<span class="pill">OK</span>'.html_safe }
      l.with_item(label: "Deck") { "7" }
    end
    expect(page).to have_css("dt", text: "Status")
    expect(page).to have_css("dd .pill", text: "OK")
    expect(page).to have_css("dd", text: "7")
  end

  it "keeps each term next to its description in the markup" do
    render_inline(described_class.new(items: [ %w[A 1], %w[B 2] ]))
    expect(page.all("dl > *").map(&:tag_name)).to eq(%w[dt dd dt dd])
  end

  it "renders nothing when there is nothing to show" do
    render_inline(described_class.new(items: []))
    expect(page).not_to have_css("dl")
  end

  it "applies a colour and passes html options through" do
    render_inline(described_class.new(items: [ %w[A 1] ], color: :tertiary, class: "x", id: "d"))
    expect(page).to have_css("dl#d.dp-data-list.dp-c-tertiary.x")
  end

  it "rejects malformed items and unknown colours" do
    expect { described_class.new(items: [ [ "only one" ] ]) }.to raise_error(ArgumentError, /item/)
    expect { described_class.new(items: [ [ "", "x" ] ]) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(items: [], color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
