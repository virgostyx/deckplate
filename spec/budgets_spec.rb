require "spec_helper"
require_relative "../tools/budgets"

RSpec.describe DeckplateBuild::Budgets do
  subject(:rows) { described_class.new(Deckplate::Engine.root).rows }

  KB = 1024

  it "measures every stylesheet, the JavaScript and the fonts" do
    names = rows.map(&:name)
    %w[core controls forms data feedback].each do |sheet|
      expect(names).to include("CSS #{sheet} raw", "CSS #{sheet} gzip")
    end
    expect(names).to include("CSS all-in-one raw", "CSS all-in-one gzip", "JS raw", "JS gzip", "Fonts (woff2)")
    expect(rows.map(&:size)).to all(be > 0)
  end

  it "stays within the SPEC section 12 budgets (raise one only with an ADR)" do
    over = rows.reject(&:ok?).map { |r| "#{r.name}: #{r.size} B > #{r.limit} B" }
    expect(over).to eq([])
  end

  it "uses the per-sheet limits of ADR 0012" do
    limits = rows.to_h { [ _1.name, _1.limit ] }
    expect(limits).to include(
      "CSS core raw" => 50 * KB, "CSS core gzip" => 9 * KB,
      "CSS controls raw" => 25 * KB, "CSS controls gzip" => 5 * KB,
      "CSS forms raw" => 25 * KB, "CSS data raw" => 25 * KB, "CSS feedback raw" => 25 * KB,
      "CSS data gzip" => 5 * KB, "CSS forms gzip" => 5 * KB, "CSS feedback gzip" => 5 * KB,
      "CSS all-in-one raw" => 120 * KB, "CSS all-in-one gzip" => 20 * KB,
      "JS raw" => 20 * KB, "JS gzip" => 6 * KB, "Fonts (woff2)" => 90 * KB
    )
  end
end
