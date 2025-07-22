import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.modal = document.getElementById("report-modal")
    this.button = document.getElementById("report-button")
    this.closeBtn = document.getElementById("report-close")
    this.cancelBtn = document.getElementById("report-cancel")

    this.button.addEventListener("click", () => this.show())
    this.closeBtn.addEventListener("click", () => this.hide())
    this.cancelBtn.addEventListener("click", () => this.hide())
  }

  show() {
    this.modal.classList.remove("hidden")
  }

  hide() {
    this.modal.classList.add("hidden")
  }
}
