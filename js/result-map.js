function init(){
  var mapOptions = {
    center: {lat: 1.306, lng: 103.77},
    zoom: 12
  };
  var map = new google.maps.Map(
      document.getElementById('map-canvas'),
      mapOptions
    );
  var resultDisplay = new ResultDisplay(map);
  query.resultDisplay = resultDisplay;
  if(sessionStorage.searchId != null){
    query.resultDisplay.updateSearchResults(parseInt(sessionStorage.searchId));
  }
}
google.maps.event.addDomListener(window, 'load', init);

function ResultDisplay(input_map){

  var userMarkers = [];
  var userDetails = [];
  var placeDetails = [];
  var placeMarker = null;
  var activePlaceIndex;
  var currSearchId;

  var googleMap = input_map;

  var directionsMatrix = [];
  var directionRenderers = [];
  var directionsService = new google.maps.DirectionsService();

  var userPinColor = "250BFF";
  var polylineColors = [
    '#00FF00',
    '#0000FF',
    '#FFFF00',
    '#FF00FF',
    '#00FFFF',
    '#FF0080',
    '#FF8040',
    '#804000',
    '#008080',
    '#800000',
    '#800080',
    '#8080FF'
  ];
  var userPinImage = new google.maps.MarkerImage("http://chart.apis.google.com/"
  + "chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + userPinColor,
      new google.maps.Size(21, 34),
      new google.maps.Point(0,0),
      new google.maps.Point(10, 34));
  var timeoutTime = 200;
  var polylineIndex = 0;

  setResizeHandler();

  this.updateSearchResults = function(searchId){
    console.log('Search id ' + searchId);
    currSearchId = searchId;
    $.get('/search/' + searchId + '/people', setUserMarkers);
    $.get('/search/' + searchId + '/places', setPlaceDetails);
  }

  this.returnMap = function(){
    return googleMap;
  }

  this.clearMap = function(){
    console.log('Clearing');
    if(placeMarker){
      placeMarker.setMap(null);
      activePlaceIndex = null;
    }
    userMarkers.map(function(val){
      val.setMap(null);
    })
    directionRenderers.map(function(val){
      val.setMap(null);
    })
  }

  this.getActivePlace = function(){
    return placeDetails[activePlaceIndex];
  }

  this.getCurrentSearch = function(){
    return currSearchId;
  }

  function optionClickHandler(index){

    setPlaceMarker(index);
    setBounds();
    clearDirectionRenderers();

    if(directionsMatrix[index].length === 0){
      directionQueryLoop(0, index);
    } else {
      setExistingDirectionRenderers(index);
    }

  }


  function generatePolyline(){
    return new google.maps.Polyline({
        strokeColor: polylineColors[polylineIndex++],
        strokeOpacity: 0.7,
        strokeWeight: 5
    });
  }

  function setUserMarkers(data){
    console.log(data);
    userMarkers = data.people.map(function(val){
      return new google.maps.Marker({
        position: new google.maps.LatLng(
          val.personLocation.lat,
          val.personLocation.lng
        ),
        icon: userPinImage,
        map: googleMap
      })
    })
    userDetails = data.people;
    setBounds();
  }

  function setPlaceDetails(data){

    placeDetails = data.places;
    $('#place-option-list').html('');
    for(var i=0;i<placeDetails.length;i++){
      $('#place-option-list').append(
        '<div data-role="collapsible" data-collapsed-icon="carat-d"'
        + ' data-expanded-icon="carat-u"'
        + ' data-iconpos="right" option-index=' + i + '>'
        + '<h2><div style="float:left">'
        + placeDetails[i].placeName + '</div><div style="float:right"> $'
        + '?</div></h2>'
        + '<span class="option-info">Placeholder</span>' + '</div>'
      );
      directionsMatrix.push([]);

    }

    console.log('setPlaceDetails')
    placeDetails.map(populateCost);

    $('#place-option-list').collapsibleset('refresh');

    $('#place-option-list h2').click(function(){
      var index = parseInt($(this)
        .closest('.ui-collapsible')
        .attr('option-index'));
      optionClickHandler(index);
    });

  }

  function setResizeHandler(){
    $(document).on('pagecontainershow', function(event, ui){
      var pageId = $('body').pagecontainer('getActivePage').prop('id');
      if (pageId === 'NewConquestTwo'){
        var center = googleMap.getCenter();
        google.maps.event.trigger(googleMap, "resize");
        googleMap.setCenter(center);
      }
    });
  }

  function setPlaceMarker(index){
    var place_location = placeDetails[index].placeLocation;

    var myLatLng = new google.maps.LatLng(
      place_location.lat,place_location.lng);

    if(placeMarker) {placeMarker.setMap(null)};

    placeMarker = new google.maps.Marker({
      position: myLatLng,
      title: place_location.name,
      animation: google.maps.Animation.DROP,
    });

    placeMarker.setMap(googleMap);
    activePlaceIndex = index;
  }

  function setBounds(){
    var bound = new google.maps.LatLngBounds();

    for (var i=0; i<userMarkers.length; i++){
      bound.extend(userMarkers[i].position);
    }

    if(placeMarker){bound.extend(placeMarker.position);}

    googleMap.setCenter(bound.getCenter());
    googleMap.fitBounds(bound);
  }

  function clearDirectionRenderers(){
    directionRenderers.forEach(function(val){
      val.setMap(null);
    })
    directionRenderers.length = 0;
    polylineIndex = 0;
  }

  function setNewDirectionRenderer(response, index){
    var directionRenderer = new google.maps.DirectionsRenderer({
      suppressMarkers: true,
      polylineOptions: generatePolyline(),
      preserveViewport: true
    });
    directionRenderer.setDirections(response);
    directionsMatrix[index].push(directionRenderer);
    directionRenderer.setMap(googleMap);
    directionRenderers.push(directionRenderer);
  }

  function setExistingDirectionRenderers(index){
    for(var i=0; i<directionsMatrix[index].length; i++){
      directionsMatrix[index][i].setMap(googleMap);
      directionRenderers.push(directionsMatrix[index][i]);
    }
  }

  //Sends direction query from each user position
  //with a time out time to avoid triggering query failure
  //due to Google rate limits
  function directionQueryLoop(i, index){
    setTimeout(function() {
      var request = {
        origin: placeMarker.position,
        destination: userMarkers[i].position,
        travelMode: google.maps.TravelMode.DRIVING
      }
      directionsService.route(request, function(response, status){
        if (status === google.maps.DirectionsStatus.OK) {
          setNewDirectionRenderer(response, index);
        } else {
          //Over query limit error to be handled.
        }
      });
      if(++i<userMarkers.length){
        directionQueryLoop(i, index);
      }
    }, timeoutTime);
  }

  function populateCost(detail, index){
    $.get('/search/' + currSearchId + '/' + detail.placeYelpid + '/distance',
    function(response){
      var distanceArray = response.distances.map(function(val){
        return val.distance;
      });
      var costArray = distanceArray.map(calculateTaxiFare);
      var sum = costArray.reduce(function(pv,cv){return pv + cv;},0.00);
      var max = costArray.reduce(function(pv,cv){return Math.max(pv,cv);},0.00);
      $('#place-option-list').find('[option-index =' + index + ']')
      .find('[style="float:right"]').html('$' + sum.toFixed(2));
      $('#place-option-list').find('[option-index =' + index + ']')
      .find('.option-info')
      .html('Maximum individual taxi fare estimate is $' + max.toFixed(2));
    })
  }

}

function calculateTaxiFare(dist){
  var cost;
  if(dist<0){
    return 0.00;
  }else if(dist<1000){
    return 3.00;
  }else if(dist<11000){
    cost = 3.00;
    cost += 0.22*(Math.ceil((dist-1000)/400));
    return cost;
  }else{
    cost = 8.50;
    cost += 0.22*(Math.ceil((dist-11000)/350));
    return cost;
  }
}
