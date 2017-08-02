import { onLoad } from './util';
import createDebug from 'debug';

const debug = createDebug('ms:flag_conditions');

onLoad(() => {
  window.previewHandler = ev => {
    let filter = $(ev.target).attr('data-filter') || '';

    debug(`preview-flag-conditions: click, filter=${filter}`);
    $.ajax({
      url: `/flagging/conditions/preview?filter=${filter}`,
      data: $('form').serialize()
    });
  };

  $('.preview-flag-conditions-button').on('click', previewHandler);
});
