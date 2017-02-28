App.flag_logs = App.cable.subscriptions.create "TopbarChannel",
  received: ({ review, commit, last_ping }) ->
    console.log review, commit, last_ping
    if review?
      $('.navbar .reviews-count').text review or ''
    if commit?
      $('.commit').attr 'href', "https://github.com/Charcoal-SE/metasmoke/commit/#{commit}"
      .children('code').text commit.slice 0, 7
      $('.nav + div').prepend $ "<div class='alert alert-warning' role='alert'>This page has been updated. <a href='#{location.href}'>Refresh</a> to get the latest version.</div>"
    if last_ping?
      $('.navbar .status').data 'last-ping', last_ping

setInterval ->
  $status = $ '.navbar .status'
  last_ping = parseFloat($status.data 'last-ping') * 1e3
  ago = Date.now() - last_ping
  title = "Last ping was #{moment(last_ping).fromNow()}."
  status = switch
    when ago < 90e3 then 'good'
    when ago < 3 * 60e3 then 'warning'
    else 'critical'
  $status.removeClass 'status-good status-warning status-critical'
         .addClass "status-#{status}"
         .attr 'data-original-title', title
         .tooltip()
         .parent().find '.status + .tooltip .tooltip-inner'
         .text title
, 1000
