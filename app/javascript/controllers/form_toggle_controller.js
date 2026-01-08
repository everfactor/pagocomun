import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "toggleable"]
  static values = {
    showIf: String
  }

  connect() {
    this.toggle()
  }

  toggle() {
    const value = this.inputTarget.value
    const shouldShow = value === this.showIfValue

    this.toggleableTargets.forEach(target => {
      target.style.display = shouldShow ? 'block' : 'none'
    })
  }
}
