import createDebug from 'debug';
import { route } from './util';

const debug = createDebug('ms:site_settings');

route('/admin/settings', () => {
  $('.setting-checkbox').on('change', async ev => {
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
        debug('Changed :)');
      }
      else {
        debug('???');
      }
    }
    catch (err) {
      debug('???', resp);
    }
  });

  $('.editable-value').on('click', ev => {
    ev.stopPropagation();
    const value = $(ev.target).text();
    const type = $(ev.target).data('type');
    $(ev.target).html(`<input type="${type}" class="editing-value form-control input-sm" value="${value}" />`);
  });

  $(document).on('click', () => {
    $('.editing-value').each((i, e) => {
      const value = $(e).val();
      $(e).parent().text(value);
    });
  });

  $(document).on('keypress', '.editing-value', async ev => {
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
          debug('Changed :)');
          $(document).click();
        }
        else {
          debug('???');
        }
      }
      catch (err) {
        debug('???', resp);
      }
    }
  });
});
