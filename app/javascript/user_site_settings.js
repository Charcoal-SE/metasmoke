$(document).on('ready turbolinks:load', () => {
  $('#red-button').on('click', function () {
    const flagsEnabled = $(this).is(':checked');
    $.ajax({
      type: 'POST',
      url: '/flagging/preferences/enable',
      data: {
        enable: flagsEnabled
      }
    }).done(() => console.log('Saved :)')).error(xhr => console.error(xhr.responseText));
  });
});
