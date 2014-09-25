$(document).ready(function(){

  $(document).on('pagecontainerbeforeshow', function( event, ui){
    if(($(ui.prevPage).attr('id') === 'NewConquestTwo') &&
      $(ui.toPage).attr('id') === 'ConquestDetailsCreate'){
        var placeDetails = query.resultDisplay.getActivePlace();
        if(placeDetails.placeImgurl !== 'No image'){
          $('#ConquestDetailsCreate')
          .find('img')
          .attr('src',placeDetails.placeImgurl)
        }
        $('#ConquestDetailsCreate').find('h2').html(placeDetails.placeName);

        $('#ConquestDetailsCreate').find('li').find('p')
        .html('Placeholder text');

        $('#ConquestDetailsCreate').find('li').find('a')
        .attr('href', 'http://m.yelp.com.sg/biz/' + placeDetails.placeYelpid);
    }
  });

})
