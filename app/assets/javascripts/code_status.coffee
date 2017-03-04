# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  if location.pathname == '/status/code'
    $("#show-all-gem-versions").on "click", (e) ->
      e.preventDefault()

    $("table#gems-versions-table .minor").toggleClass 'hide'
    $(this).toggleClass 'shown'
