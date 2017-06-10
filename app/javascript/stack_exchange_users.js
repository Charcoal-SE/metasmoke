function ready() {
  $("img.stack_exchange_user_flair").error(function() {
    $(this).replaceWith("<h3><img src='" + $(this).data("site-logo") + "'> " + $(this).data("username") + " (" + $(this).data("reputation") + ")</h3><p class='text-danger'>(user has been deleted)</p>");
  });
  $('.not-spammer').click(function(e) {
    e.preventDefault();
    const $this = $(this);
    $.ajax({
      'type': 'POST',
      'url': '/spammers/dead/' + slf.data('uid')
    }).done(data => {
      if (data === "ok") {
        const $tr = $this.parent().parent();
        $tr.fadeOut(200, () => $tr.remove());
      } else {
        console.error('something went wrong: update returned', data);
      }
    }).fail(jqXHR => console.error('something went wrong: update returned', jqXHR.status, jqXHR.responseText));
  });
};

$(document).ready(ready);
$(document).on('turbolinks:load', ready);
