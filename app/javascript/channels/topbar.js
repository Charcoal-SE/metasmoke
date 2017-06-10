import moment from 'moment';

$(document).on('ready turbolinks:load', function() {
  App.cable.subscriptions.create('TopbarChannel', {
    received({ review, commit, last_ping }) {
      console.log(review, commit, last_ping);
      if (review != null) {
        $('.navbar .reviews-count').text(review || '');
      }
      if (commit != null) {
        $('.commit').attr('href', `https://github.com/Charcoal-SE/metasmoke/commit/${commit}`)
                    .children('code').text(commit.slice(0, 7))
        $('.nav + div').prepend($(`
          <div class='alert alert-warning' role='alert'>
            This page has been updated. <a href='${location.href}' data-turbolinks='false'>Refresh</a> to get the latest version.
          </div>
        `));
      }
      if (last_ping != null) {
        $('.navbar .status').data('last-ping', last_ping)
      }
    }
  })

  setInterval(() => {
    const $status = $('.navbar .status')
    const last_ping = parseFloat($status.data('last-ping')) * 1e3
    const ago = Date.now() - last_ping
    const title = `Last ping was ${moment(last_ping).fromNow()}.`
    let status = 'critical'
    if (ago < 90e3) {
      status = 'good'
    } else if (ago < 3 * 60e3) {
      status = 'warning'
    }
    $('.navbar-toggle').removeClass('status-good status-warning status-critical')
                       .addClass(`status-${status}`)
    $status.removeClass('status-good status-warning status-critical')
           .addClass(`status-${status}`)
           .attr('data-original-title', title)
           .tooltip()
           .parent()
             .find('.status + .tooltip .tooltip-inner')
             .text(title)
  }, 1000);
});
