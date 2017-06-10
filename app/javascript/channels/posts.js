let is_page_visible = true;
let num_unseen_posts = 0;

$(document).on('turbolinks:load', () => {
  if (App.posts != null) {
    App.posts.unsubscribe();
  }
  if (location.pathname === '/posts') {
    App.posts = App.cable.subscriptions.create("PostsChannel", {
      received(data) {
        $('table#posts-index-table tbody').prepend(data.row);
        if (!is_page_visible) {
          num_unseen_posts++;
          document.title = `(${num_unseen_posts}*) Recent posts - metasmoke`;
        }
      }
    });
  } else if (/^\/post\/(\d*)(\/)?$/.test(location.pathname)) {
    App.posts = App.cable.subscriptions.create({
      channel: "PostsChannel",
      post_id: location.pathname.match(/^\/post\/(\d*)(\/)?$/)[1]
    }, {
      received(data) {
        $('strong.post-feedbacks').prepend(data.feedback);
      }
    });
  }
});

$(window).on('blur', () => is_page_visible = false);

$(window).on('focus', () => {
  if (location.pathname === '/posts') {
    is_page_visible = true;
    num_unseen_posts = 0;
    document.title = "Recent posts - metasmoke";
  }
});
