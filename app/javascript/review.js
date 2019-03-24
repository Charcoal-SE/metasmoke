import { onLoad, route, installSelectpickers } from './util';

onLoad(() => {
  $(document).on('ajax:success', 'a.feedback-button[data-remote]', e => {
    if (!$(e.target).hasClass('on-post')) {
      $('.post-cell-' + e.target.dataset.postId).remove();
      e.target.closest('tr').remove();
    }
  });
});

route(/\/review\/[\w-]+\/?\d*$/i, async () => {
  const queuePath = (/(\/review\/[\w-]+)\/?\d*$/i).exec(location.pathname)[1];
  const hasItemID = location.pathname.match(/\/review\/[\w-]+\/?\d+$/i);

  const loadNextPost = async () => {
    const filters = $('.review-filter').toArray();
    const params = {};
    filters.forEach(e => {
      const el = $(e);
      const val = el.val();
      if (!!val) {
        params[el.attr('name')] = val;
      }
    });
    const url = new URL(queuePath + '/next', `${location.protocol}//${location.host}`);
    const search = new URLSearchParams(params);
    url.search = search;

    const response = await fetch(url, {
      credentials: 'include'
    });
    const html = await response.text();
    $('.review-item-container').html(html);

    installSelectpickers();
  };

  if (!hasItemID) {
    loadNextPost();
  }

  $(document).on('ajax:success', '.review-submit-link', () => {
    $('.review-item-container').text('Loading...');
    loadNextPost();
  });

  $(document).on('click', '.review-next-link', () => {
    $('.review-item-container').text('Loading...');
    loadNextPost();
  });

  $('#filter-button').click(() => {
    $('.review-item-container').text('Loading...');
    loadNextPost();
  });
});

route(/\/review\/untagged-domains(\/\d*)?/, () => {
  $(document).on('ajax:success', '.review-add-domain-tag', (e, data) => {
    const $noTags = $('.no-tags');
    if ($noTags.length > 0) {
      $noTags.remove();
      $('.domain-tag-list p').html('Tagged with: ' + data);
    }
    else {
      $('.domain-tag-list p').append(data);
    }
    $(e.target).find('select').selectpicker('val', null);
  });
});
