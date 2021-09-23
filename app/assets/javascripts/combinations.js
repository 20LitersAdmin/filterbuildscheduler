$(document).on('turbolinks:load', function() {
  if(!(controllerMatches(['combinations']))) {
    return;
  };

  // Combination/edit: item search AJAX lookup
  $(document).on('change', '#assembly_item_search', function() {
    var searchString = $(this).val();
    $.ajax({
      type: 'post',
      url: '/combinations/item_search',
      data: { search: { terms: searchString } },
      success: function(response) {
        console.log(response);
        // throw the response array into select#asembly_item_id
        // as options
      },
      error: function(response) { console.log(response); }
    });
  });

});
