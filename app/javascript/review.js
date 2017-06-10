$(() => {
  $(document).on('ajax:success', 'a[data-remote]', e => {
    $('.post-cell-' + e.target.dataset.postId).remove();
    e.target.closest('tr').remove();
  });
});
