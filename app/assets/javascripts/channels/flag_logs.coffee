$(document).on 'turbolinks:load', ->
  if location.pathname == '/flagging/logs'
    App.flag_logs = App.cable.subscriptions.create "FlagLogsChannel",
      received: (data) ->
        $('table tbody').prepend(data['row'])
  else if App.posts
    App.flag_logs.unsubscribe()
    App.flag_logs = null
