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
