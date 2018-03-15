import { route } from './util';

/* globals Highcharts */

route('/flagging/conditions/sandbox', () => {
  $(document).ajaxSuccess((ev, xhr, options) => {
    if (options.url.indexOf('/graphs/af_accuracy') >= 0) {
      Highcharts.charts[0].update({ series: [{ marker: { enabled: false }, linecap: 'butt' }, { marker: { enabled: false }, linecap: 'butt' },
        { yAxis: 1, marker: { enabled: false }, linecap: 'butt' }] });
    }
  });
});
