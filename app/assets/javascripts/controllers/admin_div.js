// TODO: delete this file if no more _*_functions partials
$(document).on("turbolinks:load", function(){
  // _inventory_functions and _event_functions partials
  $("#hide_admin").on("click", function(){
    $(".admin-div").addClass("hidden");
  });
});
