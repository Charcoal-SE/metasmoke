import { onLoad } from './util';

onLoad(() => {
  $('input#preview-flag-conditions-button').on('click', () => {
    $.ajax({
      url: '/flagging/conditions/preview',
      data: $('form').serialize()
    });
  });
});
