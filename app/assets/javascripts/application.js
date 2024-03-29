// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require jquery
//= require jquery_ujs
//= require activestorage
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.responsive
//= require dataTables/extras/dataTables.fixedHeader
//= require moment
//= require bootstrap-datetimepicker
//= require bootstrap-sprockets
//= require turbolinks
//= require chartkick
//= require Chart.bundle
//= require_directory ./controllers
//= require_tree ./rails_admin


// =====> Hello, Interviewers!
// In Rails 4 - 6, I got in the habit of using these functions
// to restrict my JS to the apropriate page.
//
// Not sure it'll be relevant in Rails 7, but a nice trick I picked up
// from some gist somewhere.
function controllerMatches(controllers_ary) {
  var controller = $('body').data('controller');
  return controllers_ary.indexOf(controller) !== -1;
};

function actionMatches(actions_ary) {
  var action = $('body').data('action');
  return actions_ary.indexOf(action) !== -1;
};
