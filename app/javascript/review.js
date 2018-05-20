import { route } from './util';

$(() => {
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
    const response = await fetch(queuePath + '/next', {
      credentials: 'include'
    });
    const html = await response.text();
    $('.review-item-container').html(html);
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
});

route(/\/review\/untagged-domains(\/\d*)?/, () => {
  $(document).on('click', '.review-add-domain-tag input[type=submit]', ev => {
    const tags = $(ev.target).parent().find('#tag_list').children('option').map((i, e) => $(e).val());
    const requested = $(ev.target).parent().find('.tag-name').val();
    if (tags.toArray().indexOf(requested) === -1) {
      const ok = confirm(`${requested} doesn't exist yet. Sure you want to create it?`);
      if (!ok) {
        return false;
      }
    }
  });

  $(document).on('ajax:success', '.review-add-domain-tag', (e, data) => {
    const $noTags = $('.no-tags');
    if ($noTags.length > 0) {
      $noTags.remove();
      $('.domain-tag-list p').html('Tagged with: ' + data);
    }
    else {
      $('.domain-tag-list p').append(data);
    }
    $(e.target).find('input[type=text]').val('');
  });
});
