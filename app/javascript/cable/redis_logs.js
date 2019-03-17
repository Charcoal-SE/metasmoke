import { route } from '../util';
import cable from './cable';

$(document).ready(() => {
  $('#logs').on('click', '.redis-log-link', e => {
    e.stopPropagation();
  });
});

let redis;
route('/dev/request-log', () => {
  redis = cable.subscriptions.create('RedisLogChannel', {
    received(data) {
      const matchedLog = $('#logs div[data-log-id="' + data.key + '"]');
      let parsed_html = $.parseHTML(data.html)[1];
      if (matchedLog.length > 0 && matchedLog[0].getAttribute("precedence") < data.precedence) {
        matchedLog[0].replaceWith(parsed_html);
      }
      else {
        parsed_html.setAttribute('precedence', data.precedence);
        $('#logs').prepend(parsed_html);
      }
    }
  });
}, () => {
  if (!redis) {
    return;
  }
  redis.unsubscribe();
  redis = null;
});
