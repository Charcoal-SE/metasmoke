$(document).on('ready turbolinks:load', function() {
    $("#red-button").on("click", function() {
        var flagsEnabled = $(this).is(":checked");
        $.ajax({
            'type': 'POST',
            'url': '/flagging/preferences/enable',
            'data': {
                'enable': flagsEnabled
            }
        })
        .done(function(data) {
            console.log("Saved :)");
        })
        .error(function(xhr, textStatus, errorThrown) {
            console.error(xhr.responseText);
        });
    });
});
