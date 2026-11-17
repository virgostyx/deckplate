require "spec_helper"
require "json"
require_relative "../tools/tokens_exporter"

# config/deckplate/tokens.json: the palette, the three font families and every theme, in the W3C design tokens format
# (Style Dictionary 4, Tokens Studio, Figma variables imports). Generated from the same sources as the CSS: never edited by hand.
RSpec.describe "Design tokens export" do
  let(:root) { Deckplate::Engine.root }
  let(:exporter) { DeckplateBuild::TokensExporter.new(root) }
  let(:tokens) { JSON.parse(root.join(DeckplateBuild::TokensExporter::PATH).read).fetch("dp") }
  let(:themes) { Deckplate::Configuration::BUILT_IN_THEMES.map(&:to_s) }

  it "is up to date with its sources (run bin/build-css)" do
    expect(root.join(DeckplateBuild::TokensExporter::PATH).read).to eq(exporter.json), "tokens.json is stale: run bin/build-css"
  end

  it "ships in the gem" do
    spec = Gem::Specification.load(root.join("deckplate.gemspec").to_s)
    expect(spec.files).to include("config/deckplate/tokens.json")
  end

  describe "palette" do
    it "has every stop and its ink as a colour token with the exact hex of palette.yml" do
      CssVars.palette.each do |name, stop|
        expect(tokens.dig("palette", name)).to include("$type" => "color", "$value" => stop["hex"].upcase)
        expect(tokens.dig("palette", "#{name}-ink", "$value")).to eq(stop["ink"].upcase)
      end
    end

    it "marks background-only stops (never to be used as text or line colour)" do
      flagged = CssVars.palette.select { |_, s| s["background_only"] }.keys
      expect(flagged).not_to be_empty
      flagged.each { expect(tokens.dig("palette", _1, "$extensions", "dp", "backgroundOnly")).to be(true) }
      (CssVars.palette.keys - flagged).each { expect(tokens.dig("palette", _1, "$extensions")).to be_nil }
    end
  end

  describe "themes" do
    it "exports every built-in theme" do
      expect(tokens.fetch("theme").keys).to match_array(themes)
    end

    it "defines the same tokens as the CSS themes, none more, none less" do
      themes.each do |theme|
        css_names = CssVars.theme_vars(theme).keys.map { _1.delete_prefix("--dp-") }
        expect(tokens.dig("theme", theme).keys).to match_array(css_names), "theme #{theme}"
      end
    end

    it "resolves, for every theme and token, to exactly the colour the CSS resolves to" do
      themes.each do |theme|
        css = CssVars.stop_vars.merge(CssVars.theme_vars(theme))
        tokens.dig("theme", theme).each do |name, token|
          expect(token["$type"]).to eq("color")
          expect(resolve(token["$value"], tokens, theme)).to eq(CssVars.resolve(css.fetch("--dp-#{name}"), css)), "#{theme}.#{name}"
        end
      end
    end

    it "uses aliases to the palette where the CSS uses a palette variable, and literal hex where the CSS does (no dangling reference)" do
      themes.each do |theme|
        css = CssVars.theme_vars(theme)
        tokens.dig("theme", theme).each do |name, token|
          raw = css.fetch("--dp-#{name}")
          if raw.start_with?("var(")
            expect(token["$value"]).to match(/\A\{dp\.palette\.[a-z0-9-]+\}\z/)
            expect(lookup(tokens, token["$value"])).not_to be_nil, "#{theme}.#{name} -> #{token['$value']}"
          else
            expect(token["$value"]).to eq(raw.upcase)
          end
        end
      end
    end
  end

  describe "fonts" do
    it "exports the three families as font stacks equal to the CSS custom properties" do
      foundation = File.read(root.join("app/assets/stylesheets/deckplate/foundation.css"))
      %w[display data text].each do |kind|
        css_stack = foundation[/--dp-font-#{kind}:\s*([^;]+);/, 1].split(",").map { _1.strip.delete('"') }
        expect(tokens.dig("font", kind)).to eq("$type" => "fontFamily", "$value" => css_stack)
      end
    end
  end

  it "does not export values that depend on the cascade (geometry uses calc and var): colours and fonts only" do
    expect(tokens.keys).to match_array(%w[palette font theme])
  end

  def lookup(tokens, ref)
    ref.delete("{}").delete_prefix("dp.").split(".").reduce(tokens) { |node, key| node.is_a?(Hash) ? node[key] : nil }
  end

  # Follows {dp.palette.x} aliases to a hex string
  def resolve(value, tokens, theme)
    return value unless value.start_with?("{")

    target = lookup(tokens, value)
    resolve(target["$value"], tokens, theme)
  end
end
