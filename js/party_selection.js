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
      var toSearch = friends.filter(function(val, index){
        return statusArray[index];
      }).map(function(val, index){
        return {
          name: val.name,
          postal: val.postalCode,
          phone: val.phone,
        }
      });
      var payload = JSON.stringify({'people':toSearch});
      console.log(payload);
      $.post('/doSearch',
      payload,
      function(res){
        updateSearchResults(res.searchId);
      });
    };
  });

  //Use Get from localStorage to fill here

  var friends = [
    {name:"Warrior", phone:10011, postalCode:'408600', loc: {lat: 1.3055, lng: 103.80}},
    {name:"Wizard", phone:20022, postalCode:'138595', loc: {lat: 1.3085, lng: 103.77}},
    {name:"Cleric", phone:30033, postalCode:'088278', loc: {lat: 1.3065, lng: 103.79}},
    {name:"Ranger", phone:40044, postalCode:'129770', loc: {lat: 1.3075, lng: 103.78}},
  ]

  for(var i=0;i<friends.length;i++){
    $('#chosenParty > fieldset').append(
      '<input type="checkbox" name="checkbox-' + i
      + '" id="checkbox-' + i + '" class="custom" />'
      + '<label for="checkbox-' + i + '">' + friends[i].name + '</label>'
    )
  }


})
