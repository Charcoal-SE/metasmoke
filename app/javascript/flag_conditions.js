$(document).on('turbolinks:load', () => {
  $("input#preview-flag-conditions-button").on('click', () => {
    $.ajax({
      url: "/flagging/conditions/preview",
      data: $("form").serialize()
    });
  });
});
