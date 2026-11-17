require "spec_helper"

# app/assets/tailwind/deckplate/engine.css is picked up by tailwindcss-rails (ADR 0001): `bg-dp-primary`, `text-dp-ink`, ... without any host config.
RSpec.describe "Tailwind bridge" do
  let(:path) { Deckplate::Engine.root.join("app/assets/tailwind/deckplate/engine.css") }
  let(:css) { File.read(path) }
  let(:roles) { %w[primary secondary tertiary accent muted info success warning danger emergency] }
  let(:neutrals) { %w[canvas surface surface-raised ink ink-muted line focus disabled] }

  it "maps every role, its ink and every neutral to a Tailwind colour, by reference (so themes keep working)" do
    (roles.flat_map { [ _1, "#{_1}-ink" ] } + neutrals).each do |name|
      expect(css).to match(/--color-dp-#{Regexp.escape(name)}:\s*var\(--dp-#{Regexp.escape(name)}\);/), "missing #{name}"
    end
  end

  it "maps the three font families" do
    %w[display data text].each { expect(css).to match(/--font-dp-#{_1}:\s*var\(--dp-font-#{_1}\);/) }
  end

  it "uses @theme inline (values stay live CSS variables) and nothing else" do
    expect(css).to include("@theme inline {")
    expect(css.gsub(%r{/\*.*?\*/}m, "").gsub(/@theme inline \{.*\}/m, "").strip).to eq("")
  end

  it "is shipped in the gem" do
    spec = Gem::Specification.load(Deckplate::Engine.root.join("deckplate.gemspec").to_s)
    expect(spec.files).to include("app/assets/tailwind/deckplate/engine.css")
  end
end
