$(document).ready(function(){

  $(document).on('pagecontainerbeforeshow', function( event, ui){
    if(($(ui.prevPage).attr('id') === 'NewConquestOne') &&
      $(ui.toPage).attr('id') === 'NewConquestTwo'){
      var statusArray = $('input[type="checkbox"]').filter('.custom').map
        (function(){
          if ($(this).is(':checked')){
            return true;
          } else {
            return false;
          }
        });
      var toSearch = $('#chosenParty').find('li').map(
        function(){
          var id = $(this).attr('skynetid');
          var friend = JSON.parse(window.localStorage.getItem('Skynet:g' + id));

          return {
            name: friend.guildName,
            postal: friend.guildPostal,
            phone: parseInt(friend.guildMobile)
          }
        }
      )

      var payload = JSON.stringify({'people':toSearch.toArray()});
      console.log(payload);
      $.post('/doSearch',
       payload,
       function(res){
         sessionStorage.searchId = res.searchId.toString();
         query.updateSearchResults(res.searchId);
       });
    } else if ($(ui.toPage).attr('id') === 'NewConquestTwo'){
      //Handled in Map init
    }
  });

})
