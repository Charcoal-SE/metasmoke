import { onLoad } from './util';

setTimeout(() => {
  /* This is a patch to remove duplicated bootstrap-select dropdown selections.
   * It would be better to prevent these from being created.
   * This is added to onLoad() from a setTimeout, so it ends up being called
   * after other functions. Putting the operation within a setTimeout that's
   * called on each load results in the duplicate being visible briefly.
   */
  onLoad(() => {
    $('.dropdown.bootstrap-select > .dropdown.bootstrap-select').each(function () {
      const useSelect = $(this);
      useSelect.parent().replaceWith(useSelect);
    });
  });
}, 100);

(() => {
  /* This prevents multiple requests being made to the same URL within a short period of time.
   *   It should affect anywhere where more than one request of the same type is being made to
   *   the same URL within 100ms.
   */
  const minimumTimeBetweenBackToBackRequests = 100;
  const dupAjaxRequestIgnoredUrls = [
    'https://metasmoke.erwaysoftware.com/mini-profiler-resources/results',
    '/mini-profiler-resources/results'
  ];
  const priorAjaxSendInfo = {
    url: '',
    date: 0,
    type: ''
  };

  function dontPermitQuickBackToBackRequestsToSameURL(event, jqXHR, requestSettings) {
    const now = Date.now();
    if (!dupAjaxRequestIgnoredUrls.includes(requestSettings.url)) {
      if (priorAjaxSendInfo.date > (now - minimumTimeBetweenBackToBackRequests) && priorAjaxSendInfo.url === requestSettings.url && priorAjaxSendInfo.type === requestSettings.type) {
        // Abort this request which is to the same URL and within 100ms of the most recent prior request.
        console.error('Aborting rapid request to same url:\nTHIS MAY CONTAIN PRIVATE INFORMATION. Be careful when sharing.\nrequestSettings.url:', requestSettings.url, '::  requestSettings:', requestSettings, '::  jqXHR:', jqXHR, '::  event:', event); // eslint-disable-line no-console
        jqXHR.abort();
        return;
      }
    }
    priorAjaxSendInfo.date = now;
    priorAjaxSendInfo.url = requestSettings.url;
    priorAjaxSendInfo.type = requestSettings.type;
  }
  $(document).ajaxSend(dontPermitQuickBackToBackRequestsToSameURL);
})();

