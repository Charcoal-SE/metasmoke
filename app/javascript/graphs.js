/* globals Highcharts */

$(document).ajaxSuccess((ev, xhr, options) => {
  // Equivalent detection to route() from './util', but doesn't add multiple listeners.
  if (window.location.pathname === '/flagging/conditions/sandbox') {
    if (options.url.indexOf('/graphs/af_accuracy') >= 0) {
      Highcharts.charts[0].update({ series: [{ marker: { enabled: false }, linecap: 'butt' }, { marker: { enabled: false }, linecap: 'butt' },
        { yAxis: 1, marker: { enabled: false }, linecap: 'butt' }] });
    }
  }
});
