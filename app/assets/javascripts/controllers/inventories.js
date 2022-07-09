// InventoriesController#edit page: filters _count paritals
function filterTech(techId) {
  $('div.count-wrapper').hide();
  var finder = '[data-techs*="' + techId + '"]';
  $(finder).show();
};

// InventoriesController#edit page: filters _count paritals
function filterStatus(status) {
  // status options: [uncounted, partial, counted]
  $('div.count-wrapper').hide();
  var finder = '[data-status="' + status + '"]';
  $(finder).show();
};

function stringMaker(float, fixed) {
  num = float.toFixed(fixed);
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
};

function orderTotal() {
  var range = [ $("#order_item_div"), $("#order_supplier_div") ];
  var target = [ $("#item_ttl"), $("#supplier_ttl") ];
  var ttl = [];
  var ttlStr = [];
  var amtStr, amt;

  for( i = 0; i < range.length; i++ ) {
    var booleans = range[i].find(".order_checkbox").get();
    ttl[i] = 0;

    for( j = 0; j < booleans.length; j++ ) {
      if (booleans[j].checked === true ) {
        amtStr = $( "#" + booleans[j].id ).parents("tr").find(".order-total-amt").html();
        amt = parseFloat( amtStr.replace(",","") );
        ttl[i] += amt;
      };
    };

    ttlStr[i] = stringMaker(ttl[i], 2);
    target[i].html(ttlStr[i]);
  };
};

function toggleCheck(action,scope) {
  if(scope === "all") {
    var booleans = $(".order_checkbox").get();
  } else {
    // scope === id
    var tableId = "#order_supplier_tbl_" + scope
    var booleans = $(tableId).find("input.order_checkbox").get();
  };

  if(action === "check") {
    for( i = 0; i < booleans.length; i++ ) {
        booleans[i].checked = true;
        // twinSnyc(booleans[i]);
      };
  } else if(action === "uncheck") {
    for( i = 0; i < booleans.length; i++ ) {
        booleans[i].checked = false;
        // twinSnyc(booleans[i]);
      };
  };
  orderTotal();
};

function twinSnyc(checkboxA) {
  var idStr = $(checkboxA).attr("id");
  var inputA = $(checkboxA).parents('tr').find('.min-order-field');
  var inputAval = $(inputA).val() || 0;
  var quantity = parseFloat( inputAval.replace(",","") );
  var state = $(checkboxA).prop("checked")
  var split = idStr.split("_");
  // split: ("checkbox",["item", "supplier"],"uid")
  if(split[1] === "item") {
    var locator = "supplier";
  } else {
    var locator = "item";
  };

  var checkboxB = "#checkbox_" + locator + "_" + split[2];
  $(checkboxB).prop("checked", state);

  var inputB = "#" + locator + "_min_order_" + split[2];
  $(inputB).val(quantity);
  reformat(inputB);
};

function lineTotal(source) {
  var quantity = parseFloat( $(source).val().replace(",","") );
  var itemCostSpan = $(source).parents("tr").find(".item-cost-value");
  var itemCost = parseFloat( $(itemCostSpan).html().replace(",","") );

  var newTotalStr = stringMaker( (quantity * itemCost), 2 );
  var totalCostSpan = $(source).parents("tr").find(".order-total-amt");
  $(totalCostSpan).html(newTotalStr);
};

function lineCheck(source) {
  var checkbox = $(source).parents("tr").find(".order_checkbox");
  if( $(checkbox).prop("checked") === false ) {
    $(checkbox).prop("checked", true);
  };
  twinSnyc(checkbox);
};

function reformat(source) {
  var unformatted = $(source).val();
  var formatted = unformatted.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  $(source).val(formatted);
};

