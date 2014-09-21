var map, place_marker;
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

var polylineIndex = 0;

function init(){
  var mapOptions = {
    center: {lat: 1.306, lng: 103.77},
    zoom: 12
  };
  map = new google.maps.Map(
      document.getElementById('map-canvas'),
      mapOptions
    );
  onMapLoad();
}
google.maps.event.addDomListener(window, 'load', init);


var details = [
{'name':'Burger Shack', 'lat':1.308, 'lng':103.82},
{'name':'Salad Bar', 'lat':1.305, 'lng':103.79},
{'name':'Seafood Place', 'lat':1.317, 'lng':103.76},
{'name':'Cheap Alcohol', 'lat':1.303, 'lng':103.81},
{'name':'Expensive Restaurant', 'lat':1.3, 'lng':103.78}
];

var users = [
  {'lat':1.3055, 'lng':103.80},
  {'lat':1.3085, 'lng':103.77},
  {'lat':1.3065, 'lng':103.79},
  {'lat':1.3075, 'lng':103.78}
]


function onMapLoad(){

  var user_markers = [];
  var directionsMatrix = []


  $(document).ready(function(){

    var direction_renderers = [];

    //Inside a get to the server to get details or just names
    for(var i=0;i<details.length;i++){
      $('#option-list').append(
        '<li option-index=' + i + '><a href="#">'
        + details[i].name + '</a></li>'
      );
      directionsMatrix.push([]);
    }
    $('#option-list').listview('refresh');

    //Inside a get request to get lat+lng of users
    var userPinImage = new google.maps.MarkerImage("http://chart.apis.google.com/"
    + "chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + userPinColor,
        new google.maps.Size(21, 34),
        new google.maps.Point(0,0),
        new google.maps.Point(10, 34));

    for(var i=0;i<users.length;i++){
      var latLng = new google.maps.LatLng(
        users[i].lat, users[i].lng
      )

      user_markers.push(new google.maps.Marker({
        position: latLng,
        icon: userPinImage,
        map: map
      }));

    }


    function generatePolyline(){
      return new google.maps.Polyline({
          strokeColor: polylineColors[polylineIndex++],
          strokeOpacity: 0.7,
          strokeWeight: 5
      });
    }



    //Need to optimise soon!

    $('#option-list li').click(function(){
      var index = parseInt($(this).attr('option-index'));


      var option_details = details[index]; //Replace with API get

      var myLatLng = new google.maps.LatLng(
        option_details.lat,option_details.lng);

      if(place_marker) {place_marker.setMap(null)};

      place_marker = new google.maps.Marker({
        position: myLatLng,
        title: option_details.name,
        animation: google.maps.Animation.DROP,
      });

      place_marker.setMap(map);

      var bound = new google.maps.LatLngBounds();

      for (var i=0; i<user_markers.length; i++){
        bound.extend(user_markers[i].position);
      }

      bound.extend(place_marker.position);

      map.setCenter(bound.getCenter());
      map.fitBounds(bound);

      polylineIndex = 0;
      for(var i=0;i<direction_renderers.length;i++){
        direction_renderers[i].setMap(null);
      }
      direction_renderers = [];


      if(directionsMatrix[index].length === 0){
        var i = 0;

        function syncLoop(){

          setTimeout(function() {
            var request = {
              origin: place_marker.position,
              destination: user_markers[i].position,
              travelMode: google.maps.TravelMode.DRIVING
            }
            directionsService.route(request, function(response, status){
              if (status === google.maps.DirectionsStatus.OK) {
                var directionRenderer = new google.maps.DirectionsRenderer({
                  suppressMarkers: true,
                  polylineOptions: generatePolyline(),
                  preserveViewport: true
                });
                directionRenderer.setDirections(response);
                directionsMatrix[index].push(directionRenderer);
                directionRenderer.setMap(map);
                direction_renderers.push(directionRenderer);

              } else {
                //Over query limit error to be handled.
              }
            });

            i++;
            if(i<user_markers.length){
              syncLoop();
            }

          }, 200);
        }

        syncLoop();

      } else {
          for(var i=0; i<directionsMatrix[index].length; i++){
            directionsMatrix[index][i].setMap(map);
            direction_renderers.push(directionsMatrix[index][i]);
          }
      }

    });

  });

}
