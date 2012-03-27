var copenhagen = new google.maps.LatLng(55.676294, 12.568116);
var bounds = new google.maps.LatLngBounds();
var currentPlace = null;
var icons = {
  'skate':          'http://cphsk8map.dk/images/skate.png',
  'skate-selected': 'http://cphsk8map.dk/images/skate-selected.png'
}
var map;

function initializeMap() {
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
   var center;
   function calculateCenter() {
     center = map.getCenter();
   }
   
   google.maps.event.addDomListener(map, 'idle', function() {
     calculateCenter();
   });
   google.maps.event.addDomListener(window, 'resize', function() {
     map.setCenter(center);
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

function displayMap(slug,info)
{
   $.getJSON('/georss.json', function(places) {
    $(places).each(function() {
      var place = this;
      var marker = new google.maps.Marker({
        position: new google.maps.LatLng(place.lat, place.long),
        map:      map,
        title:    place.title,
        // icon: icons["skate"],
        clickable: true
      });
      bounds.extend(new google.maps.LatLng(place.lat, place.long));
      map.fitBounds(bounds);
      if(place.slug === slug){
		  marker.setIcon('http://maps.google.com/mapfiles/ms/icons/blue-dot.png');
		  marker.setShadow(new google.maps.MarkerImage('http://maps.gstatic.com/mapfiles/shadow50.png', null, null, new google.maps.Point(10, 34)));
		  // var latLng = marker.getPosition(); // returns LatLng object
		  // map.setCenter(latLng); // setCenter takes a LatLng object
	  }

      google.maps.event.addListener(marker, 'click', function() {
         var html = '<a href="/spot/'+place.slug+'">'+place.title+'</a>';
         html += '<p>'+place.teaser+'</p>';
         infowindow.setContent(html);
         infowindow.open(map, this);
         
        var hidingMarker = currentPlace;
        
        // marker.setIcon(icons['skate-selected']);
        //         if (currentPlace) {
        //           currentPlace.setIcon(icons['skate']);
        //         } 
        currentPlace = marker;
      });
    });
   });
}

function fetchYoutube(tags)
{
   $.getJSON("http://gdata.youtube.com/feeds/api/videos?v=2&alt=jsonc&q=skateboard+"+tags+"&category=Sports%2Cskateboard&max-results=10&format=5&orderby=relevance&callback=?",
 function(data){
   var movies = data["data"]["items"];
   if(movies == null || movies == 0){
   }else{
     //load the trailer
     for (var i = 0; i < movies.length; i++) {
       yt_url = 'http://www.youtube.com/watch?v='+movies[i].id+'&feature=player_embedded#at=41';
       yt_embed = yt_url.replace(new RegExp("watch\\?v=", "i"), 'v/')
       //yt_url = 'http://www.youtube.com/v/' + movies[i].id + '&amp;fs=1&feature=player_embedded';
       yt_img_url = movies[i].thumbnail.hqDefault;
       $('<a href="' +yt_url+'" rel="vidbox" class="gallerypic"><img alt="jat" width="156" height="118" class="spot" src="'+yt_img_url+'"></img><span class="zoom-icon-yt"><img src="/images/yt_icon.png" alt="Zoom" width="36" height="25" /></span></a>').fancybox({
     			'padding'		: 0,
           'width'		: 680,
     			'height'		: 495,
     			'href'			: yt_embed,
     			'type'			: 'swf',
     			'swf'			: {
     			  'wmode'		: 'transparent',
     				'allowfullscreen'	: 'true'
     			}
     		}).appendTo("#foto");
     }
   }
 }
 );

}

function fetchFlickr(tags)
{
   $.getJSON("http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=f65cddc72218d6629231015dbba534ab&tags="+tags+",skateboard&tag_mode=all&format=json&sort=interestingness-desc&jsoncallback=?",
    function(data){
      $.each(data.photos.photo, function(i,item){
        var url_s = "http://farm"+item.farm+".static.flickr.com/"+item.server+"/"+item.id+"_"+item.secret+"_s.jpg";
        var url_m = "http://farm"+item.farm+".static.flickr.com/"+item.server+"/"+item.id+"_"+item.secret+"_m.jpg";
        var url = "http://farm"+item.farm+".static.flickr.com/"+item.server+"/"+item.id+"_"+item.secret+".jpg";
        var url_b = "http://farm"+item.farm+".static.flickr.com/"+item.server+"/"+item.id+"_"+item.secret+"_b.jpg";
        $('<a href="' +url_b+'" rel="hat" class="gallerypic"><img alt="jat" width="156" height="118" class="spot" src="'+url_m+'"></img><span class="zoom-icon"><img src="/images/FlickrSmall.png" alt="Zoom" width="156" height="118" /></span></a>').fancybox().appendTo("#foto");
      
      });

      $('<div class="downarrowdiv contribute"><h3>Contribute</h3><p>If you have any content online for this spot you can make it available for this site. The "live feed" section of this site is fetched off the web. All you need to do is tag your content with "skateboard" and the following keyword: "'+tags+'"</p></div>').appendTo("#foto");
    }
  );
}

function fetchFlickrThumbs(tags)
{
   $.getJSON("http://api.flickr.com/services/rest/?method=flickr.groups.pools.getPhotos&api_key=f65cddc72218d6629231015dbba534ab&group_id=1695312%40N23&tags="+tags+"&extras=tags&format=json&jsoncallback=?",
       function(data) {         
         $.each(data.photos.photo, function(i,item){
           var url_s = "http://farm"+item.farm+".static.flickr.com/"+item.server+"/"+item.id+"_"+item.secret+"_s.jpg";
           var url_m = "http://farm"+item.farm+".static.flickr.com/"+item.server+"/"+item.id+"_"+item.secret+"_m.jpg";
           var url = "http://farm"+item.farm+".static.flickr.com/"+item.server+"/"+item.id+"_"+item.secret+".jpg";
           var url_b = "http://farm"+item.farm+".static.flickr.com/"+item.server+"/"+item.id+"_"+item.secret+"_b.jpg";
           var substr = item.tags.split(' ');
           $.each(substr, function(j, item){
			 if(item=='main'){
				 $(".portrait").attr({ src: url });
			 }
             if(item == 'spotadmin' || item == 'SpotAdmin'){
				 $('<a href="'+url_b+'" rel="kat" class="gallerypic"><img alt="jat" height="50px" width="50px" class="spot" src="'+url_m+'"></img></a>').fancybox().appendTo(".image_thumb");	
			 }
           });           
         });         
       });
}