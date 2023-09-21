import { route } from '../util';
import cable from './cable';

let isPageVisible = true;
let numUnseenPosts = 0;

let postsSocket;
route('/posts', () => {
  postsSocket = cable.subscriptions.create('PostsChannel', {
    received(data) {
      $('table#posts-index-table > tbody').prepend(data.row);
      if (!isPageVisible) {
        numUnseenPosts++;
        document.title = `(${numUnseenPosts}*) Recent posts - metasmoke`;
      }
    }
  });
}, () => {
  if (!postsSocket) {
    return;
  }
  postsSocket.unsubscribe();
  postsSocket = null;
});

$(window).on('blur', () => {
  isPageVisible = false;
});

$(window).on('focus', () => {
  if (location.pathname === '/posts') {
    isPageVisible = true;
    numUnseenPosts = 0;
    document.title = 'Recent posts - metasmoke';
  }
});
