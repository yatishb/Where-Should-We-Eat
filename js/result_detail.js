$(document).ready(function(){

  $(document).on('pagecontainerbeforeshow', function( event, ui){
    if(($(ui.prevPage).attr('id') === 'NewConquestTwo') &&
      $(ui.toPage).attr('id') === 'ConquestDetailsCreate'){

        var placeDetails = query.resultDisplay.getActivePlace();
        if(!placeDetails){
          return;
        }
        if(placeDetails.placeImgurl !== 'No image'){
          $('#ConquestDetailsCreate')
          .find('img')
          .attr('src',placeDetails.placeImgurl)
        }
        $('#ConquestDetailsCreate').find('h2').html(placeDetails.placeName);

        $('#ConquestDetailsCreate').find('li').find('a')
        .attr('href', 'http://m.yelp.com.sg/biz/' + placeDetails.placeYelpid);

        $.get('/search/'
          + query.resultDisplay.getCurrentSearch() + '/'
          + placeDetails.placeYelpid + '/distance',
          populatePartyCost);

    }
  });

  $(document).on('pagecontainerbeforechange', function( event, ui){
    if(typeof ui.toPage == 'object'){
      if(($(ui.prevPage).attr('id') === 'NewConquestTwo') &&
        $(ui.toPage).attr('id') === 'ConquestDetailsCreate'){
          var placeDetails = query.resultDisplay.getActivePlace();
          if(placeDetails == null && typeof ui.toPage == 'object'){
            ui.toPage[0] = $(ui.prevPage)[0];
            //Not working - too unimportant to fix now
            //$('#popupDialog').find('div').text('Please pick a place!');
            //$('#popupDialog').popup();
            alert('Please pick a place before progressing!');
            return;
          }
      }
    }
  });

  $('#conquest-confirm').click(function(){
    $.post('/chosen/'
    + query.resultDisplay.getCurrentSearch() + '/',
    JSON.stringify({'yelpid':query.resultDisplay.getActivePlace().placeYelpid}));
  });

  function populatePartyCost(response){

    $('#party-cost-list').html('');
    for(var i=0;i<response.distances.length;i++){
      $('#party-cost-list').append(
        '<li><div style="float:left">'
        + response.distances[i].name + '</div>'
        + '<div style="float:right">$'
        + calculateTaxiFare(response.distances[i].distance).toFixed(2)
        + '</div></li>'
      );
    }
    $('#party-cost-list').listview('refresh');
  }

})
