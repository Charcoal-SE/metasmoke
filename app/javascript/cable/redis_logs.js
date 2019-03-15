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
      if (matchedLog.length > 0) {
        matchedLog[0].replaceWith($.parseHTML(data.html)[1]);
      }
      else {
        $('#logs').prepend($.parseHTML(data.html)[1]);
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
