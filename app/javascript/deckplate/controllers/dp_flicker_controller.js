import { Controller } from "@hotwired/stimulus"

// Blinks an outline when the element was inserted by a Turbo Stream (a value that just changed), not when the page loads or a normal
// Turbo visit renders it. The stream's render runs synchronously and Stimulus connects the new element in a microtask, so a flag set
// around the render and cleared by a timeout is enough to tell the two apart.
let streaming = false

document.addEventListener("turbo:before-stream-render", (event) => {
  const render = event.detail.render
  event.detail.render = (stream) => {
    streaming = true
    render(stream)
    setTimeout(() => { streaming = false }, 0)
  }
})

export default class extends Controller {
  connect() {
    if (streaming) this.flicker()
  }

  disconnect() { clearTimeout(this.timer) }

  flicker() {
    this.element.classList.add("dp-readout--flicker")
    this.timer = setTimeout(() => this.element.classList.remove("dp-readout--flicker"), 700)
  }
}
