$(document).on("turbolinks:load", function(){
  $('.datetimepicker').each(function(){
    var theValue = Date(this.value);
    $(this).datetimepicker({
      date: this.value,
      format: 'MMM DD YYYY HH:mm A'
    });
    
  });
});
