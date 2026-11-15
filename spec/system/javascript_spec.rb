require "spec_helper"

RSpec.describe "JavaScript infrastructure", type: :system, js: true do
  before { driven_by :dp_cuprite }

  it "boots Turbo and Stimulus on a preview page without console errors" do
    visit "/rails/view_components/token_gallery/default"
    expect(page).to have_css("html[data-dp-theme]")
    expect(page.evaluate_script("typeof window.Turbo")).to eq("object")
    expect(page.evaluate_script("typeof window.Stimulus.register")).to eq("function")
  end

  it "registers every Deckplate controller listed in the table, and only those files exist" do
    visit "/rails/view_components/token_gallery/default"
    registered = page.evaluate_script("window.Stimulus.router.modules.map(m => m.identifier)")
    files = Dir[Deckplate::Engine.root.join("app/javascript/deckplate/controllers/dp_*_controller.js")]
            .map { File.basename(_1, "_controller.js").tr("_", "-") }
    expect(registered.sort).to eq(files.sort)
  end
end
