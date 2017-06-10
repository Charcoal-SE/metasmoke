// This really is the wrong file for all of this

$(function() {
  $(document).on('click', '.show-post-body', function(event) {
    const span = $(this);
    if (!$(this).data('postloaded')) {
      // If we need to lazy-load the post body from the server
      // This is criminally ugly
      $($(this).parent().children('div.post-body')[0]).load(`/post/${$(this).data('postid')}/body`, () => {
        console.log("yay");
        togglePostBodyVisible(span);
        span.data('postloaded', true);
      });
    } else {
      togglePostBodyVisible(this);
    }
  });
  $(document).on('keyup', '#search', function(event) {
    var val;
    val = $.trim($(this).val()).replace(/ +/g, ' ').toLowerCase();
    console.log(val);
    $("tr").not('tr:first').show().filter(function() {
      const text = $(this).text().replace(/\s+/g, ' ').toLowerCase();
      return !~text.indexOf(val);
    }).hide();
  });
  $(document).on('click', 'li.search-icon a', e => {
    $('#search').focus();
    e.preventDefault();
  });
  setTimeout(() => $('#search').addClass('ready'), 100);
});

function togglePostBodyVisible(row) {
  $(".post-body[data-postid='" + $(row).data("postid") + "']").toggle();
  if ($(row).text() === "►") {
    $(row).text("▼");
  } else if ($(row).text() === "▼") {
    $(row).text("►");
  }
};
