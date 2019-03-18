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
      const parsedHtml = $.parseHTML(data.html)[1];
      if (matchedLog.length === 0) {
        parsedHtml.setAttribute('precedence', data.precedence);
        $('#logs').prepend(parsedHtml);
      }
      else if (matchedLog[0].getAttribute('precedence') < data.precedence) {
        matchedLog[0].replaceWith(parsedHtml);
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
