$(document).on('ajax:success', '#new_domain_link', (ev, data) => {
  $('.domain-links-list').append(data);
  $(ev.target).parents('.modal').modal('hide');
});
