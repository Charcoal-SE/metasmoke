import { onLoad } from './util';

onLoad(() => {
  $('.expand-status-table').on('click', e => {
    $('.hidden-row').toggle();
    e.preventDefault();
  });
});
