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

// Same order as Inventory#edit: status (uncounted, partial, counted), then item name.
// Move the updated node only. Rebuilding the row would request every picture again.
function placeCountCard(row, card) {
  if (!card.length) return;

  var statusRank = { uncounted: 0, partial: 1, counted: 2 };

  function sortKey(el) {
    var status = statusRank[el.getAttribute('data-status')];
    var title = el.querySelector('.count-title');
    var name = title ? title.textContent.trim() : '';

    return [(status === undefined ? 0 : status), name];
  }

  function isAfter(a, b) {
    var ka = sortKey(a);
    var kb = sortKey(b);

    if (ka[0] !== kb[0]) return ka[0] > kb[0];
    return ka[1] > kb[1];
  }

  var others = row.children('.count-wrapper').not(card).get();
  var cardEl = card.get(0);
  var i;

  for (i = 0; i < others.length; i++) {
    if (isAfter(others[i], cardEl)) {
      $(others[i]).before(card);
      return;
    }
  }

  row.append(card);
}

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
        // data["html_slug"] is only the count that changed, so the other cards keep their images
        // data["uncounted"]
        var row = $('div.row#counts_row');
        var existing = $('#count_' + data["count_id"]);

        if (existing.length) {
          existing.replaceWith(data["html_slug"]);
        } else {
          row.append(data["html_slug"]);
        }

        placeCountCard(row, $('#count_' + data["count_id"]));

        var countTargets = $('.uncounted_number');
        countTargets.html(data["uncounted"]);

        console.log('[ActionCable] target updated');
      }
    }
  );
};
