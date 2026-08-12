import { Controller } from "@hotwired/stimulus"

// Drives the mobile nav drawer. The hamburger button toggles the collapsible
// panel, swaps the open/close icon, and keeps aria-expanded in sync. On lg+ the
// panel is always visible via CSS (`lg:flex` beats the base `hidden`), so this
// controller only does anything on small screens. The drawer closes on outside
// click and Escape; Turbo navigation replaces the bar entirely, so links close
// it for free.
export default class extends Controller {
  static targets = ["panel", "button", "openIcon", "closeIcon"]

  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.remove("hidden")
    this.panelTarget.classList.add("flex")
    this.reflect(true)
  }

  close() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.add("hidden")
    this.panelTarget.classList.remove("flex")
    this.reflect(false)
  }

  closeOnOutside(event) {
    if (this.isOpen && !this.element.contains(event.target)) this.close()
  }

  reflect(open) {
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", String(open))
    if (this.hasOpenIconTarget) this.openIconTarget.classList.toggle("hidden", open)
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.toggle("hidden", !open)
  }

  get isOpen() {
    return this.hasPanelTarget && !this.panelTarget.classList.contains("hidden")
  }
}
