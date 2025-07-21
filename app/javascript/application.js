import "@hotwired/turbo-rails"
import "controllers"
import Rails from "@rails/ujs"
Rails.start()

document.addEventListener("turbo:load", function () {
  const toggleBtn = document.getElementById("toggle-right-sidebar");
  const sidebar = document.getElementById("right-sidebar");

  if (toggleBtn && sidebar) {
    toggleBtn.addEventListener("click", () => {
      sidebar.classList.toggle("hidden");
    });
  }
});

