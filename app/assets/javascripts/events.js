// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function attendanceCounter(){
  var booleans = $(".event_registrations_attended input[type=checkbox]").get();
  var inputs = $(".event_registrations_guests_attended input[type=number]").get();
  var count = 0
  for ( i = 0; i < booleans.length; i++) {
    if(booleans[i].checked) {
      count++;
    };
  };
  for ( i = 0; i < inputs.length; i++) {
    count += parseInt(inputs[i].value);
  };
  $("#attendance_counter").html(count);
  $("#event_attendance").val(count);
}

(function() {
  $(document).on("click", ".btn-accept-waiver", function() {
    $("input[type=checkbox]#registration_waiver_accepted").prop("checked", true);
    $("#waiverModal").modal('hide');
  });
  $(document).on("change", ".event_registrations_attended input[type=checkbox]", function() {
    attendanceCounter();
  });
  $(document).on("change", ".event_registrations_guests_attended input[type=number]", function() {
    attendanceCounter();
  });
  $(document).on("click", "#btn_check_all", function() {
    var booleans = $(".event_registrations_attended input[type=checkbox]").get();
    for( i = 0; i < booleans.length; i++ ) {
      booleans[i].checked = true;
    };
    $("#btn_check_all").hide();
    $("#btn_uncheck_all").show();
    attendanceCounter();
    event.preventDefault();
  });
  $(document).on("click", "#btn_uncheck_all", function() {
    var booleans = $(".event_registrations_attended input[type=checkbox]").get();
    for( i = 0; i < booleans.length; i++ ) {
      booleans[i].checked = false;
    };
    $("#btn_uncheck_all").hide();
    $("#btn_check_all").show();
    attendanceCounter();
    event.preventDefault();
  });
  $(document).on("turbolinks:load", function(){
    attendanceCounter();
    $("#btn_uncheck_all").hide();
  })
}());
