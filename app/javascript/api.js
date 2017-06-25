import createDebug from 'debug';

import { onLoad } from './util';

const debug = createDebug('ms:api');
const partitionArray = (array, size) => array.map((e, i) => (i % size === 0) ?
  array.slice(i, i + size) : null).filter(e => e);

onLoad(() => {
  $('#create_filter').on('click', () => {
    const bits = Array.from($('input[type=checkbox]')).reduce((arr, el) => {
      const $el = $(el);
      arr[$el.data('index')] = Number($el.is(':checked'));
      return arr;
    }, []);

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
