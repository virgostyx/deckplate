require "spec_helper"

RSpec.describe Deckplate::Helpers, type: :helper do
  describe "#dp_font_tags" do
    subject(:html) { Nokogiri::HTML.fragment(helper.dp_font_tags) }

    it "preloads the two latin fonts with the attributes browsers require" do
      links = html.css("link")
      expect(links.size).to eq(2)
      links.each do |l|
        expect(l["rel"]).to eq("preload")
        expect(l["as"]).to eq("font")
        expect(l["type"]).to eq("font/woff2")
        expect(l["crossorigin"]).to eq("anonymous")
      end
      expect(links.map { _1["href"] }).to match([ %r{/assets/deckplate/antonio-latin-\h+\.woff2}, %r{/assets/deckplate/share-tech-mono-latin-\h+\.woff2} ])
    end

    it "is html safe" do
      expect(helper.dp_font_tags).to be_html_safe
    end
  end

  it "is available in every view of the host app" do
    expect(ActionView::Base.included_modules).to include(described_class)
  end
end
