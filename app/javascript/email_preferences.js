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
    console.log(resp, data);
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
    console.log(resp, data);
    $(evt.target).attr('disabled', false);
  });
});