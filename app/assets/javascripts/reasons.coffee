# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# This really is the wrong file for all of this

$ ->
  $(document).on 'click', '.show-post-body', (event) ->
    span = $(this)
    unless $(this).data('postloaded')
      # If we need to lazy-load the post body from the server
      # This is criminally ugly
      $($(this).parent().children('div.post-body')[0]).load "/post/#{$(this).data('postid')}/body", ->
         console.log("yay")
         togglePostBodyVisible(span)
         span.data('postloaded', true)

    else
      togglePostBodyVisible(this)

  $(document).on 'keyup', '#search', (event) ->
    val = $.trim($(this).val()).replace(/ +/g, ' ').toLowerCase();
    console.log val

    $("tr").not('tr:first').show().filter( () ->
      text = $(this).text().replace(/\s+/g, ' ').toLowerCase();
      return !~text.indexOf(val);
    ).hide();
  $(document).on 'click', '#search ~ li a', () ->
    $('#search').focus()
  setTimeout ->
    $('#search').addClass 'ready'
  , 100

togglePostBodyVisible = (row) ->
  $(".post-body[data-postid='" + $(row).data("postid") + "']").toggle()

  if $(row).text() == "►"
    $(row).text("▼")
  else if $(row).text() == "▼"
    $(row).text("►")
