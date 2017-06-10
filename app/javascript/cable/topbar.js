import createDebug from 'debug';
import moment from 'moment';

import cable from './cable';

const debug = createDebug('ms:topbar');

$(() => {
  cable.subscriptions.create('TopbarChannel', {
    received(arg) {
      const { review, commit, last_ping: lastPing } = arg;
      debug('received', arg);
      if (review != null) {
        $('.navbar .reviews-count').text(review || '');
      }
      if (commit != null) {
        if ($('.commit-sha').data('sha') === commit) {
          return; // don’t worry! nothing’s changed!
        }
        $('.commit-sha').attr('href', `https://github.com/Charcoal-SE/metasmoke/commit/${commit}`)
                        .children('code').text(commit.slice(0, 7));
        $('#metasmoke-deployed-banner').slideDown();
      }
      if (lastPing != null) {
        $('.navbar .status').data('last-ping', lastPing);
      }
    }
  });

  setInterval(() => {
    const $status = $('.navbar .status');
    const lastPing = parseFloat($status.data('last-ping')) * 1e3;
    const ago = Date.now() - lastPing;
    const title = `Last ping was ${moment(lastPing).fromNow()}.`;
    let status = 'critical';
    if (ago < 90e3) {
      status = 'good';
    } else if (ago < 3 * 60e3) {
      status = 'warning';
    }
    $('.navbar-toggle').removeClass('status-good status-warning status-critical')
                       .addClass(`status-${status}`);
    $status.removeClass('status-good status-warning status-critical')
           .addClass(`status-${status}`)
           .attr('data-original-title', title)
           .tooltip()
           .parent()
             .find('.status + .tooltip .tooltip-inner')
             .text(title);
  }, 1000);
});
