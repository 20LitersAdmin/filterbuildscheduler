$(document).on("turbolinks:load", function(){
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
      "<'col-xs-12 no-overflow center' B>"+
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
});
