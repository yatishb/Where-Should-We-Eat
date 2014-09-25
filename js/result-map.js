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

}
google.maps.event.addDomListener(window, 'load', init);

function ResultDisplay(input_map){

  var userMarkers = [];
  var userDetails = [];
  var placeDetails = [];
  var placeMarker = null;

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
    console.log(searchId);
    $.get('/search/' + searchId + '/people', setUserMarkers);

    //TODO Add get for places here
    $.get('/search/' + searchId + '/places', function(data){
      console.log(data);
    })
    setPlaceDetails();
  }

  this.returnMap = function(){
    return googleMap;
  }

  this.clearMap = function(){
    if(placeMarker){
      placeMarker.setMap(null);
    }
    userMarkers.map(function(val){
      val.setMap(null);
    })
    directionRenderers.map(function(val){
      val.setMap(null);
    })
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

  function setPlaceDetails(){

    var details = [
    {'name':'Burger Shack', 'lat':1.308, 'lng':103.82, 'cost':250, 'info':'Placeholder 1'},
    {'name':'Salad Bar', 'lat':1.305, 'lng':103.79, 'cost':200, 'info':'Placeholder 2'},
    {'name':'Seafood Place', 'lat':1.317, 'lng':103.76, 'cost':350, 'info':'Placeholder 3'},
    {'name':'Cheap Alcohol', 'lat':1.303, 'lng':103.81, 'cost':150, 'info':'Placeholder 4'},
    {'name':'Expensive Restaurant', 'lat':1.3, 'lng':103.78,'cost':280, 'info':'Placeholder 5'}
    ];

    placeDetails = details;
    $('#place-option-list').html('');
    for(var i=0;i<details.length;i++){
      $('#place-option-list').append(
        '<div data-role="collapsible" data-collapsed-icon="carat-d"'
        + ' data-expanded-icon="carat-u" data-iconpos="right" option-index=' + i + '>'
        + '<h2><div style="float:left">'
        + details[i].name + '</div><div style="float:right"> $'
        + details[i].cost + '</div></h2>'
        + details[i].info + '</div>'
      );
      directionsMatrix.push([]);
    }

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
    var option_details = placeDetails[index];

    var myLatLng = new google.maps.LatLng(
      option_details.lat,option_details.lng);

    if(placeMarker) {placeMarker.setMap(null)};

    placeMarker = new google.maps.Marker({
      position: myLatLng,
      title: option_details.name,
      animation: google.maps.Animation.DROP,
    });

    placeMarker.setMap(googleMap);
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

}
