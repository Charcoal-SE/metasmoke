import { route } from './util';

route('/admin/settings', () => {
  $('.setting-checkbox').on('change', async (ev) => {
    const target = $(ev.target);
    const name = target.data('name');
    const checked = target.is(':checked');
    const resp = await fetch(`/admin/settings/${name}?value=${checked}`, {
      method: 'post',
      credentials: 'include'
    });
    try {
      const json = await resp.json();
      if (json.success) {
        console.log('Changed :)');
      }
      else {
        console.log('???');
      }
    }
    catch (ex) {
      console.log('???', resp);
    }
  });

  $('.editable-value').on('click', (ev) => {
    ev.stopPropagation();
    const value = $(ev.target).text();
    $(ev.target).html(`<input type="text" class="editing-value form-control input-sm" value="${value}" />`);
  });

  $(document).on('click', (ev) => {
    $('.editing-value').each((i, e) => {
      const value = $(e).val();
      $(e).parent().text(value);
    });
  });

  $(document).on('keypress', '.editing-value', async (ev) => {
    if (ev.charCode === 13) {
      const name = $(ev.target).parent().data('name');
      const value = $(ev.target).val();
      const resp = await fetch(`/admin/settings/${name}?value=${value}`, {
        method: 'post',
        credentials: 'include'
      });
      try {
        const json = await resp.json();
        if (json.success) {
          console.log('Changed :)');
          $(document).click();
        }
        else {
          console.log('???');
        }
      }
      catch (ex) {
        console.log('???', resp);
      }
    }
  });
});
