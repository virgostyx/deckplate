require "spec_helper"

RSpec.describe Deckplate::Data::ProgressComponent, type: :component do
  after { Deckplate.reset_configuration! }

  def bar = page.find("[role='progressbar']", visible: :all)

  it "renders a progress bar named by its visible label, with the ARIA value attributes" do
    render_inline(described_class.new(label: "Upload", value: 72, id: "up"))
    expect(bar["aria-valuemin"]).to eq("0")
    expect(bar["aria-valuemax"]).to eq("100")
    expect(bar["aria-valuenow"]).to eq("72")
    expect(bar["aria-valuetext"]).to eq("72%")
    expect(bar["aria-labelledby"]).to eq("up-label")
    expect(page).to have_css("#up-label.dp-progress__label", text: "Upload")
    expect(page).to have_css(".dp-progress__fill", visible: :all)
  end

  it "derives the label id from the label when there is no id (render-pure)" do
    render_inline(described_class.new(label: "Upload", value: 10))
    expect(bar["aria-labelledby"]).to eq("upload-progress-label")
    expect(render_inline(described_class.new(label: "A", value: 1)).to_html).to eq(render_inline(described_class.new(label: "A", value: 1)).to_html)
  end

  it "passes the value to the CSS as --dp-value (inline style by default)" do
    render_inline(described_class.new(label: "L", value: 72))
    expect(bar[:style]).to eq("--dp-value: 72")
  end

  it "can show the value as text" do
    render_inline(described_class.new(label: "L", value: 72, show_value: true))
    expect(page).to have_css(".dp-progress__value", text: "72%", visible: :all)
    render_inline(described_class.new(label: "L", value: 72))
    expect(page).not_to have_css(".dp-progress__value", visible: :all)
  end

  describe "segments" do
    it "renders a segmented bar with as many lit segments as the value says" do
      render_inline(described_class.new(label: "L", value: 50, segments: 10))
      expect(page).to have_css(".dp-progress__segment", count: 10, visible: :all)
      expect(page).to have_css(".dp-progress__segment--on", count: 5, visible: :all)
      expect(page).to have_css(".dp-progress--segmented", visible: :all)
    end

    it "rounds to the nearest segment" do
      render_inline(described_class.new(label: "L", value: 24, segments: 10))
      expect(page).to have_css(".dp-progress__segment--on", count: 2, visible: :all)
    end
  end

  it "is indeterminate without a value: no aria-valuenow, an animated state class" do
    render_inline(described_class.new(label: "Loading", value: nil))
    expect(bar["aria-valuenow"]).to be_nil
    expect(bar[:class].split).to include("dp-progress--indeterminate")
    expect(bar[:style]).to be_nil
  end

  it "uses quantised classes and no style attribute in CSP-safe mode" do
    Deckplate.configure { |c| c.csp_safe_values = true }
    render_inline(described_class.new(label: "L", value: 72.4))
    expect(bar[:style]).to be_nil
    expect(bar[:class].split).to include("dp-v-72")
    expect(bar["aria-valuenow"]).to eq("72.4")
  end

  it "applies a colour and passes html options through" do
    render_inline(described_class.new(label: "L", value: 1, color: :success, class: "x", data: { a: 1 }))
    expect(page).to have_css(".dp-progress.dp-c-success.x[data-a='1']", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(label: "", value: 1) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(label: "L", value: 101) }.to raise_error(ArgumentError, /value.*0.*100/)
    expect { described_class.new(label: "L", value: -1) }.to raise_error(ArgumentError, /value/)
    expect { described_class.new(label: "L", value: "50") }.to raise_error(ArgumentError, /value/)
    expect { described_class.new(label: "L", value: 1, segments: 0) }.to raise_error(ArgumentError, /segments/)
    expect { described_class.new(label: "L", value: 1, color: :nope) }.to raise_error(ArgumentError, /unknown colour/)
  end
end
