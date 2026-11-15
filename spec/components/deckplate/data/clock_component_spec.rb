require "spec_helper"

RSpec.describe Deckplate::Data::ClockComponent, type: :component do
  let(:time) { Time.utc(2026, 3, 9, 14, 5, 59) }

  def clock = page.find("time.dp-clock")

  it "renders the server time as the initial value, in a semantic time element that is not announced as it ticks" do
    render_inline(described_class.new(time:, zone: "UTC"))
    expect(clock.text).to eq("14:05:59")
    expect(clock[:datetime]).to eq("2026-03-09T14:05:59Z")
    expect(clock[:role]).to eq("timer") # a timer is not a live region: assistive tech does not read each second
  end

  it "hands the controller the server epoch (so a wrong client clock does not matter), the zone and the format" do
    render_inline(described_class.new(time:, zone: "Europe/Brussels", format: :datetime))
    expect(clock["data-controller"]).to eq("dp-clock")
    expect(clock["data-dp-clock-epoch-value"]).to eq((time.to_i * 1000).to_s)
    expect(clock["data-dp-clock-zone-value"]).to eq("Europe/Brussels")
    expect(clock["data-dp-clock-format-value"]).to eq("datetime")
  end

  it "formats the initial text in the requested zone and format" do
    render_inline(described_class.new(time:, zone: "Europe/Brussels", format: :time))
    expect(clock.text).to eq("15:05:59")
    render_inline(described_class.new(time:, zone: "UTC", format: :datetime))
    expect(clock.text).to eq("2026-03-09 14:05:59")
    render_inline(described_class.new(time:, zone: "UTC", format: :date))
    expect(clock.text).to eq("2026-03-09")
  end

  it "defaults to the application time zone and the current time" do
    render_inline(described_class.new)
    expect(clock["data-dp-clock-zone-value"]).to eq(Time.zone.tzinfo.name)
    expect(clock["data-dp-clock-epoch-value"].to_i).to be_within(5_000).of(Time.current.to_i * 1000)
  end

  it "can be named, and passes html options through (an id plus data-turbo-permanent keeps it across Turbo visits)" do
    render_inline(described_class.new(time:, zone: "UTC", label: "Ship time", id: "ship-clock", class: "x", data: { turbo_permanent: true }))
    expect(page).to have_css("time#ship-clock.dp-clock.x[aria-label='Ship time'][data-turbo-permanent]")
  end

  it "rejects an unknown format or zone" do
    expect { described_class.new(format: :seconds) }.to raise_error(ArgumentError, /format.*time, datetime, date/)
    expect { described_class.new(zone: "Mars/Olympus") }.to raise_error(ArgumentError, /zone/)
  end
end
