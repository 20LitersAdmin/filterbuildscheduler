$(document).on("turbolinks:load", function(){
  // User#show and Pages#info accordion symbol switching
  $(".panel-title").children("a").addClass("accordion-link")

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

  /* Create an array with the values of all the checkboxes in a column */
  $.fn.dataTable.ext.order['dom-checkbox'] = function  ( settings, col ) {
    return this.api().column( col, {order:'index'} ).nodes().map( function ( td, i ) {
      return $('input', td).prop('checked') ? '1' : '0';
    });
  }

  $('.datatable').DataTable({
    retrieve: true,
    order: [[0, "asc"]],
    pageLength: -1,
    lengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"] ],
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-12 no-overflow center' B>"+
      "<'col-xs-4 no-overflow'l>"+
      "<'col-xs-8 no-overflow'f>"+
      "t"+
      "<'col-xs-8'p>",
    buttons: [ 'copy', 'csv', 'excel', 'print' ],
    language: {
      paginate: {
        first: "&#8676",
        previous: "&#8592",
        next: "&#8594",
        last: "&#8677"
      }
    }
  });

  $('.datatable-export').DataTable({
    retrieve: true,
    order: [[0, "asc"]],
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "t"+
      "<'col-xs-12 no-overflow center' B>",
    buttons: [ 'copy', 'csv', 'excel', 'print' ],
    language: {
      paginate: {
        first: "&#8676",
        previous: "&#8592",
        next: "&#8594",
        last: "&#8677"
      }
    }
  });

  $('.datatable-paging').DataTable({
    order: [[0, "asc"]],
    lengthMenu: [[10, 25, 50, 100, -1], [10, 25, 50, 100, "All"] ],
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-12 no-overflow center' B>"+
      "<'col-xs-4 no-overflow'l>"+
      "<'col-xs-8 no-overflow'f>"+
      "t"+
      "<'col-xs-8'p>",
    buttons: [ 'copy', 'csv', 'excel', 'print' ],
    language: {
      paginate: {
        first: "&#8676",
        previous: "&#8592",
        next: "&#8594",
        last: "&#8677"
      }
    }
  });

  $('.datatable-slim').DataTable({
    retrieve: true,
    order: [[0, "asc"]],
    paging: false,
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-4 no-overflow'l>"+
      "<'col-xs-8 no-overflow'f>"+
      "t"+
      "<'col-xs-8'p>",
  });

  $('.datatable-slim-nosort').DataTable({
    retrieve: true,
    order: false,
    paging: false,
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-4 no-overflow'l>"+
      "<'col-xs-8 no-overflow'f>"+
      "t"+
      "<'col-xs-8'p>",
  });



  $('.datatable-search').DataTable({
    retrieve: true,
    order: [],
    paging: false,
    responsive: true,
    autoWidth: false,
    info: false,
    dom: "ft",
    columnDefs: [
    { "orderable": false, "targets": -1 }
  ]
  });

  $('.datatable-order-item').DataTable({
    retrieve: true,
    order: [[0, "asc"]],
    pageLength: -1,
    lengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"] ],
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-12 no-overflow center' B>"+
      "<'col-xs-4 no-overflow'l>"+
      "<'col-xs-8 no-overflow'f>"+
      "t"+
      "<'col-xs-8'p>",
    buttons: [ 'copy', 'csv', 'excel', 'print' ],
    language: {
      paginate: {
        first: "&#8676",
        previous: "&#8592",
        next: "&#8594",
        last: "&#8677"
      }
    },
    columns: [
      null, null, null, null, null, null, null, null, null,
      { "orderDataType": "dom-checkbox", "orderSequence": [ "desc" ] }
    ]
  });

  $('.datatable-order-supplier').DataTable({
    retrieve: true,
    order: [[0, "asc"]],
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "t"+
      "<'col-xs-12 no-overflow center' B>",
    buttons: [ 'copy', 'csv', 'excel', 'print' ],
    language: {
      paginate: {
        first: "&#8676",
        previous: "&#8592",
        next: "&#8594",
        last: "&#8677"
      }
    },
    columns: [
      null, null, null, null, null, null, null, null, null,
      { "orderDataType": "dom-checkbox", "orderSequence": [ "desc" ] }
    ]
  });
});

// User#show and Pages#info accordion symbol switching
function collapsedFAs(clicked) {
  var collapsed = $('div[aria-expanded="false"]').get();
  var id = "";

  for( i = 0; i < collapsed.length; i++) {
    id = "#" + $(collapsed[i]).attr("aria-labelledby");
    $(id).find(".fa-minus").hide();
    $(id).find(".fa-plus").show();
  }
}

$(document).on("click", "a.accordion-link", function() {
  $(this).children(".fa").toggle();

  collapsedFAs(this);
});

$(document).on("click", ".use-load-screen", function() {
  $("#load_screen").show();
});

$(document).on("turbolinks:load", function() {
  $("#load_screen").hide();
});


