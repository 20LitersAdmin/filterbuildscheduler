// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function manageExpectations(focus) {
  if (focus == "loose") {
    var oldLoose = parseInt($('#expected_loose_count').html())
    var newLoose = parseInt(document.getElementById("count_loose_count").value)
    var diff = newLoose - oldLoose
    if (Math.abs(diff) > 10) {
      $('#expected_loose_count_parent').removeClass("empty");
    } else {
      $('#expected_loose_count_parent').addClass("empty");
    };
  } else {
    var oldBoxed = parseInt($('#expected_box_count').html())
    var newBoxed = parseInt(document.getElementById("count_unopened_boxes_count").value)
    var diff = newBoxed - oldBoxed
    if (Math.abs(diff) > 10) {
      $('#expected_box_count_parent').removeClass("empty");
    } else {
      $('#expected_box_count_parent').addClass("empty");
    };
  };
};

(function() {
  $(document).on("change", "#count_unopened_boxes_count", function() {
    manageExpectations("box");
  });
  $(document).on("change", "#count_loose_count", function() {
    manageExpectations("loose");
  });
}());
