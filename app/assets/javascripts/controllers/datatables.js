$(document).on("turbolinks:load", function(){
  function addCommas(nStr) {
    nStr += '';
    x = nStr.split('.');
    x1 = x[0];
    x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
      x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
  };

  /* Create an array with the values of all the checkboxes in a column */
  $.fn.dataTable.ext.order['dom-checkbox'] = function  ( settings, col ) {
    return this.api().column( col, {order:'index'} ).nodes().map( function ( td, i ) {
      return $('input', td).prop('checked') ? '1' : '0';
    });
  }

  $('.datatable').DataTable({
    retrieve: true,
    order: [[0, "asc"]],
    lengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"] ],
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-12 no-overflow center no-print' B>"+
      "<'col-xs-4 no-overflow no-print'l>"+
      "<'col-xs-8 no-overflow no-print'f>"+
      "t"+
      "<'col-xs-8 no-print'p>",
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
    pageLength: -1,
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

  $('.datatable-tech-quantities').DataTable({
    retrieve: true,
    order: [[1, "asc"]],
    pageLength: -1,
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-12 no-overflow center no-print' B>"+
      "t"+
      "<'col-xs-12 no-overflow center no-print' B>",
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

  $('.datatable-inventory-search').DataTable({
    retrieve: true,
    order: [],
    paging: false,
    responsive: true,
    autoWidth: false,
    info: false,
    dom: "ft"
  });

  $('.datatable-item-list').DataTable({
    retrieve: true,
    order: [[0, "asc"]],
    pageLength: -1,
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-12 no-overflow center' B>" +
      "t",
    buttons: [ 'copy', 'csv', 'excel', 'print' ]
  });

  $('.datatable-item-snapshot').DataTable({
    headerCallback: function (row, data, start, end, display) {
      var api = this.api();
      // Remove string formatting
      var intVal = function (i) {
        return typeof i === 'string' ? i.replace(/[\$,]/g, '') * 1 : typeof i === 'number' ? i : 0;
      };

      total = api.column(-1).data().reduce(function (a, b) { return intVal(a) + intVal(b)}, 0);

      $(api.column(-1).header()).html('Cost Ttl $' + addCommas(total.toFixed(2)));
    },
    retrieve: true,
    order: [[0, "asc"]],
    pageLength: -1,
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-12 no-overflow center' B>" +
      "t",
    buttons: [ 'copy', 'csv', 'excel', 'print' ]
  });

  $('.datatable-label-chooser').DataTable({
    retrieve: true,
    order: [[0, "asc"]],
    lengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"] ],
    pageLength: -1,
    responsive: true,
    autoWidth: false,
    info: false,
    columnDefs: [
      { "orderable": false, "targets": 1 }
    ],
    dom:
      "<'col-xs-4 no-overflow'l>"+
      "<'col-xs-8 no-overflow'f>"+
      "t",
    columns: [
      null, null,
      { "orderDataType": "dom-checkbox", "orderSequence": [ "desc" ] }
    ]
  });

  $('.datatable-leaders').DataTable({
    retrieve: true,
    paging: false,
    order: [[0, "asc"]],
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-12 no-overflow center' B>"+
      "<'col-xs-12 no-overflow'f>"+
      "t",
    buttons: [
      {
        extend: 'copy',
        exportOptions: {
          columns: [0, 1, 2, 3, 5, 7, 8]
        }
      },
      {
        extend: 'csv',
        exportOptions: {
          columns: [0, 1, 2, 3, 5, 7, 8]
        }
      },
      {
        extend: 'excel',
        exportOptions: {
          columns: [0, 1, 2, 3, 5, 7, 8]
        }
      },
      {
        extend: 'print',
        exportOptions: {
          columns: [0, 1, 2, 3, 5, 7, 8]
        }
      }
    ]
  });

  $('.datatable-events-lead').DataTable({
    retrieve: true,
    paging: false,
    order: [[2, "asc"]],
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
    columnDefs: [
      { "targets": [ 0, 3], "orderable": false  }
    ],
    language: {
      paginate: {
        first: "&#8676",
        previous: "&#8592",
        next: "&#8594",
        last: "&#8677"
      }
    }
  });

  $('.datatable-order-events').DataTable({
    retrieve: true,
    order: [[1, "desc"]],
    pageLength: 25,
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

  $('.datatable-order-events-slim').DataTable({
    retrieve: true,
    order: [[1, "desc"]],
    paging: false,
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-4 no-overflow'l>"+
      "<'col-xs-8 no-overflow'f>"+
      "t"+
      "<'col-xs-8'p>"
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
      null, null, null, null, null, null, null, null,
      { "orderDataType": "dom-checkbox", "orderSequence": [ "desc" ] }
    ]
  });

  $('.datatable-paging').DataTable({
    order: [[0, "asc"]],
    lengthMenu: [[10, 25, 50, 100, -1], [10, 25, 50, 100, "All"] ],
    pageLength: -1,
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-12 no-overflow center no-print' B>"+
      "<'col-xs-4 no-overflow no-print'l>"+
      "<'col-xs-8 no-overflow no-print'f>"+
      "t"+
      "<'col-xs-8 no-print'p>",
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

  $('.datatable-paging-users').DataTable({
    order: false,
    lengthMenu: [[50, 100, 200, 500, -1], [50, 100, 200, 500, "All"] ],
    pageLength: 50,
    responsive: true,
    autoWidth: false,
    info: false,
    dom:
      "<'col-xs-4 no-overflow no-print'l>"+
      "<'col-xs-8 no-overflow no-print'f>"+
      "t"+
      "<'col-xs-8 no-print'p>",
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
});
