function shiftDdWells(jq_dd_ary) {
  // shift all dd.well elems over behind their previous dt elems
  jq_dd_ary.each( function() {
    var transformWidth = $(this).prev('dt').children('.label').width()
    var marginLeft = '-' + (transformWidth + 5) + 'px';
    var minWidth = (transformWidth + 10) + 'px'
    $(this).css('margin-left', marginLeft);
    $(this).css('min-width', minWidth);
  });
};

function runShowPageFunctions() {
  if ( isRailsAdminPage() && actionMatches(['show']) ) {
    ddWells = $('dd.well')
    shiftDdWells(ddWells);
    // .well is set to max-width: 30% for long text block fields
    // but line charts should get max-width: 100%
    $('canvas').parents('.well').addClass('full-width');
  };
};

// run on full page loads
$(document).on("ready", function() {
  runShowPageFunctions();
});

// run on ajaxComplete
$(document).ajaxComplete( function() {
  runShowPageFunctions();
});



