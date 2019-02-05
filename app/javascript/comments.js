import createDebug from 'debug';
import { onLoad } from './util';

const debug = createDebug('ms:comments');

onLoad(() => {
  $(document).on('click', '.new-comment', ev => {
    debug('.new-comment click');
    ev.preventDefault();
    $('.add-comment').show();
    $(ev.target).remove();
  });

  $(document).on('click', '.comment-edit', async ev => {
    ev.preventDefault();

    const $comment = $(ev.target).parents('.post-comment, .abuse-comment');
    const $body = $comment.find('.panel-body');
    const id = $comment.data('cid');
    const uri = $comment.hasClass('post-comment') ? `/comments/${id}` : `/abuse/comments/${id}`;

    const resp = await fetch(uri, {
      credentials: 'include'
    });
    const json = await resp.json();
    const text = json.text;

    $body.html(`<form method="POST" action="${uri}/edit">
        <div class="field">
            <textarea name="text" rows="3" cols="100" placeholder="Useful information about this post that others might need..."
                      class="form-control">${text}</textarea>
        </div><br/>
        <div class="actions">
            <input type="submit" value="Update comment" class="btn btn-primary" />
        </div>`);
  });
});
