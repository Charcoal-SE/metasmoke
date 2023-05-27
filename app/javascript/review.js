import { onLoad, route, installSelectpickers } from './util';

onLoad(() => {
  $(document.body).on('ajax:success', 'a.feedback-button[data-remote]', e => {
    if (!$(e.target).hasClass('on-post')) {
      $('.post-cell-' + e.target.dataset.postId).remove();
      e.target.closest('tr').remove();
    }
  });
});

route(/\/review\/[\w-]+\/?\d*$/i, async () => {
  const queuePath = (/(\/review\/[\w-]+)\/?\d*$/i).exec(location.pathname)[1];
  const hasItemID = location.pathname.match(/\/review\/[\w-]+\/?\d+$/i);

  const adjustReviewPageTitle = () => {
    try {
      const pathname = window.location.pathname;
      const isHistory = pathname.endsWith('/history');
      const historyText = isHistory ? 'history for ' : '';
      const reviewTypeText = pathname.split('/')[2].split('-').map(word => word[0].toUpperCase() + word.slice(1)).join(' ');
      const submitLink = $('.review-submit-link');
      const relativeUrl = (submitLink.length ? submitLink.first().attr('href') : pathname).replace(/\?.*/, '');
      const reviewID = (relativeUrl.match(/\d+/) || [''])[0];
      const reviewIDText = reviewID ? `: Review #${reviewID}` : '';
      let title = document.title;
      let extraText = '';
      if (!isHistory) {
        if (pathname.indexOf('/review/posts') === 0) {
          const titleEl = $('h4:not(.modal-title)');
          // If the titleEl doesn't exist, then all reviews are done.
          if (titleEl.length > 0) {
            const postTitle = $('h4')[0].firstChild.textContent.trim();
            const postID = $('h4 a').attr('href').replace(/^\D*(\d+)/, '$1');
            extraText = `: post ID ${postID}: ${postTitle}`;
          }
        }
        else if (pathname.indexOf('/review/untagged-domains') === 0) {
          extraText = `: ${$('h3').first().text()}`;
        }
      }
      title = `Review ${historyText}${reviewTypeText}${reviewIDText}${extraText} - metasmoke`;
      document.title = title;
      if (relativeUrl === pathname) {
        history.replaceState({}, title, relativeUrl);
      }
      else {
        history.pushState({}, title, relativeUrl);
      }
    }
    catch (err) {
      console.error(err); // eslint-disable-line no-console
    }
  };

  const loadNextPost = async () => {
    const filters = $('.review-filter').toArray();
    const params = {};
    filters.forEach(e => {
      const el = $(e);
      const val = el.val();
      if (val) {
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

    adjustReviewPageTitle();
    installSelectpickers();
    $(window).trigger('MS-review-loaded');
  };

  if (!hasItemID) {
    loadNextPost();
  }

  // The document will continue to exist even if we navigate to another page.
  // Thus, when we navigate back to this route, an additional listener will
  // be added. The document.body is replaced upon each SPA navigation.
  $(document.body).on('ajax:success', '.review-submit-link', () => {
    $('.review-item-container').text('Loading...');
    loadNextPost();
  });

  $(document.body).on('click', '.review-next-link', () => {
    $('.review-item-container').text('Loading...');
    loadNextPost();
  });

  $('#filter-button').click(() => {
    $('.review-item-container').text('Loading...');
    loadNextPost();
  });

  // Sort the site filter list
  const siteSelect = $('#site_id');
  const siteSelectOptions = siteSelect.find('option').toArray();
  siteSelect.append(siteSelectOptions.sort((a, b) => {
    if (a.value < 5 || b.value < 5) {
      return a.value - b.value;
    }
    return a.textContent.trim().localeCompare(b.textContent.trim());
  }));
  // Keep site filter selection through page reload
  siteSelect.val(localStorage['review-site-filter'] || 0);
  siteSelect.on('change', () => {
    localStorage['review-site-filter'] = siteSelect.val();
  });

  adjustReviewPageTitle();
});

route(/\/review\/untagged-domains(\/\d*)?/, () => {
  $(document.body).on('ajax:success', '.review-add-domain-tag', (e, data) => {
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
