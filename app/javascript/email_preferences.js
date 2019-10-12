$(() => {
  $('.js-preference-toggle').on('change', async evt => {
    const enabled = $(evt.target).is(':checked');
    const prefId = $(evt.target).data('pref-id');
    const resp = await fetch(`/email/preferences/${prefId}/toggle`, {
      method: 'POST',
      credentials: 'include',
      body: JSON.stringify({ enabled }),
      headers: { 'Content-Type': 'application/json' }
    });
    const data = await resp.json();
    console.log('pref-toggle', resp, data); // eslint-disable-line no-console
  });

  $('.js-preference-frequency').on('click', async evt => {
    $(evt.target).attr('disabled', true);
    const prefId = $('.js-preference-frequency').data('pref-id');
    const frequency = $(`.js-frequency[data-pref-id="${prefId}"]`).val();
    const resp = await fetch(`/email/preferences/${prefId}/frequency`, {
      method: 'POST',
      credentials: 'include',
      body: JSON.stringify({ frequency }),
      headers: { 'Content-Type': 'application/json' }
    });
    const data = await resp.json();
    console.log('pref-freq', resp, data); // eslint-disable-line no-console
    $(evt.target).attr('disabled', false);
  });

  $('.js-preference-delete').on('click', async evt => {
    evt.preventDefault();

    const prefId = $(evt.target).data('pref-id');
    const resp = await fetch(`/email/preferences/${prefId}/delete`, {
      method: 'POST',
      credentials: 'include'
    });
    const data = await resp.json();
    console.log('pref-delete', resp, data);
    $(evt.target).parents('.preference-container').fadeOut(200, function () { $(this).remove(); });
  });
});
