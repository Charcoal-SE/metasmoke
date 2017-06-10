$(document).on 'ready turbolinks:load', ->
  if location.pathname == '/flagging/logs'
    App.flag_logs = App.cable.subscriptions.create "FlagLogsChannel",
      received: (data) ->
        $('table#all-flag-logs tbody').prepend(data['row'])
  else if App.posts
    App.flag_logs.unsubscribe()
    App.flag_logs = null
