require "spec_helper"

# G-17: with a long status pill in the header bar, the title must keep a readable width (it wraps below the pill
# instead of shrinking to a column of single letters).
RSpec.describe "Panel header on a phone", type: :system, js: true do
  before do
    driven_by :dp_cuprite
    page.current_window.resize_to(390, 800)
  end

  it "keeps the title readable next to a long, non-wrapping action" do
    visit "/rails/view_components/panel/default"
    expect(page).to have_css(".dp-panel__header")
    page.execute_script(<<~JS)
      const header = document.querySelector(".dp-panel__header")
      const actions = document.createElement("div")
      actions.className = "dp-panel__actions"
      actions.innerHTML = '<span style="white-space:nowrap">DEGRADED: 3 CHECKS FAILING NOW</span>'
      header.appendChild(actions)
      header.querySelector(".dp-panel__title").textContent = "Reactor core"
    JS
    title_width = page.evaluate_script('document.querySelector(".dp-panel__title").getBoundingClientRect().width')
    expect(title_width).to be > 90, "title shrank to #{title_width}px"
    expect(page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')).to be(true)
  end
end
