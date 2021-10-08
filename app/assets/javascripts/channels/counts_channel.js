var pathname = window.location.pathname;

if (pathname.match(/^\/inventories\/\d+\/edit/) != null) {
  var inventoryId = pathname.match(/\d+/)[0];

  App.cable.subscriptions.create(
    {
      channel: "CountsChannel",
      inventory_id: inventoryId
    },
    {
      connected: function() {
        console.log("[ActionCable] connected");
      },

      disconnected: function() {
        console.log("[ActionCable] disconnected");
      },

      rejected: function() {
        console.log("[ActionCable] rejected");
      },

      received: function(data) {
        console.log('[ActionCable] data received');

        // data["count_id"]
        // data["html_slug"]
        // data["uncounted"]
        var slugTarget = $('div.row#counts_row');
        slugTarget.html(data["html_slug"]);

        var countTargets = $('.uncounted_number');
        countTargets.html(data["uncounted"]);

        console.log('[ActionCable] target updated');
      }
    }
  );
};

