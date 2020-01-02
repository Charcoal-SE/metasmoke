import { route } from '../util';
import cable from './cable';

let postSocket;
route(/^\/post\/(\d*)(\/)?$/, () => {
  postSocket = cable.subscriptions.create({
    channel: 'PostsChannel',
    post_id: location.pathname.match(/^\/post\/(\d*)(\/)?$/)[1]
  }, {
    received(data) {
      $('strong.post-feedbacks').append(data.feedback).append(' ').find('[data-toggle="tooltip"]').tooltip();
    }
  });
}, () => {
  if (!postSocket) {
    return;
  }
  postSocket.unsubscribe();
  postSocket = null;
});
