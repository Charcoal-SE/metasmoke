import createDebug from 'debug';

import { onLoad } from './util';

const debug = createDebug('ms:admin');

onLoad(() => {
  let nukeUserConfirmed = false;

  $('a.nuke-user-link').click(function (e) {
    e.preventDefault();

    const $this = $(this);
    if (!nukeUserConfirmed) {
      nukeUserConfirmed = window.confirm('Are you sure?  This will permanently destroy \'' + $this.data('username') + '\' and all associated records.  ' +
                                         'Note that you will not be prompted for confirmation to nuke another user until you refresh the page.');
      if (!nukeUserConfirmed) {
        return;
      }
    }
    $.ajax({
      type: 'delete',
      url: '/admin/permissions/' + $this.data('user-id'),
      success() {
        $this.closest('tr').remove();
      }
    });
  });

  $('input.permissions-checkbox').change(function () {
    const $this = $(this);
    $this.disabled = true;
    $.ajax({
      type: 'put',
      data: {
        permitted: $this.is(':checked'),
        user_id: $this.data('user-id'),
        role: $this.data('role')
      },
      dataType: 'json',
      url: '/admin/permissions/update',
      success() {
        $this.disabled = false;
      }
    });
  });

  $('input.pin-checkbox').change(function () {
    const $this = $(this);
    $this.disabled = true;
    $.ajax({
      type: 'put',
      data: {
        permitted: $this.is(':checked'),
        pinned: true,
        user_id: $this.data('user-id'),
        role: $this.data('role')
      },
      dataType: 'json',
      url: '/admin/permissions/update',
      success() {
        $this.disabled = false;
      }
    });
  });

  $('input.trust-checkbox').change(function () {
    const $this = $(this);
    $this.disabled = true;
    $.ajax({
      type: 'post',
      data: {
        trusted: $this.is(':checked')
      },
      dataType: 'json',
      url: `/admin/keys/${$this.data('key-id')}/trust`,
      success: data => {
        if (data !== 'OK') {
          debug('toggle failed:', data);
        }
        $this.disabled = false;
      }
    });
  });
});
