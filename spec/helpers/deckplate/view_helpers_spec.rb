require "spec_helper"

RSpec.describe Deckplate::Helpers, type: :helper do
  after { Deckplate.reset_configuration! }

  describe "#dp_theme_attrs" do
    it "returns the default theme when there is no cookie" do
      expect(helper.dp_theme_attrs).to eq(data: { dp_theme: "classic" })
    end

    it "honours the configured default theme" do
      Deckplate.configure { |c| c.default_theme = :azure }
      expect(helper.dp_theme_attrs).to eq(data: { dp_theme: "azure" })
    end

    it "reads the dp_theme cookie so the first paint is correct" do
      helper.request.cookies["dp_theme"] = "daylight"
      expect(helper.dp_theme_attrs).to eq(data: { dp_theme: "daylight" })
    end

    it "ignores a cookie naming a theme that is not enabled" do
      helper.request.cookies["dp_theme"] = "evil\"><script>"
      expect(helper.dp_theme_attrs).to eq(data: { dp_theme: "classic" })
    end

    it "renders as attributes through tag.attributes" do
      expect(helper.tag.attributes(helper.dp_theme_attrs)).to eq('data-dp-theme="classic"')
    end
  end

  describe "#dp_root" do
    it "wraps content in a .dp-root div" do
      html = Nokogiri::HTML.fragment(helper.dp_root { "hi" })
      el = html.at_css("div.dp-root")
      expect(el.text).to eq("hi")
      expect(el["data-dp-theme"]).to be_nil
    end

    it "merges classes and attributes, and can pin a nested theme" do
      html = Nokogiri::HTML.fragment(helper.dp_root(theme: :crimson, class: "x", id: "r", tag: :section) { "a" })
      el = html.at_css("section.dp-root.x")
      expect(el["id"]).to eq("r")
      expect(el["data-dp-theme"]).to eq("crimson")
    end

    it "rejects a theme that is not enabled" do
      expect { helper.dp_root(theme: :bogus) { "" } }.to raise_error(ArgumentError, /theme/)
    end
  end

  describe "#dp_color_class" do
    it "returns the CSS class for a role or palette stop" do
      expect(helper.dp_color_class(:primary)).to eq("dp-c-primary")
      expect(helper.dp_color_class(:neon_carrot)).to eq("dp-c-neon-carrot")
    end

    it "raises on an unknown colour when strict" do
      expect { helper.dp_color_class(:nope) }.to raise_error(ArgumentError, /unknown colour/)
    end
  end

  describe "#dp_icon" do
    Deckplate::Helpers::ICONS.each_key do |name|
      it "renders #{name} as a decorative inline svg" do
        svg = Nokogiri::HTML.fragment(helper.dp_icon(name)).at_css("svg.dp-icon")
        expect(svg["aria-hidden"]).to eq("true")
        expect(svg["focusable"]).to eq("false")
        expect(helper.dp_icon(name)).to include('viewBox="0 0 24 24"') # raw string: HTML parsers lowercase attribute names
        expect(svg.css("path").size).to be >= 1
      end
    end

    it "ships at least the icons the plan lists" do
      expect(Deckplate::Helpers::ICONS.keys).to include(:close, :chevron_left, :chevron_right, :chevron_up, :chevron_down,
        :check, :alert, :info, :menu, :search, :plus, :minus, :sort_asc, :sort_desc, :external)
    end

    it "becomes an accessible image when a title is given" do
      svg = Nokogiri::HTML.fragment(helper.dp_icon(:info, title: "Information")).at_css("svg")
      expect(svg["role"]).to eq("img")
      expect(svg["aria-hidden"]).to be_nil
      expect(svg.at_css("title").text).to eq("Information")
    end

    it "passes class and data through" do
      svg = Nokogiri::HTML.fragment(helper.dp_icon(:plus, class: "big", data: { x: 1 })).at_css("svg")
      expect(svg["class"].split).to include("dp-icon", "big")
      expect(svg["data-x"]).to eq("1")
    end

    it "raises with the list of names for an unknown icon" do
      expect { helper.dp_icon(:nope) }.to raise_error(ArgumentError, /unknown icon :nope.*close/)
    end
  end
end
