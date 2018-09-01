import { route, installSelectpickers } from './util';

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

    installSelectpickers();

    if (queuePath.includes('untagged-domains')) {
      let a = document.getElementsByName('tag_name');
      for (let i = 0; i < a.length; i++) {
        Taggify.taggify_element(a[i]);
        a[i].parentElement.addEventListener('tag_change', function() {
          let form = $(this.parentElement);
          let submit_btn = form.find('input[type=submit]');
          submit_btn.removeClass('btn-success');
        });
      }
    }
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
  $(document).on('ajax:success', '.review-add-domain-tag', (e) => {
    let a = document.getElementById('tag_name');
    a.removeAttribute('disabled');
    let form = $(a.parentElement.parentElement);
    let submit_btn = form.find('input[type=submit]');
    submit_btn.addClass('btn-success');
  });
  $(document).on('ajax:failure', '.review-add-domain-tag', (e) => {
    let a = document.getElementById('tag_name');
    a.removeAttribute('disabled');
    let form = $(a.parentElement.parentElement);
    let submit_btn = form.find('input[type=submit]');
    submit_btn.addClass('btn-danger');
  });
});
