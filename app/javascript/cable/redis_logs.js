import { route } from '../util';
import cable from './cable';

$( document ).ready(function() {
  $("#logs").on('click', '.redis-log-link', function(e) {
    e.stopPropagation();
  });
});

/* TODO: Add websockets to the other pages */
let redis;
route('/redis_log/index', () => {
  redis = cable.subscriptions.create('RedisLogChannel', {
    received(data) {
      var matched_log = $('#logs div[data-log-id="'+ data.key +'"]');
      // console.log($.parseHTML(data.html)[1]);
      if (matched_log.length > 0) {
        // console.log(matched_log);
        matched_log[0].replaceWith($.parseHTML(data.html)[1]);
      } else {
        $("#logs").prepend($.parseHTML(data.html)[1]);
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
