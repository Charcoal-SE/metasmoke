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
          return; // Don’t worry! nothing’s changed!
        }
        $('.commit-sha').attr('href', `https://github.com/Charcoal-SE/metasmoke/commit/${commit}`)
                        .children('code').text(commit.slice(0, 7));
        $('#metasmoke-deployed-banner').slideDown();
      }
      if (lastPing != null) {
        $('.navbar .status').data('last-ping', lastPing);
        // Update the display for the new last ping time.
        updateStatus();
      }
    }
  });

  function setOnlyStatusClassIfNotHasClass(el, statusClass) {
    if (!el.hasClass(statusClass)) {
      el.removeClass('status-good status-warning status-critical')
        .addClass(statusClass);
    }
  }

  let updateStatusTimer = 0;
  function updateStatus() {
    clearTimeout(updateStatusTimer);
    if (document.hidden) {
      // If the document is hidden, then there isn't much benefit from updating the UI. The
      //   UI will be updated when the visibility of the page changes.
      return;
    }
    const $status = $('.navbar #smokedetector-status');
    const lastPing = parseFloat($status.data('last-ping')) * 1e3;
    const ago = Date.now() - lastPing;
    const title = `Last ping was ${moment(lastPing).fromNow()}.`;
    let status = 'critical';
    // The .fromNow() method only provides minute resolution. So time passing can cause the status text
    //   to change change at the earliest at the point when "ago" passes the next minute.
    let msToNextPossibleChange = 60e3 - (ago % 60e3); // Time to next minute ago;
    if (ago < 90e3) {
      status = 'good';
      msToNextPossibleChange = Math.min(msToNextPossibleChange, 90e3 - ago); // Time to 1.5 minutes ago, if less;
    }
    else if (ago < 3 * 60e3) {
      status = 'warning';
      msToNextPossibleChange = Math.min(msToNextPossibleChange, 3 * 60e3 - ago); // Time to 3 minutes ago, if less;
    }
    const navbarToggle = $('.navbar-toggle');
    const statusClass = `status-${status}`;
    setOnlyStatusClassIfNotHasClass(navbarToggle, statusClass);
    setOnlyStatusClassIfNotHasClass($status, statusClass);
    const currentOrigTitle = $status.attr('data-original-title');
    const currentTooltipInnerText = $status.find('.status + .tooltip .tooltip-inner')
                                           .text();
    if (currentOrigTitle !== title || currentTooltipInnerText !== title) {
      $status.attr('data-original-title', title)
             .tooltip()
             .parent()
             .find('.status + .tooltip .tooltip-inner')
             .text(title);
    }
    // Get called again just after when anything displayed to the user might update.
    updateStatusTimer = setTimeout(updateStatus, msToNextPossibleChange + 1);
  }
  updateStatus();
  window.addEventListener('visibilitychange', updateStatus);
});
