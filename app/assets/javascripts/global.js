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

  $('.datatable').DataTable({
    retrieve: true,
    order: [[0, "asc"]],
    pageLength: -1,
    lengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"] ],
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'row'"+
        "<'col-xs-12 no-overflow center' B>"+
        "<'col-xs-4 no-overflow'l>"+
        "<'col-xs-8 no-overflow'f>"+
      "r>"+
      "t"+
      "<'row'"+
      "<'col-xs-8'p>"+
      ">",
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
      "<'row'"+
        "<'col-xs-12 no-overflow center' B>"+
        "<'col-xs-4 no-overflow'l>"+
        "<'col-xs-8 no-overflow'f>"+
      "r>"+
      "t"+
      "<'row'"+
      "<'col-xs-8'p>"+
      ">",
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
      "<'row'"+
        "<'col-xs-12 no-overflow center'>"+
        "<'col-xs-4 no-overflow'l>"+
        "<'col-xs-8 no-overflow'f>"+
      "r>"+
      "t"+
      "<'row'"+
      "<'col-xs-8'p>"+
      "<'col-xs-12 no-overflow center'>"+
      ">"
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
});

// User#show and Pages#info accordion symbol switching
$(document).on("click", "a.accordion-link", function() {
  $(this).children(".fa").toggle();
});
