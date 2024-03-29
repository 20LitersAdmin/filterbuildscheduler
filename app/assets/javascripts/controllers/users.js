// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var availabilityByCode = { 0: 'All hours', 1: 'Business hours', 2: 'After hours'};

var typeByCode = { 0: 'Trainee', 1: 'Helper', 2: 'Primary', '': '' };

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
    var emails = emailInput.value;
    var countCommas = ((emails.match(/,/g) || []).length) + 1;

    navigator.clipboard.writeText(emails).then(function(){
      alert(`Copied ${countCommas} emails to the clipboard.`);
    }, function(promise, reason) {
      console.log(`Tried to copy emails to clipboard, didn't work.`);
    });

    event.preventDefault();
    false;
  });

  $(document).on("click", "a.copy-email", function(){
    var email = this.dataset.copy;

    navigator.clipboard.writeText(email).then(function(){
      alert(`Copied ${email} to clipboard.`);
    }, function() {
      console.log(`Tried to copy email to clipboard, didn't work.`);
    });

    event.preventDefault();
    false;
  })

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

  $(document).on("change", "select.type-select", function() {
    var select = $(this);
    var userId = parseInt($(this).attr("id"));
    var t = $(this).val();
    var url = "/users/" + userId + "/leader_type?t=" + t;
    $.ajax({url: url}).done(function(response) {
      if (response == t || ( t == '' && response == null)) {
        var type = typeByCode[t];
        select.parent().siblings('td.type').html(type);
      } else {
        console.log('User leader_type update failed.');
      }
    });
  });

}());
