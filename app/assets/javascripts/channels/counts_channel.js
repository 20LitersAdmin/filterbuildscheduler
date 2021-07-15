var pathname = window.location.pathname

if (pathname.match(/^\/\w+\/\d+\/edit/) != null) {
  var inventoryId = pathname.match(/\d+/)[0]

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
        var target = $('div.row#counts_row');
        target.html(data["html_slug"]);
        console.log('[ActionCable] target updated');
      }
    }
  );
}

