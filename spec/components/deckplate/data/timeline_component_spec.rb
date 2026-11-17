require "spec_helper"

RSpec.describe Deckplate::Data::TimelineComponent, type: :component do
  def build(**options, &block)
    render_inline(described_class.new(**options)) do |t|
      t.with_event(title: "Launch", time: "14:02", datetime: "2026-11-17T14:02", state: :done) { "Left dock" }
      t.with_event(title: "Transit", state: :current)
      t.with_event(title: "Arrival", time: "18:30", state: :upcoming)
      block&.call(t)
    end
  end

  it "renders an ordered list of events, in the order given" do
    build
    expect(page).to have_css("ol.dp-timeline > li.dp-timeline__event", count: 3)
    expect(page.all("li .dp-timeline__title").map { _1.text.split(":").first.strip }).to eq(%w[Launch Transit Arrival])
  end

  it "defaults to the primary colour and passes html options through" do
    build(class: "x", id: "t", data: { k: 1 }, aria: { label: "Mission" })
    expect(page).to have_css("ol#t.dp-timeline.dp-c-primary.x[data-k='1'][aria-label='Mission']")
  end

  describe "states (never colour alone: an icon or shape, and a text for assistive technology)" do
    it "marks the three states with a class" do
      build
      expect(page).to have_css("li.dp-timeline__event--done", count: 1)
      expect(page).to have_css("li.dp-timeline__event--current", count: 1)
      expect(page).to have_css("li.dp-timeline__event--upcoming", count: 1)
    end

    it "flags only the current event as the current step" do
      build
      expect(page).to have_css("li[aria-current='step']", count: 1)
      expect(page).to have_css("li.dp-timeline__event--current[aria-current='step']")
    end

    it "shows a check in the marker of a done event and nothing in the other markers" do
      build
      expect(page).to have_css("li.dp-timeline__event--done .dp-timeline__marker svg.dp-icon", visible: :all)
      expect(page).not_to have_css("li.dp-timeline__event--current .dp-timeline__marker svg", visible: :all)
      expect(page).not_to have_css("li.dp-timeline__event--upcoming .dp-timeline__marker svg", visible: :all)
    end

    it "hides the marker from assistive technology and names the state in text instead" do
      build
      expect(page).to have_css(".dp-timeline__marker[aria-hidden='true']", count: 3, visible: :all)
      expect(page.find("li.dp-timeline__event--done .dp-sr-only", visible: :all).text).to include("Completed")
      expect(page.find("li.dp-timeline__event--current .dp-sr-only", visible: :all).text).to include("Current")
      expect(page.find("li.dp-timeline__event--upcoming .dp-sr-only", visible: :all).text).to include("Upcoming")
    end

    it "speaks French" do
      I18n.with_locale(:fr) { build }
      expect(page.find("li.dp-timeline__event--done .dp-sr-only", visible: :all).text).to include("Terminé")
      expect(page.find("li.dp-timeline__event--current .dp-sr-only", visible: :all).text).to include("En cours")
      expect(page.find("li.dp-timeline__event--upcoming .dp-sr-only", visible: :all).text).to include("À venir")
    end

    it "treats an event without a state as done" do
      render_inline(described_class.new) { |t| t.with_event(title: "A") }
      expect(page).to have_css("li.dp-timeline__event--done")
    end
  end

  describe "time" do
    it "renders a <time> with the machine-readable value when given" do
      build
      expect(page).to have_css("li.dp-timeline__event--done time.dp-timeline__time[datetime='2026-11-17T14:02']", text: "14:02")
    end

    it "renders a <time> without datetime when only a text is given, and none when there is no time" do
      build
      expect(page).to have_css("li.dp-timeline__event--upcoming time.dp-timeline__time:not([datetime])", text: "18:30")
      expect(page).not_to have_css("li.dp-timeline__event--current time")
    end

    it "accepts a Time, formatting it and giving its ISO 8601 value" do
      moment = Time.utc(2026, 11, 17, 9, 5)
      render_inline(described_class.new) { |t| t.with_event(title: "A", time: moment) }
      expect(page).to have_css("time[datetime='2026-11-17T09:05:00Z']")
      expect(page.find("time").text).to include("2026")
    end
  end

  it "renders the event body" do
    build
    expect(page).to have_css("li.dp-timeline__event--done .dp-timeline__body", text: "Left dock")
    expect(page).not_to have_css("li.dp-timeline__event--current .dp-timeline__body")
  end

  it "escapes titles" do
    render_inline(described_class.new) { |t| t.with_event(title: "<b>x</b>") }
    expect(page.native.to_html).to include("&lt;b&gt;x&lt;/b&gt;")
  end

  it "lets one event take another colour role" do
    build { |t| t.with_event(title: "Fault", state: :done, color: :danger) }
    expect(page).to have_css("li.dp-timeline__event.dp-c-danger .dp-timeline__title", text: "Fault")
    expect(page).not_to have_css("li.dp-c-primary")
  end

  it "applies a colour to the whole timeline" do
    render_inline(described_class.new(color: :tertiary)) { |t| t.with_event(title: "A") }
    expect(page).to have_css("ol.dp-timeline.dp-c-tertiary")
  end

  it "renders nothing without events" do
    render_inline(described_class.new)
    expect(page).not_to have_css("ol")
  end

  describe "validation" do
    it "requires a title" do
      expect { render_inline(described_class.new) { |t| t.with_event(title: " ") } }.to raise_error(ArgumentError, /title/)
    end

    it "rejects an unknown state and lists the valid ones" do
      expect { render_inline(described_class.new) { |t| t.with_event(title: "A", state: :late) } }.to raise_error(ArgumentError, /state.*done, current, upcoming/)
    end

    it "rejects an unknown colour role" do
      expect { render_inline(described_class.new) { |t| t.with_event(title: "A", color: :nonsense) } }.to raise_error(ArgumentError)
    end

    it "rejects a datetime without a time" do
      expect { render_inline(described_class.new) { |t| t.with_event(title: "A", datetime: "2026-11-17") } }.to raise_error(ArgumentError, /datetime.*time/)
    end
  end
end
