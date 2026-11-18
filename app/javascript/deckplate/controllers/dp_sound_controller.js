import { Controller } from "@hotwired/stimulus"

// Original beeps synthesised with WebAudio (no audio files). Never plays by itself: the AudioContext is created on the first user
// gesture, and requests before that are ignored. The mute choice lives in localStorage and is driven by the SoundToggle.
// Put on <body>/dp_root by `dp_sound_attrs` (config.sounds). Tones are requested by Button clicks or `dp:sound` window events.
// Each theme has its own pack of four tones (ADR 0018), chosen when the tone is played, so the theme switcher changes the sound at once;
// a theme without a pack (a custom theme) uses the classic one. A tone is [oscillator type, note frequencies in Hz, note length in s, volume].
const PACKS = {
  classic: { tick: [ "square", [ 880 ], 0.05, 0.04 ], confirm: [ "sine", [ 660, 990 ], 0.09, 0.08 ], alert: [ "triangle", [ 440, 440 ], 0.12, 0.1 ], error: [ "sawtooth", [ 220, 165 ], 0.14, 0.06 ] },
  azure: { tick: [ "sine", [ 1046 ], 0.04, 0.05 ], confirm: [ "sine", [ 784, 1175 ], 0.08, 0.08 ], alert: [ "sine", [ 587, 587 ], 0.11, 0.1 ], error: [ "triangle", [ 247, 185 ], 0.14, 0.08 ] },
  nocturne: { tick: [ "sine", [ 523 ], 0.05, 0.02 ], confirm: [ "sine", [ 392, 587 ], 0.1, 0.04 ], alert: [ "sine", [ 330, 330 ], 0.13, 0.05 ], error: [ "triangle", [ 147, 110 ], 0.16, 0.04 ] },
  daylight: { tick: [ "triangle", [ 1175 ], 0.04, 0.06 ], confirm: [ "triangle", [ 784, 1318 ], 0.08, 0.09 ], alert: [ "square", [ 523, 523 ], 0.1, 0.06 ], error: [ "square", [ 262, 196 ], 0.13, 0.05 ] },
  crimson: { tick: [ "square", [ 988 ], 0.04, 0.045 ], confirm: [ "sawtooth", [ 740, 1109 ], 0.07, 0.07 ], alert: [ "sawtooth", [ 698, 698 ], 0.09, 0.12 ], error: [ "sawtooth", [ 196, 147 ], 0.16, 0.09 ] },
  verdant: { tick: [ "sine", [ 740 ], 0.03, 0.05 ], confirm: [ "sine", [ 587, 880 ], 0.07, 0.08 ], alert: [ "triangle", [ 494, 494 ], 0.11, 0.09 ], error: [ "triangle", [ 185, 139 ], 0.15, 0.08 ] },
  "high-contrast": { tick: [ "square", [ 1000 ], 0.08, 0.08 ], confirm: [ "square", [ 800, 1200 ], 0.12, 0.1 ], alert: [ "square", [ 600, 600 ], 0.18, 0.12 ], error: [ "square", [ 200, 150 ], 0.2, 0.1 ] }
}
const KEY = "dp-sound-enabled"

export default class extends Controller {
  static targets = [ "toggle" ]

  connect() {
    this.enabled = this.read() !== "0"
    this.syncToggle()
    this.unlock = this.unlock.bind(this)
    for (const type of [ "pointerdown", "keydown" ]) window.addEventListener(type, this.unlock, { capture: true })
  }

  disconnect() {
    for (const type of [ "pointerdown", "keydown" ]) window.removeEventListener(type, this.unlock, { capture: true })
  }

  toggleTargetConnected() { this.syncToggle() }

  unlock() {
    const Context = window.AudioContext || window.webkitAudioContext
    if (!this.audio && Context) this.audio = new Context()
    this.audio?.resume?.()
  }

  play(event) { this.tone(event.params.tone) }
  fromEvent(event) { this.tone(event.detail?.tone) }

  setEnabled(event) {
    this.enabled = event.target.checked
    try { localStorage.setItem(KEY, this.enabled ? "1" : "0") } catch { /* storage unavailable: the choice lasts for this page */ }
  }

  // Turbo morph: the switch shows the user's choice, not the server's default
  keepState(event) {
    if (this.hasToggleTarget && event.target === this.toggleTarget && event.detail.attributeName === "checked") event.preventDefault()
  }

  tone(name) {
    const theme = this.element.closest("[data-dp-theme]")?.dataset.dpTheme
    const pack = Object.hasOwn(PACKS, theme) ? PACKS[theme] : PACKS.classic
    const spec = Object.hasOwn(pack, name) ? pack[name] : null
    if (!spec || !this.enabled || !this.audio) return
    const [ type, notes, length, volume ] = spec
    const ctx = this.audio
    notes.forEach((frequency, index) => {
      const start = ctx.currentTime + index * (length + 0.02)
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = type
      osc.frequency.setValueAtTime(frequency, start)
      gain.gain.setValueAtTime(volume, start)
      gain.gain.exponentialRampToValueAtTime(0.0001, start + length)
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.start(start)
      osc.stop(start + length)
    })
  }

  syncToggle() { if (this.hasToggleTarget) this.toggleTarget.checked = this.enabled }

  read() {
    try { return localStorage.getItem(KEY) } catch { return null }
  }
}
