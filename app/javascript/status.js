$(document).on("turbolinks:load", () => {
  $(".expand-status-table").on("click", e => {
    $(".hidden-row").toggle();
    e.preventDefault();
  });
});
