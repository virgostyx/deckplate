require "spec_helper"

RSpec.describe Deckplate::Feedback::SkeletonComponent, type: :component do
  it "renders placeholder lines, hidden from assistive technology, with one status text" do
    render_inline(described_class.new(lines: 3))
    expect(page).to have_css(".dp-skeleton[role='status']")
    expect(page).to have_css(".dp-skeleton__shape[aria-hidden='true']", count: 3)
    expect(page).to have_css(".dp-skeleton .dp-sr-only", text: "Loading")
  end

  it "supports text, block and circle shapes" do
    %i[text block circle].each do |shape|
      render_inline(described_class.new(shape:))
      expect(page).to have_css(".dp-skeleton--#{shape}")
    end
  end

  it "translates the text, or takes a label" do
    I18n.with_locale(:fr) { render_inline(described_class.new) }
    expect(page).to have_css(".dp-sr-only", text: "Chargement")
    render_inline(described_class.new(label: "Loading crew"))
    expect(page).to have_css(".dp-sr-only", text: "Loading crew")
  end

  it "passes html options through" do
    render_inline(described_class.new(class: "x", id: "sk"))
    expect(page).to have_css("#sk.dp-skeleton.x")
  end

  it "rejects invalid input" do
    expect { described_class.new(lines: 0) }.to raise_error(ArgumentError, /lines/)
    expect { described_class.new(lines: 21) }.to raise_error(ArgumentError, /lines/)
    expect { described_class.new(shape: :star) }.to raise_error(ArgumentError, /shape.*text, block, circle/)
  end
end
