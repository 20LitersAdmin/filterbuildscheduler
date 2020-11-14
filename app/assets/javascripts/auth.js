$(document).on('turbolinks:load', function() {
  if (!(controllerMatches('oauth_users') && actionMatches('manual'))) {
    return;
  };
});
