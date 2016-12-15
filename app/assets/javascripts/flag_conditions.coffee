# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $("input#preview-flag-conditions-button").on 'click', ->
    $.ajax
      url: "/flagging/conditions/preview",
      data: $("form").serialize()
