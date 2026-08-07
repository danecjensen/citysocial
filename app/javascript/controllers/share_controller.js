import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["native", "status"]
  static values = { title: String, url: String }

  connect() {
    this.nativeTarget.hidden = !this.nativeShareAvailable
  }

  async copy() {
    try {
      await this.copyUrl()
      this.announce("Link copied.")
    } catch (_error) {
      this.announce("Could not copy the link. Copy the page address from your browser instead.")
    }
  }

  async native() {
    if (!this.nativeShareAvailable) return

    try {
      await navigator.share({ title: this.titleValue, url: this.urlValue })
      this.announce("Shared.")
    } catch (error) {
      this.announce(error.name === "AbortError" ? "Share canceled." : "Could not share. Copy the link instead.")
    }
  }

  get nativeShareAvailable() {
    return typeof navigator.share === "function"
  }

  async copyUrl() {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(this.urlValue)
      return
    }

    const field = document.createElement("textarea")
    field.value = this.urlValue
    field.setAttribute("readonly", "")
    field.style.position = "fixed"
    field.style.left = "-9999px"
    document.body.appendChild(field)
    field.select()

    let copied = false
    try {
      copied = document.execCommand("copy")
    } finally {
      field.remove()
    }
    if (!copied) throw new Error("Copy command failed")
  }

  announce(message) {
    this.statusTarget.textContent = message
  }
}
