(function() {
  $(document).on("click", "#show_finalize_form", function() {
    $('#finalize_form').fadeIn();
    $('#counts_div').hide();
    event.preventDefault();
  });
  $(document).on("click", "#hide_finalize_form", function() {
    $('#finalize_form').hide();
    $('#counts_div').fadeIn();
    event.preventDefault();
  });
}());
