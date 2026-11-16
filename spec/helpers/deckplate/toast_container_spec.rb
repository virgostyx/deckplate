require "spec_helper"

RSpec.describe Deckplate::Helpers, type: :helper do
  describe "#dp_toast_container" do
    def container = Capybara.string(helper.dp_toast_container).find("#dp-toasts", visible: :all)

    it "renders the Turbo Stream target as a polite live region that announces additions" do
      expect(container[:class]).to eq("dp-toast-container")
      expect(container["aria-live"]).to eq("polite")
      expect(container["aria-relevant"]).to eq("additions")
      expect(container["aria-atomic"]).to eq("false")
      expect(container[:role]).to eq("region")
    end

    it "is named, and translated" do
      expect(container["aria-label"]).to eq("Notifications")
      I18n.with_locale(:fr) { expect(container["aria-label"]).to eq("Notifications") }
    end

    it "limits the stack through a data attribute the controller reads" do
      expect(container["data-dp-toast-max"]).to eq("5")
      html = Capybara.string(helper.dp_toast_container(max: 3)).find("#dp-toasts", visible: :all)
      expect(html["data-dp-toast-max"]).to eq("3")
    end

    it "can be permanent: kept across Turbo morphs and visits, so toasts appended by a stream survive a page refresh" do
      expect(container["data-turbo-permanent"]).to be_nil
      html = Capybara.string(helper.dp_toast_container(permanent: true)).find("#dp-toasts", visible: :all)
      expect(html["data-turbo-permanent"]).to eq("true")
    end

    it "renders initial toasts (for example from the flash) inside the container" do
      html = Capybara.string(helper.dp_toast_container { helper.render(Deckplate::Feedback::ToastComponent.new(kind: :success)) { "Saved." } })
      expect(html).to have_css("#dp-toasts .dp-toast", text: "Saved.", visible: :all)
    end

    it "rejects a bad limit" do
      expect { helper.dp_toast_container(max: 0) }.to raise_error(ArgumentError, /max/)
    end
  end
end
