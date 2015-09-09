# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $(document).on 'click', '.show-post-body', (event) ->
    $(".post-body[data-postid='" + $(this).attr("data-postid") + "']").toggle()

    if $(this).text() == "►"
      $(this).text("▼")
    else if $(this).text() == "▼"
      $(this).text("►") 
  $(document).on 'keyup', '#search', (event) ->
    val = $.trim($(this).val()).replace(/ +/g, ' ').toLowerCase();
    console.log val

    $("tr").not('tr:first').show().filter( () -> 
      text = $(this).text().replace(/\s+/g, ' ').toLowerCase();
      return !~text.indexOf(val);
    ).hide();
