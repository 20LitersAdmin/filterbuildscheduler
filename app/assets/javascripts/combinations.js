$(document).on('turbolinks:load', function() {
  if(!(controllerMatches(['combinations']))) {
    return;
  };

  // Combination/edit: item search AJAX lookup
  $(document).on('change', '#assembly_item_search', function() {
    var searchString = $(this).val();
    console.log(searchString);
    // $.ajax({
    //   type: 'Post',
    //   url: '/combinations/item_search',
    //   data: { search: { terms: searchString } },
    //   success: function(response) {
    //     // update some dob object that can be selected
    //     console.log(response);
    //   },
    //   error: function(response) { console.log(response); }
    // });
  });

});