(function() {
  // Inventory#edit finalize buttons
  $(document).on("click", "#show_finalize_form", function() {
    $('#finalize_form').fadeIn();
    $('#counts_div').hide();
    $('#filter_div').hide();
    event.preventDefault();
  });
  $(document).on("click", "#hide_finalize_form", function() {
    $('#finalize_form').hide();
    $('#counts_div').fadeIn();
    $('#filter_div').fadeIn();
    event.preventDefault();
  });
  // Inventory#edit filter buttons
  $(document).on("click", ".status-btn", function() {
    var status = $(this).data('action')
    filterStatus(status);
    // filterView("count", this);
    event.preventDefault();
  });
  $(document).on("click", ".tech-btn", function() {
    var techId = $(this).data('tech');
    filterTech(techId);
    event.preventDefault();
  });
  $(document).on("click", '[data-action="show_all"]', function() {
    // Show all counts
    $("div.count-wrapper").show();
    event.preventDefault();
  });

  // Inventory#edit search field
  $(document).on("keyup", "#search", function() {
    var term = $("#search").val().toUpperCase();
    var collection = $(".count-wrapper").get();
    var title;
    var uid;

    if (term === "") {
      $('.count-wrapper').show();
    } else {
      for ( i = 0; i < collection.length; i++ ) {
      title = $(collection[i]).find(".count-title");
      uid = $(collection[i]).find(".count-uid");
      tech = $(collection[i]).find(".count-tech");
      if (
        $(title).html().toUpperCase().indexOf(term) === -1
        && $(uid).html().toUpperCase().indexOf(term) === -1
        && $(tech).html().toUpperCase().indexOf(term) === -1
        ) {
        $(collection[i]).hide();
      } else {
        $(collection[i]).show();
      };
    };
    }
  });

  $(document).on("turbolinks:load", function(){
    // Inventory#order filter buttons
    $("#item_btn").hide();
    $('#order_supplier_div').hide();
    $('[data-toggle="popover"]').popover();
  });

  // Inventory#order filter buttons
  $(document).on("click", "#supplier_btn", function() {
    $("#order_item_div").hide();
    $("#item_ttl").hide();
    $(this).hide();
    $("#order_supplier_div").show();
    $("#supplier_ttl").show();
    $("#item_btn").show();
    event.preventDefault();
  });

  $(document).on("click", "#item_btn", function() {
    $("#order_supplier_div").hide();
    $("#supplier_ttl").hide();
    $(this).hide();
    $("#order_item_div").show();
    $("#item_ttl").show();
    $("#supplier_btn").show();
    event.preventDefault();
  });

  // Inventory#order checkbox buttons && checkboxes
  $(document).on("click", ".btn-check", function() {
    var idStr = $(this).attr("id");
    var split = idStr.split("_");
    // ["check" || "uncheck", "all" || "id"]
    toggleCheck(split[0],split[1]);
    event.preventDefault();
  });

  $(document).on("change", ".order_checkbox", function() {
    twinSnyc(this);
    orderTotal();
  });

  // Inventory#order form field
  $(document).on("change", ".min-order-field", function() {
    lineTotal(this);
    lineCheck(this);
    reformat(this);
    orderTotal();
  });

  // Inventory#order update-ordered-btn for saving last_ordered_quantity and last_ordered_date to record remotely
  $(document).on("click", ".update-ordered-btn", function() {
    var uid = $(this).data('item');
    var quantity = parseInt($('tr#' + uid).find('td.min-order').find('input').val().replace(/,/g, ""));

    $.ajax({
      url: '/inventories/update_ordered',
      type: 'patch',
      data: { item: { uid: uid, quantity: quantity } },
      success: function(response) {
        // update the order language
        var uid = response['uid'];
        $('tr#' + uid).each( function() {
          $(this).find('i.order-language').html(response['order_language']);
        });

        // clear out any old flash messages
        $('#scrolling div.alert').remove();

        // fake a flash message
        var flashMessage = '<div class="alert fade in success"><button class="close" data-dismiss="alert">x</button>' + response['message'] + "</div>";
        $('#scrolling').prepend(flashMessage);
      },
      error: function(response) {
        console.log(response);
      },
    });
    event.preventDefault;
    return false;
  });
}());
