require "spec_helper"

# Guards the guard: if axe silently stops running, the previews spec would be green for the wrong reason.
RSpec.describe "axe harness", type: :system, js: true do
  before { driven_by :dp_cuprite }

  it "reports a missing alt text and a low-contrast text" do
    visit "/rails/view_components/token_gallery/default"
    page.execute_script(<<~JS)
      document.body.insertAdjacentHTML("beforeend",
        '<img src="data:image/gif;base64,R0lGODlhAQABAAAAACw=">' +
        '<p style="color:#777;background:#888">low contrast text</p>')
    JS
    ids = axe_violations.map { _1["id"] }
    expect(ids).to include("image-alt", "color-contrast")
  end
end
