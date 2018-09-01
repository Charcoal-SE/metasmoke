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
      const taggifyInputs = document.getElementsByName('tag_name');
      for (let i = 0; i < taggifyInputs.length; i++) {
        window.Taggify.taggify_element(taggifyInputs[i]);
        taggifyInputs[i].parentElement.addEventListener('tag_change', function () {
          const form = $(this.parentElement);
          const submitBtn = form.find('input[type=submit]');
          submitBtn.removeClass('btn-success');
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
  $(document).on('ajax:success', '.review-add-domain-tag', () => {
    const taggifyInput = document.getElementById('tag_name');
    taggifyInput.removeAttribute('disabled');
    const form = $(taggifyInput.parentElement.parentElement);
    const submitBtn = form.find('input[type=submit]');
    submitBtn.addClass('btn-success');
  });
  $(document).on('ajax:failure', '.review-add-domain-tag', () => {
    const taggifyInput = document.getElementById('tag_name');
    taggifyInput.removeAttribute('disabled');
    const form = $(taggifyInput.parentElement.parentElement);
    const submitBtn = form.find('input[type=submit]');
    submitBtn.addClass('btn-danger');
  });
});
