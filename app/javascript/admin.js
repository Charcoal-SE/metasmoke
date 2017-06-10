import { onLoad } from './util';

onLoad(() => {
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
  $('input.trust-checkbox').change(function () {
    const $this = $(this);
    $this.disabled = true;
    $.ajax({
      type: 'post',
      data: {
        trusted: $this.is(':checked')
      },
      dataType: 'json',
      url: '/admin/keys/' + $this.data('key-id') + '/trust',
      success: data => {
        if (data !== 'OK') {
          console.error(data);
        }
        $this.disabled = false;
      }
    });
  });
});
