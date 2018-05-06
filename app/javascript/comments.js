import { onLoad } from './util';

onLoad(() => {
  $('.new-comment').click(ev => {
    ev.preventDefault();
    $('.add-comment').show();
    $(ev.target).remove();
  });

  $('.comment-edit').click(ev => {
    ev.preventDefault();

    const $comment = $(ev.target).parents('.post-comment');
    const $body = $comment.find('.panel-body');
    const text = $body.text().trim();
    const id = $comment.data('cid');
    $body.html(`<form method="POST" action="/comments/${id}/edit">
        <div class="field">
            <textarea name="text" rows="3" cols="100" placeholder="Useful information about this post that others might need..."
                      class="form-control">${text}</textarea>
        </div><br/>
        <div class="actions">
            <input type="submit" value="Update comment" class="btn btn-primary" />
        </div>`);
  });
});
