is_page_visible = true
num_unseen_posts = 0

$(document).on 'page:change', ->
  if location.pathname == '/posts'
    App.posts = App.cable.subscriptions.create "PostsChannel",
      received: (data) ->
        $('table tbody').prepend(data['row'])

        unless is_page_visible
          num_unseen_posts++
          document.title = "(#{num_unseen_posts}*) Recent posts - metasmoke"

  else if App.posts
    App.posts.unsubscribe()
    App.posts = null

$(window).on 'blur', ->
  is_page_visible = false

$(window).on 'focus', ->
  is_page_visible = true
  num_unseen_posts = 0
  document.title = "Recent posts - metasmoke"
