import { route } from './util';

$(() => {
  $(document).on('ajax:success', 'a.feedback-button[data-remote]', e => {
    if (!$(e.target).hasClass('on-post')) {
      $('.post-cell-' + e.target.dataset.postId).remove();
      e.target.closest('tr').remove();
    }
  });
});

route(/\/review\/\w+/i, async () => {
  const loadNextPost = async () => {
    const response = await fetch(location.pathname + '/next', {
      credentials: 'include'
    });
    const html = await response.text();
    $('.review-item-container').html(html);
  };

  loadNextPost();

  $(document).on('ajax:success', '.review-submit-link', () => {
    $('.review-item-container').text('Loading...');
    loadNextPost();
  });
});
