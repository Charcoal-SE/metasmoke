import createDebug from 'debug';
import { onLoad } from './util';

/* global previewHandler */

const debug = createDebug('ms:flag_conditions');

onLoad(() => {
  window.previewHandler = ev => {
    const filter = $(ev.target).attr('data-filter') || '';

    debug(`preview-flag-conditions: click, filter=${filter}`);
    $.ajax({
      url: `/flagging/conditions/preview?filter=${filter}`,
      data: $('form').serialize()
    });
  };

  $('.preview-flag-conditions-button').on('click', previewHandler);
});
