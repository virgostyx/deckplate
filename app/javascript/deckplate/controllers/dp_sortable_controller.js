import { Controller } from "@hotwired/stimulus"

// Reorderable list (Data::SortableListComponent). The DOM order is the order: the hidden form fields sit inside the items. Two ways to move
// an item: the up/down buttons (every item has them; they work for keyboard, touch and screen readers) and a pointer drag on the grip.
// Without the script the list is a plain ordered list: the controls only appear once `data-dp-sortable-ready` is set.
export default class extends Controller {
  static targets = ["list", "status"]
  static values = { movedTemplate: String }

  connect() {
    this.refresh()
    this.element.dataset.dpSortableReady = ""
  }

  move(event) {
    const button = event.currentTarget
    const item = button.closest("li")
    const other = event.params.direction < 0 ? item.previousElementSibling : item.nextElementSibling
    if (!other) return
    event.params.direction < 0 ? other.before(item) : other.after(item)
    this.moved(item, button)
  }

  grab(event) {
    if (event.button) return
    event.preventDefault() // no text selection while dragging
    this.dragging = event.currentTarget.closest("li")
    this.from = this.items.indexOf(this.dragging)
    this.dragging.classList.add("dp-sortable__item--dragging")
    this.element.setPointerCapture(event.pointerId) // on the list, which never moves: moving the item would drop the capture
  }

  drag(event) {
    if (!this.dragging) return
    const next = this.items.filter((li) => li !== this.dragging).find((li) => {
      const box = li.getBoundingClientRect()
      return event.clientY < box.top + box.height / 2
    })
    if ((next ?? null) !== this.dragging.nextElementSibling) this.listTarget.insertBefore(this.dragging, next ?? null)
  }

  drop() {
    const item = this.dragging
    if (!item) return
    this.dragging = null
    item.classList.remove("dp-sortable__item--dragging")
    if (this.items.indexOf(item) !== this.from) this.moved(item)
  }

  get items() { return [...this.listTarget.children] }

  moved(item, button) {
    this.refresh()
    if (button) (button.disabled ? button.parentElement.querySelector("button:not(:disabled)") : button).focus() // moving the node dropped the focus
    const text = item.querySelector(".dp-sortable__label").textContent
    const values = { item: text, position: this.items.indexOf(item) + 1, total: this.items.length }
    this.statusTarget.textContent = this.movedTemplateValue.replace(/%\{(\w+)\}/g, (_, key) => values[key])
    this.dispatch("reorder", { detail: { ids: this.items.map((li) => li.dataset.dpSortableId) } })
  }

  refresh() {
    const items = this.items
    items.forEach((li, i) => {
      const [up, down] = li.querySelectorAll(".dp-sortable__move")
      up.disabled = i === 0
      down.disabled = i === items.length - 1
    })
  }
}
