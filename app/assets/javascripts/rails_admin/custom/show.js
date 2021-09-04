$(document).on("ready", function() {
  // only run if on a rails_admin page
  if ( !isRailsAdminPage() && !actionMatches(['show']) ) {
    return;
  };

  // shift dd.well elems over behind their previous dt elems
  $('dd.well').each( function() {
    var transformWidth = $(this).prev().css('width');
    var transformText = 'translateX(-' + transformWidth + ')';
    $(this).css('transform', transformText);
  });
});

