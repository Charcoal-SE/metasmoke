import createDebug from 'debug';

import { onLoad } from './util';

const debug = createDebug('ms:user_site_settings');

onLoad(() => {
  $('#red-button').on('click', function () {
    const flagsEnabled = $(this).is(':checked');
    $.ajax({
      type: 'POST',
      url: '/flagging/preferences/enable',
      data: {
        enable: flagsEnabled
      }
    }).done(() => debug('saved :)')).error(xhr => debug('save failed', xhr));
  });
});
