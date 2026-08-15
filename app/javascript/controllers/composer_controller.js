import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["poll"]

  connect() {
    this.change()
  }

  change() {
    const kind = this.element.querySelector("select[name='post[kind]']")?.value
    if (this.hasPollTarget) this.pollTarget.hidden = kind !== "poll"
  }
}
