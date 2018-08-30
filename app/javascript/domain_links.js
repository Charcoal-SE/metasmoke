import { onLoad } from './util';

onLoad(() => {
  $('.domain-link-form').on('ajax:success', (ev, data) => {
    $('.domain-links-list').append(data);
    $(ev.target).parents('.modal').modal('close');
  });
});
