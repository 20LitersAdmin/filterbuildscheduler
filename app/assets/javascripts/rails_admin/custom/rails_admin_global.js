function isRailsAdminPage() {
  return $('body').hasClass('rails_admin');
};

function isRailsAdminDashboard() {
  // check that the path matches '/admin' exactly
  // don't rely on <body data-action='dashboard'> because this can fail to be updated when calls are AJAXed
  return window.location.pathname.split('/').join('') == 'admin'
}

function controllerMatches(controllers_ary) {
  var controller = $('body').data('controller');
  return controllers_ary.indexOf(controller) !== -1;
};

function actionMatches(actions_ary) {
  var action = $('body').attr('data-action');
  return actions_ary.indexOf(action) !== -1;
};

function setBodyDataTags() {
  // I don't think these JS files are accessible outside of RailsAdmin, but to be safe, wrap everything in a check to see if we're inside RailsAdmin and not on the dashboard
  if ( isRailsAdminPage() && !isRailsAdminDashboard() ) {
    dataAction = $('body').attr('data-action');
    pathAry = window.location.pathname.split('/');
    lastItem = pathAry[pathAry.length -1];

    if ( lastItem == 'edit') {
      $('body').attr('data-action', 'edit');
    } else if ( lastItem == 'new') {
      $('body').attr('data-action', 'new');
    } else if ( $.isNumeric(lastItem) ) {
      // technically ($.isNumeric(lastItem) will return true for other actions [create, delete, restore], but since they don't have views, it's fine to pretend we're on the show view.
      $('body').attr('data-action', 'show');
    } else {
      // Else lastItem can be assumed to be a model name and therefore data-action should be 'index'
      $('body').attr('data-controller', lastItem);
      $('body').attr('data-action', 'index');
    };
  };
};

function confirmationOnDestroy() {
  // destroy links should behave similar to Rails' data-confirm: 'Are you sure?'
  if ( isRailsAdminPage() && !isRailsAdminDashboard() ) {
    // pjax can't be interrupted as usual, so just remove it
    $('li.destroy_member_link a').removeClass('pjax');

    $(document).on('click', 'li.destroy_member_link a', function() {
      var response = confirm('Destroying is permanent. Are you sure?');
      if (response == false) {
        event.preventDefault();
        return false;
      };
    });
  };
};

// Ensure <body> tag always has data attributes: data-controller && data-action
// views/layouts/rails_admin/application.html.haml sets the data values for full page loads, so it's not needed on $(document).ready
// BUT ajaxComplete calls need to update data attributes so that rails_admin/custom/*.js functions can use controllerMatches() and actionMatches() confidently
$(document).ajaxComplete( function() {
  setBodyDataTags();
  confirmationOnDestroy();
});

$(document).ready( function() {
  confirmationOnDestroy();
});
