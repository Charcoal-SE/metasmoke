import createDebug from 'debug';

import { onLoad } from './util';

const debug = createDebug('ms:api');
const partitionArray = (array, size) => array.map( (e,i) => (i % size === 0) ?
  array.slice(i, i + size) : null ) .filter( (e) => e );

onLoad(() => {
  $('#create_filter').on('click', () => {
    const checkboxes = $('input[type=checkbox]');
    const bits = new Array(checkboxes.length);

    $.each(checkboxes, (index, item) => {
      const $item = $(item);
      const arrayIndex = $item.data('index');
      if ($item.is(':checked')) {
        bits[arrayIndex] = 1;
        debug($item, arrayIndex);
      } else {
        bits[arrayIndex] = 0;
      }
    });

    const bytes = partitionArray(bits, 8);
    debug(bits.join(''));
    debug(bytes.map(x => x.join('')).join(' '));
    debug(bytes.map(x => parseInt(x.join(''), 2)).join('        '));

    let unsafeFilter = '';
    for (let i = 0; i < bytes.length; i++) {
      const nextByte = bytes[i].join('');
      const charCode = parseInt(nextByte.toString(), 2);
      unsafeFilter += String.fromCharCode(charCode);
      debug(nextByte, charCode, unsafeFilter);
    }

    const filter = btoa(unsafeFilter);
    debug(filter);
    window.prompt('Your filter:', filter);
  });
});
