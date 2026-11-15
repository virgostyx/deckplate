require "spec_helper"
require "open3"

# Runs the Playwright geometry check (tools/visual/elbow_geometry.mjs) against the test server: all four elbow corners at
# fractional device pixel ratios must have no seams, straight edges, and a transparent inner arc (ADR 0002).
# Chrome only by default; ELBOW_BROWSERS=chrome,firefox,webkit for the full matrix (bin/visual --geometry does that).
RSpec.describe "Elbow geometry (browser pixels)", type: :system, js: true do
  tool = Deckplate::Engine.root.join("tools/visual")

  before do
    skip "run `cd tools/visual && npm install` first" unless tool.join("node_modules/playwright").exist?
    driven_by :dp_cuprite
  end

  it "has no seams, no stair-steps and a transparent inner arc in any corner" do
    visit "/up"
    base = "http://127.0.0.1:#{Capybara.current_session.server.port}"
    out, status = Open3.capture2e("node", "elbow_geometry.mjs", "--base", base, "--browsers", ENV.fetch("ELBOW_BROWSERS", "chrome"), chdir: tool.to_s)
    expect(status).to be_success, "elbow geometry check failed:\n#{out}"
  end
end
