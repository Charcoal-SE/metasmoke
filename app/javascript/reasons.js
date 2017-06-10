import createDebug from 'debug';

const debug = createDebug('ms:reasons');

// This really is the wrong file for all of this

$(() => {
  $(document).on('click', '.show-post-body', function () {
    const span = $(this);
    if ($(this).data('postloaded')) {
      togglePostBodyVisible(this);
    } else {
      // If we need to lazy-load the post body from the server
      // This is criminally ugly
      $($(this).parent().children('div.post-body')[0]).load(`/post/${$(this).data('postid')}/body`, () => {
        debug('post data loaded', span[0])
        togglePostBodyVisible(span);
        span.data('postloaded', true);
      });
    }
  });
  $(document).on('keyup', '#search', function () {
    const val = $.trim($(this).val()).replace(/ +/g, ' ').toLowerCase();
    debug('searching for', `"${val}"`)
    $('tr').not('tr:first').show().filter(function () {
      const text = $(this).text().replace(/\s+/g, ' ').toLowerCase();
      return text.indexOf(val) !== -1;
    }).hide();
  });
  $(document).on('click', 'li.search-icon a', e => {
    $('#search').focus();
    e.preventDefault();
  });
  setTimeout(() => $('#search').addClass('ready'), 100);
});

function togglePostBodyVisible(row) {
  $('.post-body[data-postid=\'' + $(row).data('postid') + '\']').toggle();
  if ($(row).text() === '►') {
    $(row).text('▼');
  } else if ($(row).text() === '▼') {
    $(row).text('►');
  }
}
