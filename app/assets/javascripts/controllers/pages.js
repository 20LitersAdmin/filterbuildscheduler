$(document).on("click", "a#toggle_event_detail", function() {
  $("div#event_detail").toggle();
  event.preventDefault;
  return false;
});

$(document).on("click", "a#toggle_people_detail", function() {
  $("div#people_detail").toggle();
  event.preventDefault;
  return false;
});
