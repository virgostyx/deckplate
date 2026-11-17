require "spec_helper"
require "open3"

# Runs tools/visual/rtl_mirror.mjs against the test server: shapes rendered with dir=rtl must be the LTR render flipped (ADR 0017).
RSpec.describe "RTL mirror (browser pixels)", type: :system, js: true do
  tool = Deckplate::Engine.root.join("tools/visual")

  before do
    skip "run `cd tools/visual && npm install` first" unless tool.join("node_modules/playwright").exist?
    driven_by :dp_cuprite
  end

  it "renders text-free shapes in RTL exactly as the flipped LTR render" do
    visit "/up"
    base = "http://127.0.0.1:#{Capybara.current_session.server.port}"
    out, status = Open3.capture2e("node", "rtl_mirror.mjs", "--base", base, chdir: tool.to_s)
    expect(status).to be_success, "RTL mirror check failed:\n#{out}"
  end
end
