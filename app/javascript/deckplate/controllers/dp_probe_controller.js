import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() { (window.__dp ||= []).push(`connect:${this.element.id}`) }
  disconnect() { (window.__dp ||= []).push(`disconnect:${this.element.id}`) }
}
