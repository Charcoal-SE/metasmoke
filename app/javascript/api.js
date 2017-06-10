import { onLoad } from './util';

onLoad(() => {
  $('#create_filter').on('click', () => {
    const checkboxes = $('input[type=checkbox]');
    const bits = new Array(checkboxes.length);

    $.each(checkboxes, (index, item) => {
      const $item = $(item);
      const arrayIndex = $item.data('index');
      if ($item.is(':checked')) {
        bits[arrayIndex] = 1;
      } else {
        bits[arrayIndex] = 0;
      }
    });

    let unsafeFilter = '';
    while (bits.length) {
      const nextByte = bits.splice(0, 8).join('');
      const charCode = parseInt(nextByte.toString(), 2);
      unsafeFilter += String.fromCharCode(charCode);
      console.log(nextByte, charCode, unsafeFilter);
    }

    const filter = encodeURIComponent(unsafeFilter);
    window.prompt('Calculated, URL-encoded filter:', filter);
  });
});
