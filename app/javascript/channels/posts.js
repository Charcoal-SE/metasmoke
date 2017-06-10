let isPageVisible = true;
let numUnseenPosts = 0;

$(document).on('turbolinks:load', () => {
  if (App.posts != null) {
    App.posts.unsubscribe();
  }
  if (location.pathname === '/posts') {
    App.posts = App.cable.subscriptions.create('PostsChannel', {
      received(data) {
        $('table#posts-index-table tbody').prepend(data.row);
        if (!isPageVisible) {
          numUnseenPosts++;
          document.title = `(${numUnseenPosts}*) Recent posts - metasmoke`;
        }
      }
    });
  } else if (/^\/post\/(\d*)(\/)?$/.test(location.pathname)) {
    App.posts = App.cable.subscriptions.create({
      channel: 'PostsChannel',
      post_id: location.pathname.match(/^\/post\/(\d*)(\/)?$/)[1]
    }, {
      received(data) {
        $('strong.post-feedbacks').prepend(data.feedback);
      }
    });
  }
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
