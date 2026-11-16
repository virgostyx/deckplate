# Finds elements that stick out of the viewport and are not clipped by a scrollable/clipping ancestor (shared by the overflow specs).
module OverflowHelper
  FIND_JS = <<~JS.freeze
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

  ALL_PREVIEWS = -> { ViewComponent::Preview.all.flat_map { |p| p.examples.map { |e| "#{p.preview_name}/#{e}" } }.sort }
  DESKTOP_ONLY = %w[classic_console/default].freeze # reproduces a desktop console page (SPEC 5.4), not a responsive layout

  def overflowing_elements = page.evaluate_script(FIND_JS)
  def emulate_media(**features) = page.driver.browser.page.command("Emulation.setEmulatedMedia", features: features.map { |k, v| { name: k.to_s.tr("_", "-"), value: v } })
end

RSpec.configure { |c| c.include OverflowHelper, type: :system }
