require "spec_helper"

RSpec.describe "Frame responsive behaviour", type: :system, js: true do
  before { driven_by :dp_cuprite }

  def resize(width, height = 800) = page.current_window.resize_to(width, height)
  def horizontal_scroll? = page.evaluate_script("document.documentElement.scrollWidth > document.documentElement.clientWidth")
  def visible?(selector) = page.evaluate_script("(function(){var e=document.querySelector('#{selector}'); if(!e) return false; var r=e.getBoundingClientRect(); var s=getComputedStyle(e); return s.display!=='none' && s.visibility!=='hidden' && r.width>0 && r.height>0})()")

  [ 375, 768, 1280 ].each do |width|
    it "never scrolls horizontally at #{width}px (classic, double, minimal)" do
      resize(width)
      %w[classic double minimal].each do |variant|
        visit "/rails/view_components/frame/#{variant}"
        expect(page).to have_css(".dp-frame")
        expect(horizontal_scroll?).to be(false), "#{variant} overflows horizontally at #{width}px"
      end
    end
  end

  describe "classic at 375px" do
    before do
      resize(375)
      visit "/rails/view_components/frame/classic"
    end

    it "collapses the sidebar behind a Menu button and drops the corners" do
      expect(visible?(".dp-frame__menu")).to be(true)
      expect(visible?(".dp-frame__sidebar")).to be(false)
      expect(visible?(".dp-frame__corner")).to be(false)
    end

    it "opens the sidebar as a popover with the button, and closes it with Escape" do
      find(".dp-frame__menu").click
      expect(page).to have_css(".dp-frame__sidebar:popover-open", visible: :all)
      expect(visible?(".dp-frame__sidebar")).to be(true)
      expect(page).to have_content(/sensors/i)
      page.driver.browser.keyboard.type(:Escape)
      expect(page).not_to have_css(".dp-frame__sidebar:popover-open", visible: :all)
    end
  end

  describe "classic at 1280px" do
    before do
      resize(1280)
      visit "/rails/view_components/frame/classic"
    end

    it "shows the sidebar and the corners inline, without the Menu button" do
      expect(visible?(".dp-frame__sidebar")).to be(true)
      expect(visible?(".dp-frame__corner")).to be(true)
      expect(visible?(".dp-frame__menu")).to be(false)
      expect(page).to have_content(/sensors/i)
    end

    it "places the sidebar to the left of main" do
      rects = page.evaluate_script("(function(){var s=document.querySelector('.dp-frame__sidebar').getBoundingClientRect(), m=document.querySelector('.dp-frame__main').getBoundingClientRect(); return [s.right, m.left]})()")
      expect(rects[0]).to be <= rects[1]
    end
  end

  it "shows the aside next to main in the double variant on wide screens only" do
    resize(1280)
    visit "/rails/view_components/frame/double"
    expect(visible?(".dp-frame__aside")).to be(true)
    main_right, aside_left = page.evaluate_script("(function(){var a=document.querySelector('.dp-frame__aside').getBoundingClientRect(), m=document.querySelector('.dp-frame__main').getBoundingClientRect(); return [m.right, a.left]})()")
    expect(main_right).to be <= aside_left
    resize(375)
    visit "/rails/view_components/frame/double"
    main_bottom, aside_top = page.evaluate_script("(function(){var a=document.querySelector('.dp-frame__aside').getBoundingClientRect(), m=document.querySelector('.dp-frame__main').getBoundingClientRect(); return [m.bottom, a.top]})()")
    expect(main_bottom).to be <= aside_top
  end

  describe "fixed frame" do
    [ 375, 1280 ].each do |width|
      it "fills the viewport and scrolls only main at #{width}px" do
        resize(width, 600)
        visit "/rails/view_components/frame/fixed"
        expect(page).to have_css(".dp-frame--fixed")
        doc = page.evaluate_script("[document.documentElement.scrollHeight, document.documentElement.clientHeight]")
        expect(doc[0]).to be <= doc[1] + 1 # the page itself does not scroll
        main = page.evaluate_script("(function(){var m=document.querySelector('.dp-frame__main'); return [m.scrollHeight, m.clientHeight]})()")
        expect(main[0]).to be > main[1] # main has overflow...
        page.execute_script("document.querySelector('.dp-frame__main').scrollTop = 200")
        expect(page.evaluate_script("document.querySelector('.dp-frame__main').scrollTop")).to be > 0
        expect(page.evaluate_script("window.scrollY")).to eq(0)
        expect(visible?(".dp-frame__footer")).to be(true) # chrome stays in view
      end
    end
  end

  it "reaches the main content with the skip link" do
    resize(1280)
    visit "/rails/view_components/frame/classic"
    link = page.find(".dp-frame__skip", visible: :all)
    expect(link[:href]).to end_with("#dp-frame-main")
    expect(page).to have_css("main#dp-frame-main")
  end
end
