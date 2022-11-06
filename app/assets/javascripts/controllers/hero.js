// =====> Hello, Interviewers!
//
// If Bootstrap columns just aren't quite dynamic enough,  roll your own!

function sizeStatsBlocks() {
  var statBlocks = $('.stat-block');
  var groupSize;

  if (window.innerWidth > 920) {
    groupSize = 6;
  } else {
    groupSize = 3;
  };
  var groups = statBlocks.length/groupSize;
  var fullRows = Math.floor(groups);
  var breakPoint = (fullRows * groupSize) - 1;
  var remainder = statBlocks.length - (groupSize * fullRows);
  var groupWidth = 100/groupSize + "%";
  var remainderWidth = 100/remainder + "%";

  statBlocks.each(function(index) {
    if (index <= breakPoint) {
      $(this).css('width', groupWidth);
    } else {
      $(this).css('width', remainderWidth);
    };
  });
};

$(document).on("turbolinks:load", function(){
  if ((controllerMatches('events') && actionMatches('index'))) {
    sizeStatsBlocks();

    $(window).on("resize", function(){
      sizeStatsBlocks();
    });
  }
});
