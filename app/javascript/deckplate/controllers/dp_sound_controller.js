import { Controller } from "@hotwired/stimulus"

// Original beeps synthesised with WebAudio (no audio files). Never plays by itself: the AudioContext is created on the first user
// gesture, and requests before that are ignored. The mute choice lives in localStorage and is driven by the SoundToggle.
// Put on <body>/dp_root by `dp_sound_attrs` (config.sounds). Tones are requested by Button clicks or `dp:sound` window events.
const TONES = {
  tick: { type: "square", notes: [ 880 ], length: 0.05, volume: 0.04 },
  confirm: { type: "sine", notes: [ 660, 990 ], length: 0.09, volume: 0.08 },
  alert: { type: "triangle", notes: [ 440, 440 ], length: 0.12, volume: 0.1 },
  error: { type: "sawtooth", notes: [ 220, 165 ], length: 0.14, volume: 0.06 }
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
    const spec = Object.hasOwn(TONES, name) ? TONES[name] : null
    if (!spec || !this.enabled || !this.audio) return
    const ctx = this.audio
    spec.notes.forEach((frequency, index) => {
      const start = ctx.currentTime + index * (spec.length + 0.02)
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = spec.type
      osc.frequency.setValueAtTime(frequency, start)
      gain.gain.setValueAtTime(spec.volume, start)
      gain.gain.exponentialRampToValueAtTime(0.0001, start + spec.length)
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.start(start)
      osc.stop(start + spec.length)
    })
  }

  syncToggle() { if (this.hasToggleTarget) this.toggleTarget.checked = this.enabled }

  read() {
    try { return localStorage.getItem(KEY) } catch { return null }
  }
}
