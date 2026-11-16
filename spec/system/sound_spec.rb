require "spec_helper"

# A fake AudioContext records what the controller asks WebAudio to do, so the specs can say what is played, and when.
RSpec.describe "Sound (dp-sound)", type: :system, js: true do
  FAKE_AUDIO = <<~JS.freeze
    window.__audio = { contexts: 0, oscillators: [], resumed: 0 }
    window.AudioContext = class {
      constructor() { window.__audio.contexts++; this.state = "running"; this.currentTime = 0; this.destination = {} }
      resume() { window.__audio.resumed++; return Promise.resolve() }
      createGain() { return { gain: { value: 0, setValueAtTime() {}, linearRampToValueAtTime() {}, exponentialRampToValueAtTime() {} }, connect() {} } }
      createOscillator() {
        const o = { type: "sine", frequency: { value: 0, setValueAtTime(v) { o.frequency.value = v } }, connect() {},
          start(t) { window.__audio.oscillators.push({ f: o.frequency.value, type: o.type, start: t }) }, stop() {} }
        return o
      }
    }
  JS

  before do
    driven_by :dp_cuprite
    page.driver.browser.evaluate_on_new_document(FAKE_AUDIO)
  end

  after { Deckplate.reset_configuration! }

  def audio = page.evaluate_script("window.__audio")
  def freqs = audio["oscillators"].map { _1["f"] }
  def emit(tone) = page.execute_script("window.dispatchEvent(new CustomEvent('dp:sound', { detail: { tone: #{tone.to_json} } }))")
  def stored = page.evaluate_script("localStorage.getItem('dp-sound-enabled')")

  context "when sounds are not enabled (the default)" do
    it "has no controller and never touches WebAudio, whatever the user does" do
      visit "/rails/view_components/sound_toggle/default"
      expect(page.evaluate_script("document.querySelectorAll('[data-controller~=\"dp-sound\"]').length")).to eq(0)
      page.execute_script("document.body.click()")
      emit("confirm")
      expect(audio["contexts"]).to eq(0)
    end
  end

  context "when sounds are enabled" do
    before do
      Deckplate.configure { |c| c.sounds = true }
      page.execute_script("localStorage.clear()") rescue nil
      visit "/rails/view_components/sound_toggle/default"
      page.execute_script("localStorage.removeItem('dp-sound-enabled')")
    end

    it "never plays on its own: no AudioContext exists before the first user gesture" do
      expect(page.evaluate_script("document.querySelectorAll('[data-controller~=\"dp-sound\"]').length")).to eq(1)
      emit("alert") # something asks for a sound with no gesture yet: ignored, not queued
      expect(audio["contexts"]).to eq(0)
      expect(freqs).to eq([])
    end

    it "unlocks on the first user gesture and then plays the requested tone" do
      find("body").click
      expect(audio["contexts"]).to eq(1)
      emit("confirm")
      expect(freqs).to eq([ 660, 990 ]) # two rising notes
    end

    it "plays a tick when a button is clicked" do
      find("button", text: /click me/i).click
      wait_until("the tick") { freqs.include?(880) }
      expect(audio["oscillators"].first["type"]).to eq("square")
    end

    it "has distinct, original tones for tick, confirm, alert and error" do
      find("body").click
      { "tick" => [ 880 ], "confirm" => [ 660, 990 ], "alert" => [ 440, 440 ], "error" => [ 220, 165 ] }.each do |tone, expected|
        page.execute_script("window.__audio.oscillators.length = 0")
        emit(tone)
        expect(freqs).to eq(expected), "#{tone} played #{freqs.inspect}"
      end
    end

    it "schedules notes of a tone one after the other, not all at once" do
      find("body").click
      emit("confirm")
      starts = audio["oscillators"].map { _1["start"] }
      expect(starts).to eq(starts.sort)
      expect(starts.uniq.size).to eq(2)
    end

    it "ignores an unknown tone (the name comes from a data attribute or an event)" do
      find("body").click
      emit("<script>")
      expect(freqs).to eq([])
    end

    it "can be muted with the visible switch: nothing plays, and the choice is remembered" do
      find("body").click
      find("label", text: /sound/i).click
      expect(stored).to eq("0")
      emit("confirm")
      find("button", text: /click me/i).click
      expect(freqs).to eq([])
      find("label", text: /sound/i).click
      expect(stored).to eq("1")
      emit("tick")
      expect(freqs).to eq([ 880 ])
    end

    it "restores the muted state after a reload (stored in localStorage), with the switch showing it" do
      find("label", text: /sound/i).click
      visit "/rails/view_components/sound_toggle/default"
      expect(page.find("input[role='switch']", visible: :all)).not_to be_checked
      find("body").click
      emit("alert")
      expect(freqs).to eq([])
    end

    it "keeps the mute switch state across a Turbo morph refresh" do
      find("label", text: /sound/i).click
      page.execute_script("Turbo.visit(window.location.href, { action: 'replace' })")
      sleep 0.7
      expect(page.find("input[role='switch']", visible: :all)).not_to be_checked
    end
  end

  context "with Turbo Stream toasts" do
    before do
      Deckplate.configure { |c| c.sounds = true }
      visit "/toasts"
    end

    it "plays the toast's tone when it appears, after a gesture (the click on the button is one)" do
      click_button "Sticky toast"
      expect(page).to have_css("#dp-toasts .dp-toast", text: "Stays")
      wait_until("the confirm tone") { freqs.include?(990) }
    end

    it "plays the error tone for an error toast" do
      click_button "Error toast"
      expect(page).to have_css("#dp-toasts .dp-toast[role='alert']")
      wait_until("the error tone") { freqs.include?(165) }
    end
  end
end
