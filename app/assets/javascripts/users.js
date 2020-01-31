// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

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
    $("p#contactor_zero").hide();
  } else {
    $("a#contactor_email").hide();
    $("input#contactor_submit").show();
    $("p#contactor_zero").show();
  }
}

function emailDirtyToggle() {
  $("a#contactor_email").hide();
  $("input#contactor_submit").show();
  $("p#contactor_zero").hide();
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

  $(document).on("change", "select.avail-select", function() {
    userId = parseInt($(this).attr("id"));
    a = $(this).val();
    url = "/users/" + userId + "/availability?a=" + a;
    $.ajax({url: url}).done(function(response) {
      if (response != a) {
        console.log('An error occured.');
      } else {
        console.log('Success!');
      }
    });
  });

}());