(() => {
  /* Auxiliary setting of Turbolinks ProgressBar. The goal is to have the ProgressBar show consistently,
   * as it's not currently shown for a substantial number of situations where there's a long wait.
   * This has the ProgressBar displayed for both Turbolinks navigation and for AJAX requests. This
   * should result in the user being more aware that something is actually happening, rather than
   * wondering if their click was effective.
   * In addition, this disables clicking on the same control until the AJAX request is complete.
   * That should result in fewer situations where a user repeatedly clicks on an action with takes
   * MS substantial time to process, causing MS to repeatedly allocate resources to performing the
   * same task multiple times.
   */
  /* globals Turbolinks */
  let previousClickTarget = null;
  let previousClickTimestamp = 0;
  const withinMillisecondsForClickToMatchAjax = 50;
  const notTrackedAjaxUrls = [
    'https://metasmoke.erwaysoftware.com/mini-profiler-resources/results',
    '/mini-profiler-resources/results'
  ];
  let pendingTurbolinksVisit = null;
  let pendingTurbolinksVisitTimeout = null;
  const millisecondsWaitForTurbolinksVisit = 500;

  /* The safeStartTurbolinksProgress() and safeStopTurbolinksProgress() functions are from
   *   [answer to: "Turbolinks 5 : Show progress Bar"](https://stackoverflow.com/a/38490830/3773011)
   * by [dimroc](https://stackoverflow.com/users/639773/dimroc)
   * which is copyright 2016 and under a CC BY-SA 3.0 license.
   * The functions have been modified.
   */
  function safeStartTurbolinksProgress() {
    if (Turbolinks.supported) {
      Turbolinks.controller.adapter.progressBar.setValue(0);
      Turbolinks.controller.adapter.progressBar.show();
    }
  }

  function safeStopTurbolinksProgress() {
    if (Turbolinks.supported) {
      Turbolinks.controller.adapter.progressBar.hide();
      Turbolinks.controller.adapter.progressBar.setValue(100);
    }
  }

  // This is just a counter which allows JavaScript to explicitly identify AJAX requests.
  let turboLinksXhrId = 0;
  function getNewXhrID() {
    turboLinksXhrId++;
    return turboLinksXhrId;
  }

  function addIDToJqueryXhrOnEvent(event, jqXHR, requestSettings) {
    const url = requestSettings.url;
    if (!notTrackedAjaxUrls.includes(url)) {
      addXhrIDToObjectAndWaitForAjax(jqXHR, url);
    }
  }

  function didNotHaveTurbolinksVisitWithinTimeout() {
    // We didn't see a Turbolinks:visit event with the pending URL. We assume this means we are not navigating.
    pendingTurbolinksVisit = null;
    pendingTurbolinksVisitTimeout = null;
    safeStopTurbolinksProgress();
  }

  function addIDToTurbolinksXhrOnEvent(event) {
    // We first get here on mousedown.
    // Turbolinks fails if we cancel the click event which happens after the mousedown.
    addXhrIDToObjectAndWaitForAjax(event.originalEvent.data.xhr, event.originalEvent.data.url, false);
    if (event.type === 'turbolinks:request-start' && event.originalEvent.data.xhr) {
      pendingTurbolinksVisit = event.originalEvent.data.xhr.msData;
      pendingTurbolinksVisitTimeout = setTimeout(didNotHaveTurbolinksVisitWithinTimeout, millisecondsWaitForTurbolinksVisit);
    }
    if (event.type === 'turbolinks:visit' && pendingTurbolinksVisit && event.originalEvent.data.url === pendingTurbolinksVisit.url) {
      // This is the expected :visit event.
      clearTimeout(pendingTurbolinksVisitTimeout);
      // We disable/wait-for-AJAX the element which started this visit
      disableElementAndIndicateWaitForAjax(pendingTurbolinksVisit.clickTarget);
    }
  }

  function disableElementAndIndicateWaitForAjax(el) {
    $(el)
      .addClass('wait-for-AJAX')
      .prop('disabled', true)
      .attr('disabled', true);
  }

  function addXhrIDToObjectAndWaitForAjax(obj, url, addWaitForAjax = true) {
    if ($(previousClickTarget).closest('a.dropdown-toggle').length > 0) {
      return;
    }
    if (obj && typeof obj.msData !== 'object') {
      obj.msData = {
        id: getNewXhrID(),
        url
      };
      const timeAgo = Date.now() - previousClickTimestamp;
      if (timeAgo <= withinMillisecondsForClickToMatchAjax) {
        obj.msData.clickTarget = previousClickTarget;
        // Only one associated
        if (addWaitForAjax) {
          disableElementAndIndicateWaitForAjax(previousClickTarget);
        }
        if (previousClickTarget) {
          safeStartTurbolinksProgress();
        }
        previousClickTimestamp = 0;
        previousClickTarget = null;
      }
    }
  }

  function enableSavedTargetInJqueryXhrEvent(event, jqXHR) {
    if (jqXHR.msData && jqXHR.msData.clickTarget) {
      safeStopTurbolinksProgress();
      $(jqXHR.msData.clickTarget)
        .removeClass('wait-for-AJAX')
        .prop('disabled', false)
        .attr('disabled', false);
    }
  }

  function rememberMouseDown(event) {
    if (event.button !== 0) {
      return;
    }
    previousClickTarget = event.target;
    previousClickTimestamp = Date.now();
  }

  function cancelEventIfWaitForAjaxOrDisabled(event) {
    const target = event.target;
    if (target.classList.contains('wait-for-AJAX') || target.classList.contains('disabled') || (target.hasAttribute('disabled') && target.getAttribute('disabled') !== 'false')) {
      event.stopImmediatePropagation();
      event.preventDefault();
    }
  }

  // Remember clicks
  window.addEventListener('mousedown', rememberMouseDown, true); // Turbolinks starts fetching upon mousedown.
  window.addEventListener('mouseup', rememberMouseDown, true);
  window.addEventListener('click', rememberMouseDown, true);
  // Cancel events when waiting for AJAX for the target or target is disabled
  window.addEventListener('mousedown', cancelEventIfWaitForAjaxOrDisabled, true);
  window.addEventListener('mouseup', cancelEventIfWaitForAjaxOrDisabled, true);
  window.addEventListener('click', cancelEventIfWaitForAjaxOrDisabled, true);

  $(document)
    .ajaxSend(addIDToJqueryXhrOnEvent)
    .ajaxComplete(enableSavedTargetInJqueryXhrEvent);
  $(window).on('turbolinks:request-start turbolinks:before-visit turbolinks:visit', addIDToTurbolinksXhrOnEvent);
})();
