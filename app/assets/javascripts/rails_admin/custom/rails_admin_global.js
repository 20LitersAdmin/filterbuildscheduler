function isRailsAdminPage() {
  return $('body').hasClass('rails_admin');
};

function isRailsAdminDashboard() {
  // check for path '/admin'
  // don't rely on <body data-action='dashboard'> because this can fail to be updated when calls are AJAXed
  return window.location.pathname.split('/').join('') == 'admin'
}

function controllerMatches(controllers_ary) {
  var controller = $('body').data('controller');
  return controllers_ary.indexOf(controller) !== -1;
};

function actionMatches(actions_ary) {
  var action = $('body').data('action');
  return actions_ary.indexOf(action) !== -1;
};

function setBodyDataTags() {
  // I don't think these JS files are accessible outside of RailsAdmin, but to be safe, wrap everything in a check to see if we're inside RailsAdmin and not on the dashboard
  if ( isRailsAdminPage() && !isRailsAdminDashboard() ) {
    dataAction = $('body').data('action');
    pathAry = window.location.pathname.split('/');
    lastItem = pathAry[pathAry.length -1];

    if ( (lastItem == 'edit') && (dataAction != 'edit') ) {
      $('body').data('action', 'edit');
    } else if ( (lastItem == 'new') && (dataAction != 'new') ) {
      $('body').data('action', 'new');
    } else if ( ($.isNumeric(lastItem)) && (dataAction != 'show') ) {
      // technically ($.isNumeric(lastItem) will return true for other actions [create, delete, restore], but since they don't have views, it's fine to pretend we're on the show view.
      $('body').data('action', 'show');
    } else {
      // Else lastItem can be assumed to be a model name and therefore data-action should be 'index'
      dataController = $('body').data('controller');
      if ( lastItem != dataController ) {
        $('body').data('controller', lastItem);
        $('body').data('action', 'index');
      };
    };
  };
};

// Ensure <body> tag always has data attributes: data-controller && data-action
// views/layouts/rails_admin/application.html.haml sets the data values for full page loads
// ajaxComplete calls need to update data attributes so that rails_admin/custom/*.js functions can use controllerMatches() and actionMatches() confidently
$(document).ajaxComplete( function() {
  setBodyDataTags();
});
