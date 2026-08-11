import { Controller } from "@hotwired/stimulus"

// Progressive enhancement for the nav "More" hamburger: the <details> element
// handles open/close natively; this just closes it when the user clicks away
// or presses Escape.
export default class extends Controller {
  close() {
    this.element.removeAttribute("open")
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
