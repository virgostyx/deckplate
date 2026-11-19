require "spec_helper"

RSpec.describe "Sortable list (dp-sortable)", type: :system, js: true do
  before do
    driven_by :dp_cuprite
    visit "/rails/view_components/sortable_list/default"
    page.execute_script("window.__orders = []; document.addEventListener('dp-sortable:reorder', e => window.__orders.push(e.detail.ids))")
  end

  def labels = page.evaluate_script("[...document.querySelectorAll('.dp-sortable__label')].map(e => e.textContent)")
  def fields = page.evaluate_script("[...document.querySelectorAll('.dp-sortable input[type=hidden]')].map(e => e.value)")
  def move(item, dir) = find("button[aria-label='Move #{item} #{dir}']").click
  def status = find("[role=status]", visible: :all).text(:all)
  def focused = page.evaluate_script("document.activeElement.getAttribute('aria-label')")

  it "shows its controls once the script runs, with the end buttons disabled" do
    expect(page).to have_css(".dp-sortable[data-dp-sortable-ready]")
    expect(page).to have_css("button[aria-label='Move Alpha up'][disabled]")
    expect(page).to have_css("button[aria-label='Move Gamma down'][disabled]")
    expect(page).to have_css("button[aria-label='Move Alpha down']:not([disabled])")
  end

  it "moves an item with the buttons, keeps the form fields in the same order, tells the page and announces it" do
    expect(labels).to eq(%w[Alpha Beta Gamma])
    move("Alpha", "down")
    expect(labels).to eq(%w[Beta Alpha Gamma])
    expect(fields).to eq(%w[b a c])
    expect(page.evaluate_script("window.__orders")).to eq([ %w[b a c] ])
    expect(status).to eq("Alpha moved to position 2 of 3")
    expect(page).to have_css("button[aria-label='Move Beta up'][disabled]")
  end

  it "keeps the keyboard focus on the button that was used, or on its twin when it becomes disabled" do
    move("Alpha", "down")
    expect(focused).to eq("Move Alpha down")
    move("Alpha", "down")
    expect(labels).to eq(%w[Beta Gamma Alpha])
    expect(focused).to eq("Move Alpha up") # the down button is now disabled
  end

  it "works from the keyboard alone" do
    page.execute_script("document.querySelector(\"button[aria-label='Move Beta up']\").focus()")
    press(:Enter)
    expect(labels).to eq(%w[Beta Alpha Gamma])
  end

  it "reorders by dragging the grip with the pointer" do
    mouse = page.driver.browser.mouse
    x, y = page.evaluate_script("(function(){ var r = document.querySelector('.dp-sortable__item .dp-sortable__grip').getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2] })()")
    last = page.evaluate_script("(function(){ var r = [...document.querySelectorAll('.dp-sortable__item')].pop().getBoundingClientRect(); return r.bottom - 2 })()")
    mouse.move(x: x, y: y)
    mouse.down
    mouse.move(x: x, y: y + 40, steps: 4)
    mouse.move(x: x, y: last, steps: 6)
    mouse.up
    expect(labels).to eq(%w[Beta Gamma Alpha])
    expect(fields).to eq(%w[b c a])
    expect(page.evaluate_script("window.__orders.length")).to eq(1)
    expect(page).not_to have_css(".dp-sortable__item--dragging")
  end

  it "does nothing when a grip is released where it started" do
    mouse = page.driver.browser.mouse
    x, y = page.evaluate_script("(function(){ var r = document.querySelector('.dp-sortable__grip').getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2] })()")
    mouse.move(x: x, y: y)
    mouse.down
    mouse.up
    expect(labels).to eq(%w[Alpha Beta Gamma])
    expect(page.evaluate_script("window.__orders")).to eq([])
  end

  it "behaves the same right to left" do
    visit "/rails/view_components/sortable_list/default?dir=rtl"
    move("Alpha", "down")
    expect(labels).to eq(%w[Beta Alpha Gamma])
  end
end
