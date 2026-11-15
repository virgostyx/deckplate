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
    faces = css.scan(/@font-face\s*\{(.*?)\}/m).flatten
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
end
