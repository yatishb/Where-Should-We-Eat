function init(){
  var mapOptions = {
    center: {lat: 1.306, lng: 103.77},
    zoom: 15
  };
  var map = new google.maps.Map(
      document.getElementById('map-canvas'),
      mapOptions
    );
}
google.maps.event.addDomListener(window, 'load', init);
