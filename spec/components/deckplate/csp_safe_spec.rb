require "spec_helper"

# SPEC section 11: with csp_safe_values, components that take dynamic values emit no style attribute.
RSpec.describe "CSP-safe mode for shapes", type: :component do
  before { Deckplate.configure { |c| c.csp_safe_values = true } }
  after { Deckplate.reset_configuration! }

  def vars_of(el) = JSON.parse(el["data-dp-values-vars-value"])

  it "Spacer" do
    render_inline(Deckplate::Shapes::SpacerComponent.new(size: 2))
    el = page.find(".dp-spacer", visible: :all)
    expect(el[:style]).to be_nil
    expect(vars_of(el)).to eq("--dp-n" => "2")
  end

  it "Bar thickness and sized segments" do
    render_inline(Deckplate::Shapes::BarComponent.new(thickness: 2.5)) do |b|
      b.with_segment(color: :info, size: 3)
      b.with_segment(color: :warning)
    end
    expect(page.find(".dp-bar", visible: :all)[:style]).to be_nil
    expect(vars_of(page.find(".dp-bar", visible: :all))).to eq("--dp-bar-t" => "2.5")
    sized = page.all(".dp-bar__segment", visible: :all).first
    expect(sized[:style]).to be_nil
    expect(vars_of(sized)).to eq("--dp-seg" => "3")
    expect(page.all(".dp-bar__segment", visible: :all).last["data-controller"]).to be_nil
  end

  it "Elbow custom dimensions" do
    render_inline(Deckplate::Shapes::ElbowComponent.new(width: 9, height: 6.5))
    el = page.find(".dp-elbow", visible: :all)
    expect(el[:style]).to be_nil
    expect(vars_of(el)).to eq("--dp-elbow-w" => "calc(9 * var(--dp-u))", "--dp-elbow-h" => "calc(6.5 * var(--dp-u))")
  end

  it "leaves components without dynamic values untouched" do
    render_inline(Deckplate::Shapes::CapComponent.new)
    expect(page.find(".dp-cap", visible: :all)["data-controller"]).to be_nil
  end
end
