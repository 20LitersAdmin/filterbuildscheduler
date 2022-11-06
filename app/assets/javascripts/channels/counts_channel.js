// =====> Hello, Interviewers!
// The scenario: Multiple users can be logged into the system at one time
// all helping to perform the same inventory.
//
// Originally, users would need to refresh the page to see the items that
// other users had counted, and conflicts could arise if two users were
// trying to count the same item at the same time.
//
// Previous to this, I wrote a Javascript poller that just pinged an
// endpoint every 5 seconds. That endpoint would return count records
// based upon their updated_at value
// then the javascript would update DOM elements for those records.
//
// It worked, but really felt like duct tape.
//
// I did struggle to wrap my head around websockets, and this was my first
// attempt. It was a great learning experience and I think this is much
// better than the Javascript ping / polling function I had written.

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
