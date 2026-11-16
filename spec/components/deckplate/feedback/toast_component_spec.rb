require "spec_helper"

RSpec.describe Deckplate::Feedback::ToastComponent, type: :component do
  def toast = page.find(".dp-toast")

  it "renders a message with the kind's role, colour and icon, wired to dp-toast" do
    render_inline(described_class.new(kind: :success)) { "Saved." }
    expect(toast[:role]).to eq("status")
    expect(toast[:class].split).to include("dp-toast--success", "dp-c-success")
    expect(toast).to have_css(".dp-toast__message", text: "Saved.")
    expect(toast).to have_css("svg.dp-icon[aria-hidden='true']")
    expect(toast).to have_css(".dp-sr-only", text: "Success")
    expect(toast["data-controller"]).to eq("dp-toast")
  end

  it "uses role=alert for warnings and errors, status for the rest" do
    { info: "status", success: "status", warning: "alert", danger: "alert" }.each do |kind, role|
      render_inline(described_class.new(kind:)) { "x" }
      expect(toast[:role]).to eq(role)
    end
  end

  describe "duration" do
    it "auto-dismisses after 5 seconds by default for info and success" do
      render_inline(described_class.new(kind: :info)) { "x" }
      expect(toast["data-dp-toast-duration-value"]).to eq("5000")
      render_inline(described_class.new(kind: :success)) { "x" }
      expect(toast["data-dp-toast-duration-value"]).to eq("5000")
    end

    it "keeps warnings and errors until the user dismisses them (they must be readable)" do
      render_inline(described_class.new(kind: :danger)) { "x" }
      expect(toast["data-dp-toast-duration-value"]).to eq("0")
      render_inline(described_class.new(kind: :warning)) { "x" }
      expect(toast["data-dp-toast-duration-value"]).to eq("0")
    end

    it "accepts a custom duration in milliseconds, and 0 for a persistent toast" do
      render_inline(described_class.new(duration: 12_000)) { "x" }
      expect(toast["data-dp-toast-duration-value"]).to eq("12000")
      render_inline(described_class.new(duration: 0)) { "x" }
      expect(toast["data-dp-toast-duration-value"]).to eq("0")
    end
  end

  it "pauses on hover and focus, and has a translated close button" do
    render_inline(described_class.new) { "x" }
    actions = toast["data-action"]
    expect(actions).to include("mouseenter->dp-toast#pause", "mouseleave->dp-toast#resume", "focusin->dp-toast#pause", "focusout->dp-toast#resume")
    close = toast.find("button.dp-toast__close")
    expect(close["aria-label"]).to eq("Dismiss notification")
    expect(close["data-action"]).to eq("dp-toast#dismiss")
    I18n.with_locale(:fr) { render_inline(described_class.new) { "x" } }
    expect(toast.find("button")["aria-label"]).to eq("Fermer la notification")
  end

  it "passes html options through" do
    render_inline(described_class.new(id: "t1", class: "x", data: { a: 1 })) { "x" }
    expect(page).to have_css("#t1.dp-toast.x[data-a='1']")
  end

  it "rejects invalid input" do
    expect { described_class.new(kind: :fatal) }.to raise_error(ArgumentError, /kind.*info, success, warning, danger/)
    expect { described_class.new(duration: -1) }.to raise_error(ArgumentError, /duration/)
    expect { described_class.new(duration: "5") }.to raise_error(ArgumentError, /duration/)
  end
end
