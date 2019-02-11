import { route } from './util';

route(/\/dev\/request-log.*/, () => {
  function percentageToHsl(percentage, hue0, hue1) {
    var hue = (percentage * (hue1 - hue0)) + hue0;
    return 'hsl(' + hue + ', 100%, 25%)';
  }

  ['.request-db-time', '.request-view-time'].forEach(cls => {
    let times = $(cls).map((i, s) => parseFloat($(s).text().trim().replace('ms', '')));
    times = times.toArray().filter(x => !isNaN(x));
    const max = Math.max(...times);
    const min = Math.min(...times);
    const distance = t => {
      return t / (max - min);
    };

    $(cls).each((i, s) => {
      const time = parseFloat($(s).text().trim().replace('ms', ''));
      if (isNaN(time)) {
        return;
      }

      $(s).css('color', percentageToHsl(distance(time), 120, 0));
    });
  });
});