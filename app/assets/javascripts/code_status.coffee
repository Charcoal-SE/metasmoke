# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  $("#show-all-gem-versions").on "click", (e) ->
    e.preventDefault()

    $("table#gems-versions-table tr").show()
    $(this).hide()
