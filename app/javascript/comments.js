import createDebug from 'debug';
import { onLoad } from './util';

const debug = createDebug('ms:comments');

onLoad(() => {
  $(document.body).on('click', '.new-comment', ev => {
    debug('.new-comment click');
    ev.preventDefault();
    $('.add-comment').show();
    $(ev.target).remove();
  });

  $(document.body).on('click', '.comment-edit', async ev => {
    ev.preventDefault();

    const $comment = $(ev.target).parents('.post-comment, .abuse-comment');
    const $commentPanel = $comment.find('.panel-body');
    const id = $comment.data('cid');
    const uri = $comment.hasClass('post-comment') ? `/comments/${id}` : `/abuse/comments/${id}`;

    const resp = await fetch(uri, {
      credentials: 'include'
    });
    const json = await resp.json();
    const text = json.text;

    $commentPanel.html(`<form method="POST" action="${uri}/edit">
        <div class="field">
            <textarea name="text" rows="3" cols="100" placeholder="Useful information about this post that others might need..."
                      class="form-control"></textarea>
        </div><br/>
        <div class="actions">
            <input type="submit" value="Update comment" class="btn btn-primary" />
        </div>`);
    /* We don't put the text in the above HTML, because
     *   1. It's a potential security risk, as the text is interpreted as raw HTML and could result in
     *      execution of arbitrary code. This is particularly an issue here, because the provided comment text
     *      is likely to have been provided by a different user and isn't sanitized.
     *   2. Having it in the above HTML text converts some HTML in the comment text (e.g. HTML entities are
     *      converted to characters). This can result in being unable to save the comment, even if unedited.
     */
    $commentPanel.find('textarea').val(text);
  });
});
