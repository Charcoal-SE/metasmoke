import createDebug from 'debug';

import { onLoad } from './util';

const debug = createDebug('ms:stack_exchange_users');

onLoad(() => {
  $('img.stack_exchange_user_flair').error(function () {
    $(this).replaceWith(`<h3><img src="${$(this).data('site-logo')}">${$(this).data('username')} (${$(this).data('reputation')})</h3><p class="text-danger">(user has been deleted)</p>`);
  });
  $('.not-spammer').click(function (e) {
    e.preventDefault();
    $.ajax({
      type: 'POST',
      url: '/spammers/dead/' + $(this).data('uid')
    }).done(data => {
      if (data === 'ok') {
        const $tr = $(this).parent().parent();
        $tr.fadeOut(200, () => $tr.remove());
      } else {
        debug('something went wrong: update returned', data);
      }
    }).fail(jqXHR => debug('something went wrong: update failed:', jqXHR.status, jqXHR.responseText, '\n', jqXHR));
  });
});
