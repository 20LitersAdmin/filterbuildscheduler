function shiftDdWells(jq_dd_ary) {
  // shift all dd.well elems over behind their previous dt elems
  jq_dd_ary.each( function() {
    var transformWidth = $(this).prev().width();
    var marginLeft = '-' + (transformWidth - 5) + 'px';
    var minWidth = (transformWidth + 10) + 'px'
    $(this).css('margin-left', marginLeft);
    $(this).css('min-width', minWidth);
  });
};

// run on full page loads
$(document).on("ready", function() {
  if ( isRailsAdminPage() && actionMatches(['show']) ) {
    ddWells = $('dd.well')
    shiftDdWells(ddWells);
  };
});

// run on ajaxComplete
$(document).ajaxComplete( function() {
  if ( isRailsAdminPage() && actionMatches(['show']) ) {
    ddWells = $('dd.well')
    shiftDdWells(ddWells);
  };
});

