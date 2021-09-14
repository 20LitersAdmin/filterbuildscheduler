// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var availabilityByCode = { 0: 'All hours', 1: 'Business hours', 2: 'After hours'}

function showPasswordWarning() {
  var pass = $("input#user_password").val();
  var passConf = $("input#user_password_confirmation").val();
  var combo = pass + passConf;
  if ( combo == "" ) {
    $("div#password_change_notice").hide();
  } else {
    $("div#password_change_notice").show();
  };
};

function emailZeroToggle() {
  var count = $("a#contactor_email").data("count")
  if (count > 0 ) {
    $("a#contactor_email").show();
    $("input#contactor_submit").hide();
  } else {
    $("a#contactor_email").hide();
    $("input#contactor_submit").show();
  }
}

function emailDirtyToggle() {
  $("a#contactor_email").hide();
  $("input#contactor_submit").show();
}

(function() {
  $(document).on("focus", "input#user_password", function(){
    showPasswordWarning();
  });

  $(document).on("focus", "input#user_password_confirmation", function(){
    showPasswordWarning();
  });

  $(document).on("blur", "input#user_password", function(){
    showPasswordWarning();
  });

  $(document).on("blur", "input#user_password_confirmation", function(){
    showPasswordWarning();
  });

  $(document).on("turbolinks:load", function(){
    emailZeroToggle();
  });

  $(document).on("change", "select#contactor_availability", function(){
    emailDirtyToggle();
  });

  $(document).on("change", "select#contactor_technology", function(){
    emailDirtyToggle();
  });

  $(document).on("click", "a#contactor_email", function(){
    var emailInput = document.getElementById("contactor_email_list");

    $("input#contactor_email_list").attr("type", "text");
    emailInput.select();
    emailInput.setSelectionRange(0, 99999); // for mobile devices

    document.execCommand("copy");
    $("input#contactor_email_list").attr("type", "hidden");

    countCommas = (emailInput.value.match(/,/g) || []).length;
    count = countCommas + 1;
    lang = "Copied " + count + " emails to the clipboard.";

    alert(lang);

    event.preventDefault();
    false;
  });

  $(document).on("change", "select.avail-select", function() {
    var select = $(this);
    var userId = parseInt($(this).attr("id"));
    var a = $(this).val();
    var url = "/users/" + userId + "/availability?a=" + a;
    $.ajax({url: url}).done(function(response) {
      if (response != a) {
        console.log('User availability update failed.');
      } else {
        var availability = availabilityByCode[a];
        select.parent().siblings('td.availability').html(availability);
      }
    });
  });

}());
