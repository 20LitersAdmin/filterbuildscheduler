$(document).on("turbolinks:load", function(){
  $("#load_screen").hide();

  // User#show and Pages#info accordion symbol switching
  $(".panel-title").children("a").addClass("accordion-link")

  $("a.prevent_default").on("click", function(){
    event.preventDefault;
    return false;
  });

  $('.datetimepicker').each(function(){
    var theValue = Date(this.value);
    $(this).datetimepicker({
      date: this.value,
      format: 'MMM DD YYYY hh:mm A'
    });
  });
  $('.datepicker').each(function(){
    $(this).datetimepicker({
      date: this.value,
      format: 'MMM DD YYYY',
      maxDate: this.value
    });
  });
  $('.datepicker-nomax').each(function(){
    $(this).datetimepicker({
      date: this.value,
      format: 'MMM DD YYYY'
    });
  });

  // Inventory#order && Inventory#order_all tooltips
  $(function () {
    $('[data-toggle="tooltip"]').tooltip()
  });

  // User#show and Pages#info accordion symbol switching
  function collapsedFAs(clicked) {
    var collapsed = $('div[aria-expanded="false"]').get();
    var id = "";

    for( i = 0; i < collapsed.length; i++) {
      id = "#" + $(collapsed[i]).attr("aria-labelledby");
      $(id).find(".fa-minus").hide();
      $(id).find(".fa-plus").show();
    };
  };

  $(document).on("click", "a.accordion-link", function() {
    $(this).children(".fa").toggle();

    collapsedFAs(this);
  });

  $(document).on("click", ".use-load-screen", function() {
    // TODO: this should fail if "Target=_blank"
    $("#load_screen").show();
  });
});
