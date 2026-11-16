require "spec_helper"

RSpec.describe "Bundled fonts" do
  let(:fonts_dir) { Deckplate::Engine.root.join("app/assets/fonts/deckplate") }
  let(:css) { File.read(Deckplate::Engine.root.join("app/assets/stylesheets/deckplate.css")) }

  it "stays within the 90 KB woff2 budget" do
    total = Dir[fonts_dir.join("*.woff2")].sum { File.size(_1) }
    expect(total).to be <= 90 * 1024
  end

  it "ships an OFL licence file for each family" do
    expect(Dir[fonts_dir.join("OFL-*.txt")].map { File.basename(_1) }).to contain_exactly("OFL-Antonio.txt", "OFL-Share-Tech-Mono.txt")
    expect(File.read(fonts_dir.join("OFL-Antonio.txt"))).to include("SIL OPEN FONT LICENSE Version 1.1")
  end

  it "declares font-display: swap and an existing file for every @font-face" do
    faces = css.scan(/@font-face\s*\{(.*?)\}/m).flatten.reject { _1.include?("Fallback") } # local fallbacks: see the CLS spec below
    expect(faces.size).to be >= 3
    faces.each do |face|
      expect(face).to include("font-display: swap")
      file = face[%r{url\("deckplate/([^"]+)"\)}, 1]
      expect(fonts_dir.join(file)).to exist
    end
  end

  it "covers latin and latin-ext for the display face (French/Dutch accents)" do
    expect(css).to include("U+0100-02BA") # latin-ext range
    expect(css).to match(/font-family: "Antonio"/)
  end

  # CLS: while the web font loads, a local font is scaled to the same width and line metrics, so the swap moves nothing (ADR 0015).
  it "declares metric-adjusted local fallback faces, placed right after each web font in its stack" do
    { "Antonio" => "Arial", "Share Tech Mono" => "Courier New" }.each do |family, local|
      face = css.scan(/@font-face\s*\{(.*?)\}/m).flatten.find { _1.include?(%(font-family: "#{family} Fallback")) }
      expect(face).to include(%(src: local("#{local}")))
      expect(face).to match(/size-adjust: \d+(\.\d+)?%/)
      expect(face).to match(/ascent-override: \d+(\.\d+)?%/).and match(/descent-override: \d+(\.\d+)?%/).and include("line-gap-override: 0%")
      expect(css).to include(%("#{family}", "#{family} Fallback"))
    end
  end
end
