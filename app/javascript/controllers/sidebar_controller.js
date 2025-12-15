import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]

  connect() {
    // Check localStorage for saved state
    const isCollapsed = localStorage.getItem("sidebarCollapsed") === "true"
    if (isCollapsed) {
      this.sidebarTarget.classList.add("collapsed")
    }
  }

  toggle() {
    this.sidebarTarget.classList.toggle("collapsed")
    const isCollapsed = this.sidebarTarget.classList.contains("collapsed")
    localStorage.setItem("sidebarCollapsed", isCollapsed.toString())
  }
}
