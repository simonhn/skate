var copenhagen = new google.maps.LatLng(55.676294, 12.568116);
var bounds = new google.maps.LatLngBounds();
var currentPlace = null;
var icons = {
  'skate':          'http://cphsk8map.dk/images/skate.png',
  'skate-selected': 'http://cphsk8map.dk/images/skate-selected.png'
}
var map;

function initialize() {
   var mapOptions = {
     zoom:      13,
     center:    copenhagen,
     mapTypeId: google.maps.MapTypeId.ROADMAP,
     mapTypeControl: false,
     scaleControl: false,
     region: 'DK'
   }
   map = new google.maps.Map($("#map_canvas")[0], mapOptions);
   infowindow = new google.maps.InfoWindow({
   });   
}

    
function displayLarge(info)
{
   $.getJSON('georss.json', function(places) {
    $(places).each(function() {
      var place = this;

      var marker = new google.maps.Marker({
        position: new google.maps.LatLng(place.lat, place.long),
        map:      map,
        title:    place.title,
        icon: icons["skate"]
      });
      bounds.extend(new google.maps.LatLng(place.lat, place.long));
      map.fitBounds(bounds);
      google.maps.event.addListener(marker, 'click', function() {
        var hidingMarker = currentPlace;
        var slideIn = function(marker) {
          $('h1', info).html($('<a>').attr('href', '/spot/'+place.slug ).text(place.title));
          $('p',  info).text(place.teaser);
          info.animate({right: '0'});
        }
        marker.setIcon(icons['skate-selected']);
        if (currentPlace) {
          currentPlace.setIcon(icons['skate']);
          info.animate(
            { right: '-320px' },
            { complete: function() {
              if (hidingMarker != marker) {
                slideIn(marker);
              } else {
                currentPlace = null;
              }
            }}
          );
        } else {
          slideIn(marker);
        }
        currentPlace = marker;
      });
    });
   });
}

function displaySmall(slug,info)
{
   $.getJSON('/georss.json', function(places) {
    $(places).each(function() {
      var place = this;
      var marker = new google.maps.Marker({
        position: new google.maps.LatLng(place.lat, place.long),
        map:      map,
        title:    place.title,
        icon: icons["skate"],
        clickable: true
      });
      bounds.extend(new google.maps.LatLng(place.lat, place.long));
      map.fitBounds(bounds);
      if(place.slug === slug){
         marker.setIcon(icons['skate-selected']);
         //var latLng = marker.getPosition(); // returns LatLng object
         //map.setCenter(latLng); // setCenter takes a LatLng object         
      }

      google.maps.event.addListener(marker, 'click', function() {
         var html = '<a href='+place.slug+'>'+place.title+'</a>';
         html += '<p>'+place.teaser+'</p>';
         infowindow.setContent(html);
         infowindow.open(map, this);
         
        var hidingMarker = currentPlace;
        
        marker.setIcon(icons['skate-selected']);
        if (currentPlace) {
          currentPlace.setIcon(icons['skate']);
        } 
        currentPlace = marker;
      });
    });
   });
}
