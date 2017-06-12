import createDebug from 'debug';

import { onLoad } from './util';

const debug = createDebug('ms:api');

onLoad(() => {
  $('#create_filter').on('click', () => {
    const bits = Array.from($('input[type=checkbox]')).reduce((acc, x) => {
      acc[$(x).data('index')] = $(x).is(':checked') ? 1 : 0;
      return acc;
    }, []);
    const last = arr => arr[arr.length - 1];
    const chunk = n => arr => arr.reduce((acc, x) => {
      if (acc.length !== 0 && last(acc).length < n) {
        last(acc).push(x);
      } else {
        acc.push([x]);
      }
      return acc;
    }, []);
    const glue = x => x.join('');
    const toChar = x => String.fromCharCode(parseInt(x, 2));
    const unsafeFilter = glue(chunk(8)(bits).map(glue).map(toChar));
    const filter = encodeURIComponent(unsafeFilter);
    window.prompt('Calculated, URL-encoded filter:', filter);
  });
});
