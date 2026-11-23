require "spec_helper"

# G-12: a wide table inside a Section, Panel or Tabs panel scrolls inside its own wrapper; it must not widen the page.
RSpec.describe "Wide table inside containers", type: :system, js: true do
  CONTAINERS = {
    "section/default" => ".dp-section__body",
    "panel/default" => ".dp-panel__body",
    "tabs/default" => ".dp-tabs__panel:not([hidden])"
  }.freeze

  before { driven_by :dp_cuprite }

  [ 390, 820 ].each do |width|
    CONTAINERS.each do |preview, selector|
      it "#{preview} at #{width}px keeps the table scrolling in its wrapper" do
        page.current_window.resize_to(width, 800)
        visit "/rails/view_components/#{preview}"
        expect(page).to have_css(selector, match: :first)
        page.execute_script(<<~JS, selector)
          const body = document.querySelector(arguments[0])
          body.insertAdjacentHTML("beforeend",
            '<div class="dp-table" id="wide"><table class="dp-table__table"><tbody><tr><td><div style="min-width:1400px">wide</div></td></tr></tbody></table></div>')
        JS
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true),
          "page scrollWidth #{page.evaluate_script('document.documentElement.scrollWidth')} > #{width}"
        wrapper = page.evaluate_script('(() => { const w = document.getElementById("wide"); return [w.clientWidth, w.scrollWidth] })()')
        expect(wrapper[0]).to be < wrapper[1], "the wrapper should scroll (client #{wrapper[0]}, scroll #{wrapper[1]})"
      end
    end
  end
end
