require "spec_helper"

RSpec.describe Deckplate::Forms::DateInputComponent, type: :component do
  def build(**opts) = described_class.new(name: "ship[callsign]", label: "Callsign", **opts)
  let(:control_css) { "input[type='date'].dp-input" }

  it_behaves_like "a form control"

  it "formats Date, Time and String values for the native control" do
    render_inline(build(value: Date.new(2026, 3, 9)))
    expect(page.find("input")[:value]).to eq("2026-03-09")
    render_inline(build(type: :datetime_local, value: Time.utc(2026, 3, 9, 14, 5, 59)))
    expect(page.find("input")[:value]).to eq("2026-03-09T14:05")
    render_inline(build(type: :time, value: Time.utc(2026, 3, 9, 14, 5)))
    expect(page.find("input")[:value]).to eq("14:05")
    render_inline(build(type: :month, value: Date.new(2026, 3, 9)))
    expect(page.find("input")[:value]).to eq("2026-03")
    render_inline(build(value: "2026-01-02"))
    expect(page.find("input")[:value]).to eq("2026-01-02")
  end

  it "supports the native date and time types and min/max" do
    { date: "date", time: "time", datetime_local: "datetime-local", month: "month", week: "week" }.each do |type, html|
      render_inline(build(type:))
      expect(page).to have_css("input[type='#{html}']")
    end
    render_inline(build(min: "2026-01-01", max: "2026-12-31"))
    expect([ page.find("input")[:min], page.find("input")[:max] ]).to eq(%w[2026-01-01 2026-12-31])
  end

  it "rejects an unknown type" do
    expect { build(type: :text) }.to raise_error(ArgumentError, /type.*date, time, datetime_local, month, week/)
  end
end
