import createDebug from 'debug';

const debug = createDebug('ms:domain_links');

$(() => {
  $('.new_domain_link').on('ajax:success', (ev, data) => {
    $('.domain-links-list').append(data);
    $(ev.target).parents('.modal').modal('close');
  });
});
