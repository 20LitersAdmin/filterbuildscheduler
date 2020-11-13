$(document).on('turbolinks:load', function() {
  if (!(controllerMatches('oauth_users') && actionMatches('manual'))) {
    return;
  };

  $(document).on("click", "#oauth_user_sync_emails", function() {
    $(".sync-disabled-warning").toggle();
  });
});
