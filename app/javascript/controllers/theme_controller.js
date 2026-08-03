import { Controller } from "@hotwired/stimulus"

// Toggles the `.dark` / `.light` class on <html> and persists the choice.
// The pre-paint script in the layout head applies the stored choice before
// first render to avoid a flash; this controller just flips + saves it.
export default class extends Controller {
  toggle() {
    const root = document.documentElement
    const systemDark = window.matchMedia("(prefers-color-scheme: dark)").matches
    const isDark = root.classList.contains("dark") || (systemDark && !root.classList.contains("light"))

    root.classList.remove("dark", "light")
    if (isDark) {
      root.classList.add("light")
      localStorage.setItem("theme", "light")
    } else {
      root.classList.add("dark")
      localStorage.setItem("theme", "dark")
    }
  }
}
