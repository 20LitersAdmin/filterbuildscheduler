function filterView(type, button) {
  // type == "count" or "tech"
  var btnId = $(button).attr("id");
  var target = "." + btnId;
  
  if (type == "count") {
    var goal = "true"
    var parent_id = ""
    if (btnId == "uncounted") {
      target = ".counted";
      goal = "false";
    };
    $(target).each(function() {
      parent_id = "#" + $(this).parents(".count-parent").attr("id");
      if ( $(this).attr("title") != goal ) {
        $(parent_id).hide();
      } else {
        $(parent_id).show();
      };
    });

  } else { // type = "tech"
    var goalStr = target.substring(6, target.length);
    $(".techs").each(function() {
      parent_id = "#" + $(this).parents(".count-parent").attr("id");
      var techStr = $(this).attr("title");
      var techAry = techStr.split(",");
      if ( techAry.includes(goalStr) ) {
        $(parent_id).show();
      } else {
        $(parent_id).hide();
      };
    });
  };
};

(function() {
  $(document).on("click", "#show_finalize_form", function() {
    $('#finalize_form').fadeIn();
    $('#counts_div').hide();
    $('#admin_div').hide();
    event.preventDefault();
  });
  $(document).on("click", "#hide_finalize_form", function() {
    $('#finalize_form').hide();
    $('#counts_div').fadeIn();
    $('#admin_div').fadeIn();
    event.preventDefault();
  });
  $(document).on("click", ".count-btn", function() {
    filterView("count", this);
  });
  $(document).on("click", ".tech-btn", function() {
    filterView("tech", this);
  });
  $(document).on("click", "#clear", function() {
    $(".count-parent").show();
  })
}());
