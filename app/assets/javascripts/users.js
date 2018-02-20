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

}());