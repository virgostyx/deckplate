require "spec_helper"
require_relative "../tools/budgets"

RSpec.describe DeckplateBuild::Budgets do
  subject(:rows) { described_class.new(Deckplate::Engine.root).rows }

  it "measures CSS, JS and fonts" do
    expect(rows.map(&:name)).to eq([ "CSS raw", "CSS gzip", "JS raw", "JS gzip", "Fonts (woff2)" ])
    expect(rows.map(&:size)).to all(be > 0)
  end

  it "stays within the SPEC section 12 budgets (raise one only with an ADR)" do
    over = rows.reject(&:ok?).map { |r| "#{r.name}: #{r.size} B > #{r.limit} B" }
    expect(over).to eq([])
  end

  it "uses the SPEC limits" do
    limits = rows.to_h { [ _1.name, _1.limit ] }
    expect(limits).to eq("CSS raw" => 60 * 1024, "CSS gzip" => 12 * 1024, "JS raw" => 20 * 1024, "JS gzip" => 6 * 1024, "Fonts (woff2)" => 90 * 1024)
  end
end
