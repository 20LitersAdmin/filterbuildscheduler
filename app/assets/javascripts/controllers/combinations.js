$(document).on('turbolinks:load', function() {
  if(!(controllerMatches(['combinations']))) {
    return;
  };

  // =====> Hello, Interviewers!
  // This is the custom item search field on Assemblies#new
  //
  // Take the inputs of the item_search field and use it to create a
  // collection of matching Component and Part records that the user can
  // use to set the item (child) half of the Assembly join table.
  // the JSON return records are inserted as options to the :item_id
  // select field.
  //
  // CombinationsController#edit: item search via AJAX lookup
  $(document).on('change', '#assembly_item_search', function() {
    var searchString = $(this).val();
    var itemSelect = $('select#assembly_item_id');
    var itemSelectLabel = $('label[for="assembly_item_id"]')
    var itemType = $('input#assembly_item_type');
    var ajaxSpinner = $('div#spinner_div');
    var searchResponseDiv = $('div#item_search_response');
    var combinationUid = $('#new_asssembly_form').attr('data-uid');

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
      data: { search: { terms: searchString, uid: combinationUid } },
      success: function(response) {
        ajaxSpinner.hide();

        if (response.length != 0 && response[0] != undefined) {
          console.log(response);
          var itemLang = ((response.length > 1) ? 'items' : 'item');

          searchResponseDiv.html(
            `Found ${response.length} ${itemLang} that match "${searchString}".`
          );
          searchResponseDiv.show();

          // BUG: sometimes the select is populated with duplicates
          // trying to ensure it starts empty
          itemSelect.html('<option value=""></option>');

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
        // Controller returns :unprocessable_entity on empty strings
        ajaxSpinner.hide();
        if (response["responseText"]) {
          console.log(response["responseText"]);
        } else {
          console.log('Unknown error.');
          console.log(response);
        }
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
