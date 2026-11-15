require "spec_helper"

RSpec.describe "base styles and scoping" do
  let(:css) { File.read(Deckplate::Engine.root.join("app/assets/stylesheets/deckplate.css")) }

  it "never styles bare elements or global selectors outside .dp-* / :root / [data-dp-theme] (SPEC 6.3)" do
    stripped = css.gsub(%r{/\*.*?\*/}m, "").gsub(/@font-face\s*\{.*?\}/m, "")
    selectors = stripped.scan(/([^{};]+)\{/).flatten.map(&:strip).reject { _1.start_with?("@") }
    offenders = selectors.flat_map { |s| s.split(",").map(&:strip) }
                         .reject { |s| s.match?(/\A(:root\z|\[data-dp-theme=|\.dp-)/) }
    expect(offenders).to eq([])
  end

  it "applies canvas colours and fonts only inside .dp-root" do
    expect(css).to match(/\.dp-root\s*\{[^}]*background(-color)?:\s*var\(--dp-canvas\)/m)
    expect(css).to match(/\.dp-root\s*\{[^}]*font-family:\s*var\(--dp-font-text\)/m)
  end

  it "draws a visible focus ring from --dp-focus" do
    expect(css).to match(/\.dp-root\s+:focus-visible\s*\{[^}]*outline:\s*2px solid var\(--dp-focus\)/m)
  end

  it "neutralises motion under prefers-reduced-motion" do
    block = css[/@media \(prefers-reduced-motion: reduce\)\s*\{.*?^\}/m]
    expect(block).to include("--dp-t-fast", "animation-duration", "transition-duration")
  end

  it "keeps focus visible in forced-colors mode" do
    expect(css).to match(/@media \(forced-colors: active\)/)
  end

  it "ships a screen-reader-only utility" do
    expect(css).to match(/\.dp-sr-only\s*\{[^}]*clip/m)
  end
end
