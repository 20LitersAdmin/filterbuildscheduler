// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).on('turbolinks:load', function() {
  if(!(controllerMatches(['events','registrations']))) {
    return;
  };

  // Event/show registration form
  $(document).on("click", "#modal_accept_waiver", function() {
    $("#registration_accept_waiver").prop("checked", true);
    $("#waiverModal").modal('hide');
  });

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
  };

  function clearOccurrences(){
    $("ol#occurrences").empty();
  };

  function showOccurrences(){
    var id = $('#event_id')
    var startTime = $('#replicator_start_time').val();
    var endTime = $('#replicator_end_time').val();
    var frequency = $('#replicator_frequency').val();
    var occurrences = $('#replicator_occurrences').val();
    url = window.location.pathname + "_occurrences?s=" + startTime + "&e=" + endTime + "&f=" + frequency + "&o=" + occurrences

    if(frequency != "") {
      $.ajax({url: url}).done(function(response) {
        var target = $('ol#occurrences')
        $.each(response, function(i,hsh){
          var append = "<li>" + hsh["s"] + " - " + hsh["e"] + "</li>"
          target.append(append);
        });
      });
    };
  };

  // Event/edit form
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

  if (actionMatches(['edit'])) {
    attendanceCounter();
    $("#btn_uncheck_all").hide();
  };
  $(document).on("click", "#btn_copy", function(){
    var url = $("#copy_url")
    url.select();
    document.execCommand("Copy");
    url.blur();
    $("#copy_confirm").fadeIn('normal', function() {
      $(this).delay(3000).fadeOut();
    });
    event.preventDefault();
  });

  if (actionMatches(['replicate'])) {
    $(document).on("change", ":input", "form#new_replicator",function(){
      clearOccurrences();
      showOccurrences();
    });

    $(document).on("dp.change", ".datetimepicker", "form#new_replicator",function(){
      clearOccurrences();
      showOccurrences();
    });
  };
});
