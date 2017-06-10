import { route } from '../util';

let postSocket;
route(/^\/post\/(\d*)(\/)?$/, () => {
  postSocket = App.cable.subscriptions.create({
    channel: 'PostsChannel',
    post_id: location.pathname.match(/^\/post\/(\d*)(\/)?$/)[1]
  }, {
    received(data) {
      $('strong.post-feedbacks').prepend(data.feedback);
    }
  });
}, () => {
  if (!postSocket) {
    return;
  }
  postSocket.unsubscribe();
  postSocket = null;
});
