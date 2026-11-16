require "spec_helper"

# Sound is opt-in (config.sounds = true) and never the only way to get an information: every hook below disappears when it is off.
RSpec.describe "Sound wiring" do
  after { Deckplate.reset_configuration! }

  describe "dp_sound_attrs (helper)", type: :helper do
    it "is empty by default" do
      expect(helper.dp_sound_attrs).to eq({})
    end

    it "attaches the controller and the event bus when sounds are enabled" do
      Deckplate.configure { |c| c.sounds = true }
      attrs = helper.dp_sound_attrs
      expect(attrs[:data][:controller]).to eq("dp-sound")
      expect(attrs[:data][:action]).to include("dp:sound@window->dp-sound#fromEvent", "turbo:before-morph-attribute->dp-sound#keepState")
    end

    it "is included by dp_root" do
      Deckplate.configure { |c| c.sounds = true }
      expect(Capybara.string(helper.dp_root { "x" })).to have_css(".dp-root[data-controller='dp-sound']")
      Deckplate.reset_configuration!
      expect(Capybara.string(helper.dp_root { "x" })).not_to have_css("[data-controller]")
    end
  end

  describe "Button", type: :component do
    it "has no sound hook by default" do
      render_inline(Deckplate::ButtonComponent.new(label: "Go"))
      expect(page.find("button")["data-action"]).to be_nil
    end

    it "plays a tick on click when sounds are enabled, keeping the caller's own action" do
      Deckplate.configure { |c| c.sounds = true }
      render_inline(Deckplate::ButtonComponent.new(label: "Go", data: { action: "click->mine#go" }))
      expect(page.find("button")["data-action"]).to eq("click->dp-sound#play click->mine#go")
      expect(page.find("button")["data-dp-sound-tone-param"]).to eq("tick")
    end
  end

  describe "Toast", type: :component do
    it "carries a tone by kind only when sounds are enabled" do
      render_inline(Deckplate::Feedback::ToastComponent.new(kind: :success)) { "x" }
      expect(page.find(".dp-toast")["data-dp-toast-tone-value"]).to be_nil
      Deckplate.configure { |c| c.sounds = true }
      { info: "confirm", success: "confirm", warning: "alert", danger: "error" }.each do |kind, tone|
        render_inline(Deckplate::Feedback::ToastComponent.new(kind:)) { "x" }
        expect(page.find(".dp-toast")["data-dp-toast-tone-value"]).to eq(tone)
      end
    end
  end

  describe "SoundToggleComponent (the visible mute control)", type: :component do
    it "renders nothing when sounds are not enabled" do
      render_inline(Deckplate::SoundToggleComponent.new)
      expect(page).not_to have_css("input")
    end

    it "renders a labelled switch, on by default, wired to the controller, when sounds are enabled" do
      Deckplate.configure { |c| c.sounds = true }
      render_inline(Deckplate::SoundToggleComponent.new)
      input = page.find("input[role='switch']", visible: :all)
      expect(page).to have_css("label.dp-toggle .dp-toggle__label", text: "Sound")
      expect(input).to be_checked
      expect(input["data-dp-sound-target"]).to eq("toggle")
      expect(input["data-action"]).to eq("change->dp-sound#setEnabled")
      I18n.with_locale(:fr) { render_inline(Deckplate::SoundToggleComponent.new) }
      expect(page).to have_css(".dp-toggle__label", text: "Son")
    end

    it "takes a custom label and passes html options to the switch" do
      Deckplate.configure { |c| c.sounds = true }
      render_inline(Deckplate::SoundToggleComponent.new(label: "Beeps", id: "snd"))
      expect(page).to have_css("input#snd", visible: :all)
      expect(page).to have_css(".dp-toggle__label", text: "Beeps")
    end
  end
end
