import { route } from './util';

route('/flagging/settings/sites', () => {
  $('.unsaved-changes').hide();

  $('.site-search').on('change', ev => {
    const search = $(ev.target).val();
    $('tbody tr').each((i, e) => {
      const sid = $(e).data('sid');
      const siteData = window.flagging_settings[sid];
      if (siteData.name.indexOf(search) === -1 && siteData.domain.indexOf(search) === -1) {
        $(e).hide();
      }
      else {
        $(e).show();
      }
    });
  });

  $('input[type=checkbox]').on('change', ev => {
    $('.unsaved-changes').show();

    const sid = $(ev.target).parents('tr').data('sid').toString();
    window.flagging_settings[sid].flags_enabled = $(ev.target).is(':checked');
    window.flagging_settings[sid].changed = true;
  });

  $('input[type=number]').on('keyup', ev => {
    $('.unsaved-changes').show();

    const sid = $(ev.target).parents('tr').data('sid').toString();
    window.flagging_settings[sid].max_flags = parseInt($(ev.target).val(), 10);
    window.flagging_settings[sid].changed = true;
  });

  $('.save-changes').on('click', async ev => {
    ev.preventDefault();

    await fetch('/flagging/settings/sites', {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data: window.flagging_settings })
    });
    $('.unsaved-changes').fadeOut(200);
  });
});
