$(document).on 'page:change', ->
  if location.pathname == '/posts'
    App.posts = App.cable.subscriptions.create "PostsChannel",
      received: (data) ->
        $('table tbody').prepend(data['row'])
  else if App.posts
    App.posts.unsubscribe()
    App.posts = null
