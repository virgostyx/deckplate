require "spec_helper"

RSpec.describe "foundation tokens" do
  let(:css) { File.read(Deckplate::Engine.root.join("app/assets/stylesheets/deckplate.css")) }

  %w[
    --dp-u --dp-bar --dp-gap --dp-elbow-col --dp-elbow-r --dp-elbow-ri --dp-pill-r --dp-touch-min
    --dp-font-display --dp-font-data --dp-font-text
    --dp-t-fast --dp-t-base --dp-t-slow --dp-ease
    --dp-z-sticky --dp-z-overlay --dp-z-modal --dp-z-toast
  ].each do |var|
    it "defines #{var}" do
      expect(css).to match(/#{Regexp.escape(var)}:\s*[^;]+;/)
    end
  end

  it "never uses px for shape geometry (zoom must scale the console)" do
    geometry = css.scan(/--dp-(?:u|bar|gap|elbow-[a-z]+):\s*([^;]+);/).flatten
    expect(geometry).not_to be_empty
    expect(geometry.grep(/\d\s*px/)).to be_empty
  end
end
