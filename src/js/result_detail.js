$(document).ready(function(){

  $(document).on('pagecontainerbeforeshow', function( event, ui){
    if(($(ui.prevPage).attr('id') === 'NewConquestTwo') &&
      $(ui.toPage).attr('id') === 'ConquestDetailsCreate'){
        var placeDetails = query.resultDisplay.getActivePlace();
        var currentSearch = query.resultDisplay.getCurrentSearch();
        if(!placeDetails){
          return;
        }
        sessionStorage.searchId = '' + currentSearch;
        sessionStorage.chosenPlace = JSON.stringify(placeDetails);
        createPopulateData(placeDetails, currentSearch)
    } else if (ui.toPage.attr('id') === 'ConquestDetailsCreate'){
      if (sessionStorage.searchId != null && sessionStorage.chosenPlace != null){
        createPopulateData(JSON.parse(sessionStorage.chosenPlace),
          sessionStorage.searchId);
      } else if (sessionStorage.searchId != null) {
        $('body').pagecontainer('change','#NewConquestTwo');
      } else {
        $('body').pagecontainer('change','#NewConquestOne');
      }
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
    console.log('Here');
  });


  function createPopulateData(placeDetails, searchId){
    if(placeDetails.placeImgurl !== 'No image'){
      $('#ConquestDetailsCreate')
      .find('img')
      .attr('src',placeDetails.placeImgurl)
    }
    $('#ConquestDetailsCreate').find('h2').html(placeDetails.placeName);

    $('#ConquestDetailsCreate').find('iframe')
    .attr('src', 'http://m.yelp.com.sg/biz/' + placeDetails.placeYelpid);

    $('#create-datetime').text(new Date().toLocaleDateString());

    $.get('/search/'
      + searchId + '/'
      + placeDetails.placeYelpid + '/distance',
      createPopulatePartyCost);
  }

  function createPopulatePartyCost(response){
    query.partyCost = response.distances;
    console.log(response);
    $('#create-party-cost-list').html('');
    for(var i=0;i<response.distances.length;i++){
      $('#create-party-cost-list').append(
        '<li><div style="float:left">'
        + response.distances[i].name + '</div>'
        + '<div style="float:right">$'
        + calculateTaxiFare(response.distances[i].distance).toFixed(2)
        + '</div></li>'
      );
    }
    $('#create-party-cost-list').listview('refresh');
  }


  $( document ).on( "pageinit", function() {

    $( "#create-popupYelp iframe" )
        .attr( "width", 0 )
        .attr( "height", 0 );

    $( "#create-popupYelp" ).on({
        popupbeforeposition: function() {
            var size = scale( 497, 795, 15, 1 ),
                w = size.width,
                h = size.height;

            $( "#create-popupYelp iframe" )
                .attr( "width", w )
                .attr( "height", h );
        },
        popupafterclose: function() {
            $( "#create-popupYelp iframe" )
                .attr( "width", 0 )
                .attr( "height", 0 );
        }
    });

    $( "#details-popupYelp iframe" )
        .attr( "width", 0 )
        .attr( "height", 0 );

    $( "#details-popupYelp" ).on({
        popupbeforeposition: function() {
            var size = scale( 497, 795, 15, 1 ),
                w = size.width,
                h = size.height;

            $( "#details-popupYelp iframe" )
                .attr( "width", w )
                .attr( "height", h );
        },
        popupafterclose: function() {
            $( "#details-popupYelp iframe" )
                .attr( "width", 0 )
                .attr( "height", 0 );
        }
    });

  });

  function scale( width, height, padding, border ) {
    var scrWidth = $( window ).width() - 30,
        scrHeight = $( window ).height() - 30,
        ifrPadding = 2 * padding,
        ifrBorder = 2 * border,
        ifrWidth = width + ifrPadding + ifrBorder,
        ifrHeight = height + ifrPadding + ifrBorder,
        h, w;
    if ( ifrWidth < scrWidth && ifrHeight < scrHeight ) {
        w = ifrWidth;
        h = ifrHeight;
    } else if ( ( ifrWidth / scrWidth ) > ( ifrHeight / scrHeight ) ) {
        w = scrWidth;
        h = ( scrWidth / ifrWidth ) * ifrHeight;
    } else {
        h = scrHeight;
        w = ( scrHeight / ifrHeight ) * ifrWidth;
    }

    return {
        'width': w - ( ifrPadding + ifrBorder ),
        'height': h - ( ifrPadding + ifrBorder )
    };
  };

})
