$(document).on('turbolinks:load', function() {
  if(!(controllerMatches(['combinations']))) {
    return;
  };

  // CombinationsController#edit: item search via AJAX lookup
  $(document).on('change', '#assembly_item_search', function() {
    var searchString = $(this).val();
    var itemSelect = $('select#assembly_item_id');
    var itemSelectLabel = $('label[for="assembly_item_id"]')
    var itemType = $('input#assembly_item_type');
    var ajaxSpinner = $('div#spinner_div');
    var searchResponseDiv = $('div#item_search_response');

    // start fresh everytime to avoid duplicate options and clutter
    itemSelect.html('<option value=""></option>');
    itemSelect.hide();
    itemSelectLabel.hide();
    itemType.val('');
    searchResponseDiv.html('');
    searchResponseDiv.hide();

    console.log(`Searching for ${searchString}`);
    ajaxSpinner.show();

    $.ajax({
      type: 'post',
      url: '/combinations/item_search',
      data: { search: { terms: searchString } },
      success: function(response) {
        ajaxSpinner.hide();

        if (response.length != 0) {
          searchResponseDiv.html(
            `Found ${response.length} items that match "${searchString}".`
          );
          searchResponseDiv.show();

          $(response).each(function(i, item) {
            // throw the response array into select#asembly_item_id as options
            var [id, uid, name] = item;
            itemSelect.append(
              `<option value="${id}" data-uid="${uid}">${uid}: ${name}</option>`
            );
          });
          itemSelect.show();
          itemSelectLabel.show();
        } else {
          searchResponseDiv.html(
            `Found no items when searching "${searchString}".`
          );
          searchResponseDiv.show();
        };
      },
      error: function(response) {
        ajaxSpinner.hide();

        console.log(response);
      }
    });
  });

  $(document).on('change', 'select#assembly_item_id', function() {
    var uid = $(this).find(':selected').attr('data-uid');
    var itemType = $('input#assembly_item_type');

    if (uid == undefined) {
      itemType.val('');
    } else {
      if (uid[0] == 'C') {
        itemType.val('Component');
      };
      if (uid[0] == 'P') {
        itemType.val('Part');
      };
    };
  });
});
