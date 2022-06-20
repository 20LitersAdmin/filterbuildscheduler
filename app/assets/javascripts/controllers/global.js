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

  $('.datepicker-maxtoday').each(function(){
    $(this).datetimepicker({
      date: this.value,
      format: 'MMM DD YYYY',
      maxDate: Date.now()
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

  // Inventories#paper && Technologies#labels techs field mgmt
  function techsFieldMgmt(source) {

  };

  $(document).on("click", "a.accordion-link", function() {
    $(this).children(".fa").toggle();

    collapsedFAs(this);
  });

  $(document).on("click", ".use-load-screen", function() {
    // TODO: this should fail if "Target=_blank"
    $("#load_screen").show();
  });

  // global print button function
  $(document).on("click", "#print_btn", function() {
    event.preventDefault;
    window.print();
  })

  // Inventories#paper && Technologies#labels techs field mgmt
  // btn controls the form field, the checkbox inside is just UX
  $(document).on("click", ".tech-checkbox", function() {
    // if user clicks the checkbox inside the button, just toggle it back quick, else the btn click function will do it again
    $(this).prop("checked", !$(this).prop("checked"));
  });

  $(document).on("click", ".tech-chooser .btn-group .btn", function() {
    var checkbox = $(this).children('.tech-checkbox');
    checkbox.prop("checked", !checkbox.prop("checked"));
    var idStr = checkbox.attr("id");
    var techsField = $('input#techs');
    var techsFieldVal = techsField.val();
    if (checkbox.is(':checked')) {
      if (techsFieldVal.length == 0) {
        var newVal = idStr;
      } else {
        var newVal = techsFieldVal + ',' + idStr;
      };
    } else {
      var newVal = techsFieldVal.replace(',' + idStr, '');
      var newVal = newVal.replace(idStr, '');
    };
    techsField.val(newVal);
  });
});
