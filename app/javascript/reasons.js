import createDebug from 'debug';

const debug = createDebug('ms:reasons');

// This really is the wrong file for all of this

$(() => {
  $(document).on('click', '.show-post-body', function () {
    if ($(this).data('postloaded')) {
      togglePostBodyVisible(this);
    } else {
      // If we need to lazy-load the post body from the server
      // This is criminally ugly
      $(this).parent().children('div.post-body:first').load(`/post/${$(this).data('postid')}/body`, () => {
        debug('post data loaded', $(this)[0]);
        togglePostBodyVisible($(this));
        span.data('postloaded', true);
      });
    }
  });
  $(document).on('keyup', '#search', function () {
    const val = $.trim($(this).val()).replace(/ +/g, ' ').toLowerCase();
    debug('searching for', `"${val}"`);
    $('tr').not('tr:first').show().filter(function () {
      const text = $(this).text().replace(/\s+/g, ' ').toLowerCase();
      return text.includes(val);
    }).hide();
  });
  $(document).on('click', 'li.search-icon a', e => {
    $('#search').focus();
    e.preventDefault();
  });
  setTimeout(() => $('#search').addClass('ready'), 100);
});

function togglePostBodyVisible(row) {
  $(`.post-body[data-postid="${$(row).data('postid')}"]`).toggle();
  if ($(row).text() === '►') {
    $(row).text('▼');
  } else if ($(row).text() === '▼') {
    $(row).text('►');
  }
}
