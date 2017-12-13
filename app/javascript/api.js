import createDebug from 'debug';

import { onLoad } from './util';

const debug = createDebug('ms:api');
const partitionArray = (array, size) => array.map((e, i) => (i % size === 0) ?
  array.slice(i, i + size) : null).filter(e => e);

onLoad(() => {
  $('#create_filter').on('click', () => {
    const fields = $('label:has(input[type=checkbox]:checked)').toArray().map(el => $(el).text().trim());
    $.ajax({
      type: 'POST',
      url: '/api/filters',
      data: {
        fields: fields
      }
    })
    .done(data => {
      prompt("This is your filter. Copy it and use it as the filter query string parameter on API requests.", data['filter']);
    })
    .fail(xhr => {
      debug(xhr.status);
      debug(xhr);
    });
  });
});
