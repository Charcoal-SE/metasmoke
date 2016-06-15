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
  else if /^\/post\/(\d*)(\/)?$/.test(location.pathname)
    App.posts = App.cable.subscriptions.create { channel: "PostsChannel", post_id: location.pathname.match(/^\/post\/(\d*)(\/)?$/)[1] },
      received: (data) ->
        $('strong.post-feedbacks').prepend(data['feedback'])
  else if App.posts
    App.posts.unsubscribe()
    App.posts = null

$(window).on 'blur', ->
  is_page_visible = false

$(window).on 'focus', ->
  if location.pathname == '/posts'
    is_page_visible = true
    num_unseen_posts = 0
    document.title = "Recent posts - metasmoke"
