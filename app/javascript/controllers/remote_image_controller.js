import { Controller } from "@hotwired/stimulus"

// Remote event artwork is outside CitySocial's control. If a venue removes an
// image or blocks hotlinking, replace the broken image with the server-rendered
// category placeholder instead of leaving the browser's broken-image chrome.
export default class extends Controller {
  static targets = ["image", "placeholder"]

  connect() {
    this.verify()
  }

  verify() {
    if (this.imageTarget.complete && this.imageTarget.naturalWidth === 0) {
      this.showPlaceholder()
    }
  }

  showPlaceholder() {
    this.imageTarget.hidden = true
    this.placeholderTarget.hidden = false
  }
}
