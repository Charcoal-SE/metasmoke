$(document).on 'turbolinks:load', ->
  $("input.permissions-checkbox").change ->
    console.log("oy")
    $(this).disabled = true

    checkbox = $(this)

    $.ajax
      type: 'put'
      data: {'permitted': $(this).is(":checked"), 'user_id': $(this).data("user-id"), 'role': $(this).data("role")}
      dataType: 'json'
      url: "/admin/permissions/update"
      success: (data) ->
        checkbox.disabled = false
        
