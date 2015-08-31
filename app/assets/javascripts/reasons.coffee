# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $(document).on 'click', '.show-post-body', (event) ->
    $(this).parent().children(".post-body").toggle()

    if $(this).text() == "►"
      $(this).text("▼")
    else if $(this).text() == "▼"
      $(this).text("►") 
