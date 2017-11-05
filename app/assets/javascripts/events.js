// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

(function() {
  $(document).on("click", ".btn-accept", function() {
    $("input[type=checkbox]#registration_waiver_accepted").prop("checked", true);
    $("#waiverModal").modal('hide');
  });
}());
