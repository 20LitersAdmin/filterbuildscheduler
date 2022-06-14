function toggleFlip(action) {
  var booleans = $(".label-checkbox").get();

  if(action === "check") {
    for( i = 0; i < booleans.length; i++ ) {
        booleans[i].checked = true;
      };
  } else if(action === "uncheck") {
    for( i = 0; i < booleans.length; i++ ) {
        booleans[i].checked = false;
      };
  };
};

(function() {
  $(document).on('turbolinks:load', function() {
    if(!controllerMatches(['technologies'])) { return }
  });

  $(document).on("click", ".btn-check", function() {
    var idStr = $(this).attr("id");
    var split = idStr.split("_");
    // split[0] is either "check" or "uncheck"
    toggleFlip(split[0]);
    event.preventDefault();
  });

  $(document).on("click", ".tech-checkbox", function() {
    var idStr = $(this).attr("id");
    var techsField = $('input#techs');
    var techsFieldVal = techsField.val();
    if ($(this).is(':checked')) {
      if (techsFieldVal.length == 0) {
        var newVal = idStr;
      } else {
        var newVal = techsFieldVal + ',' + idStr;
      };
    } else {
      var newVal = techsFieldVal.replace(',' + idStr, '');
      var newVal = newVal.replace(idStr, '');
    };
    techsField.val(newVal);
  });
}());
