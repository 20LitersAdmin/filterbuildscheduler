function isRailsAdminPage() {
  return $('body').hasClass('rails_admin');
};

function controllerMatches(controllers_ary) {
  var controller = $('body').data('controller');
  return controllers_ary.indexOf(controller) !== -1;
};

function actionMatches(actions_ary) {
  var action = $('body').data('action');
  return actions_ary.indexOf(action) !== -1;
};
