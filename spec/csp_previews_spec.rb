require "spec_helper"

# SPEC section 11: with csp_safe_values every preview renders without a single inline style on a Deckplate element.
# (Preview scaffolding such as <div style="max-inline-size: 12rem"> is not a component and is not checked.)
RSpec.describe "CSP-safe mode over every preview", type: :component do
  before { Deckplate.configure { |c| c.csp_safe_values = true } }
  after { Deckplate.reset_configuration! }

  ViewComponent::Preview.all.each do |preview|
    preview.examples.each do |example|
      it "#{preview.preview_name}/#{example} has no style attribute on its components" do
        render_preview(example, from: preview)
        offenders = page.all("[style]", visible: :all).select { |el| el[:class].to_s.split.any? { |c| c.start_with?("dp-") && c != "dp-root" } }
        expect(offenders.map { |el| "#{el.tag_name}.#{el[:class]} style=#{el[:style].inspect}" }).to eq([])
        expect(page.all("body script, body style", visible: :all).size).to eq(0) # no inline script or style from components
      end
    end
  end

  it "actually exercises the mode: a preview with dynamic values carries dp-values data and quantised classes" do
    render_preview(:variants, from: GaugePreview)
    expect(page).to have_css("[class*='dp-v-']", visible: :all)
    render_preview(:sizes, from: SpacerPreview)
    expect(page).to have_css("[data-controller~='dp-values']", visible: :all)
  end
end
