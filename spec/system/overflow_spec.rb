require "spec_helper"

# No preview may overflow horizontally on a phone (375 px): content wraps, truncates or scrolls inside its own region.
RSpec.describe "No horizontal overflow at 375px", type: :system, js: true do
  before do
    driven_by :dp_cuprite
    page.current_window.resize_to(375, 800)
  end

  # Elements that stick out of the viewport and are not clipped by a scrollable/clipping ancestor
  FIND_OVERFLOW = <<~JS.freeze
    (function () {
      var width = document.documentElement.clientWidth, out = []
      document.querySelectorAll("body *").forEach(function (el) {
        var r = el.getBoundingClientRect()
        if (r.width === 0 || r.right <= width + 1) return
        if (getComputedStyle(el).position === "fixed") return
        for (var p = el.parentElement; p && p !== document.body; p = p.parentElement) {
          var o = getComputedStyle(p).overflowX
          if (o === "auto" || o === "hidden" || o === "scroll" || o === "clip") return
        }
        out.push(el.tagName.toLowerCase() + "." + String(el.className).split(" ").slice(0, 3).join(".") + " right=" + Math.round(r.right))
      })
      return out.slice(0, 5)
    })()
  JS

  DESKTOP_ONLY = %w[classic_console/default].freeze # reproduces a desktop console page (SPEC 5.4), not a responsive layout

  ViewComponent::Preview.all.flat_map { |p| p.examples.map { |e| "#{p.preview_name}/#{e}" } }.sort.reject { DESKTOP_ONLY.include?(_1) }.each do |preview|
    it "#{preview} fits in 375px" do
      visit "/rails/view_components/#{preview}"
      expect(page).to have_css("html[data-dp-theme]")
      overflowing = page.evaluate_script(FIND_OVERFLOW)
      expect(overflowing).to eq([]), "elements wider than the screen:\n  #{overflowing.join("\n  ")}"
    end
  end
end
