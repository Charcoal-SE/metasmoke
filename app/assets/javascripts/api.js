$(document).ready(function() {
   $("#create_filter").on("click", function(ev) {
       var checkboxes = $("input[type=checkbox]");
       var bits = new Array(checkboxes.length);

       $.each(checkboxes, function(index, item) {
           var $item = $(item);
           var arrayIndex = $item.data("index");
           if ($item.is(":checked")) {
               bits[arrayIndex] = 1;
           }
           else {
               bits[arrayIndex] = 0;
           }
       });

       var unsafeFilter = "";
       while (bits.length) {
           var nextByte = bits.splice(0, 8).join("");
           var charCode = parseInt(nextByte.toString(), 2);
           unsafeFilter += String.fromCharCode(charCode);
           console.log(nextByte, charCode, unsafeFilter);
       }

       var filter = encodeURIComponent(unsafeFilter);
       prompt("Calculated, URL-encoded filter:", filter);
   });
});
