$(() => {
  $(document).on("ajax:success", "a[data-remote]", (e, data, status, xhr) => {
    $(".post-cell-" + e.target.dataset["postId"]).remove();
    e.target.closest("tr").remove();
  });
});
