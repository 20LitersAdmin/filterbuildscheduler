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

function orderTotal(ttl, checked) {
  alert("total: " + ttl + "; checked: " + checked);
};

function toggleCheck(action,scope) {
  if(scope === "all") {
    var booleans = $(".order_check").get();
  } else {
    // scope === id
    var table_id = "#order_supplier_tbl_" + scope
    var booleans = $(table_id).find("input.order_check").get();
  };
  
  if(action === "check") {
    for( i = 0; i < booleans.length; i++ ) {
        booleans[i].checked = true;
      };
  } else if(action === "uncheck") {
    for( i = 0; i < booleans.length; i++ ) {
        booleans[i].checked = false;
      };
  };

  var checked_count = 0;
  for( i = 0; i < booleans.length; i++ ) {
    if(booleans[i].checked === true) {
      checked_count++;
    };
  };

  orderTotal(booleans.length, checked_count);
}

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
  });
  $(document).on("click", "#supplier_btn", function() {
    $("#order_item_div").hide();
    $("#supplier_admin").hide();
    $("#order_supplier_div").show();
    $("#item_admin").show();
    event.preventDefault();
  });
  $(document).on("click", "#item_btn", function() {
    $("#order_supplier_div").hide();
    $("#item_admin").hide();
    $("#order_item_div").show();
    $("#supplier_admin").show();
    event.preventDefault();
  });

  $(document).on("click", ".btn-check", function() {
    var id_str = $(this).attr("id");
    var split = id_str.split("_")
    toggleCheck(split[0],split[1]);
    event.preventDefault();
  });

  // $(document).on("click", "#order_check_all", function() {
  //   toggleCheck("check","all");
  //   event.preventDefault();
  // });
  // $(document).on("click", "#order_uncheck_all", function() {
  //   toggleCheck("uncheck","all");
  //   event.preventDefault();
  // });

}());
