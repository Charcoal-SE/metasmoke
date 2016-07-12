# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

ready = ->
  $("img.stack_exchange_user_flair").error ->
    $(this).replaceWith("<h3><img src='" + $(this).data("site-logo") + "'> " + $(this).data("username") + " (" + $(this).data("reputation") + ")</h3><p class='text-danger'>(user has been deleted)</p>")

$(document).ready(ready)
$(document).on('turbolinks:load', ready)
