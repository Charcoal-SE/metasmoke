import { route } from '../util';
import cable from './cable';

$(document).ready(() => {
  $('#logs').on('click', '.redis-log-link', e => {
    e.stopPropagation();
  });
});

function getLogs(data) {
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

let redis;
route(/^\/dev\/request-log.*$/, () => {
  const params = { channel: 'RedisLogChannel' };
  const status = location.pathname.match(/^\/dev\/request-log\/status\/([^/]*).*$/);
  const path = location.pathname.match(/^\/dev\/request-log\/by_path\/(\w*)\/(.*)\.[^.]*$/);
  const session = location.pathname.match(/^\/dev\/request-log\/session\/(.*)$/);
  if (status) {
    params.status = status[1];
  }
  else if (path) {
    params.path = decodeURIComponent(path[2]);
  }
  else if (session) {
    params.session = session[1];
  }
  redis = cable.subscriptions.create(params, {
    received(data) {
      getLogs(data);
    }
  });
}, () => {
  if (!redis) {
    return;
  }
  redis.unsubscribe();
  redis = null;
});
