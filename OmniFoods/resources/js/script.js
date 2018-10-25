$(document).ready(function(){

  /*Sticky Nav*/
  $('.js--section-features').waypoint(function(direction){
    if (direction == "down") {
      $('nav').addClass('sticky');
    } else {
      $('nav').removeClass('sticky');
    }
  }, {
      offset: '65px;'
  });

  /*Link Scroll*/
  $('.js--scroll-to-plans').click(function(){
    $('html, body').animate({scrollTop: $('.js--section-plans').offset().top}, 1000);
  });

  $('.js--scroll-to-start').click(function(){
    $('html, body').animate({scrollTop: $('.js--section-features').offset().top}, 1000);
  });

  /*Navigation scroll*/
  $(function() {
    $('a[href*=#]:not([href=#])').click(function() {
      if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') && location.hostname == this.hostname) {
        var target = $(this.hash);
        target = target.length ? target : $('[name=' + this.hash.slice(1) +']');
        if (target.length) {
          $('html,body').animate({
            scrollTop: target.offset().top
          }, 1000);
          return false;
        }
      }
    });
  });

  /* Annimations on Scroll*/
  $('.js--wp-1').waypoint(function(direction){
    $('.js--wp-1').addClass('animated fadeIn');
  }, {
    offset: '70%'
  });

  $('.js--wp-2').waypoint(function(direction){
    $('.js--wp-2').addClass('animated fadeInUp');
  }, {
    offset: '70%'
  });

  $('.js--wp-3').waypoint(function(direction){
    $('.js--wp-3').addClass('animated fadeIn');
  }, {
    offset: '70%'
  });

  $('.js--wp-4').waypoint(function(direction){
    $('.js--wp-4').addClass('animated fadeIn');
  }, {
    offset: '70%'
  });

  /*Mobile Nav*/
  $('.js--nav-icon').click(function(){
    var nav = $('.js--main-nav');
    var icon = $('.js--nav-icon i');
    nav.slideToggle(150);
    if (icon.hasClass('ion-navicon-round')){
      icon.addClass('ion-close-round');
      icon.removeClass('ion-navicon-round')
    } else {
      icon.addClass('ion-navicon-round');
      icon.removeClass('ion-close-round')
    }
  });

  var map = new GMaps({
    div: '.map',
    lat: 38.727432,
    lng: -9.134649
  });

  map.addMarker({
    lat: 38.727432,
    lng: -9.134649,
    title: 'Lisbon',
    infoWindow: {
      content: '<p>Our Lisbon HQ</p>'
    }
  });

  map.addMarker({
    lat: 37.771907,
    lng: -122.410959,
    title: 'San Franciso',
    infoWindow: {
      content: '<p>Our San Franciso HQ</p>'
    }
  });

  map.addMarker({
    lat: 52.514642,
    lng: 13.404152,
    title: 'Berlin',
    infoWindow: {
      content: '<p>Our Berlin HQ</p>'
    }
  });

  map.addMarker({
    lat: 51.513532,
    lng: -0.109196,
    title: 'London',
    infoWindow: {
      content: '<p>Our London HQ</p>'
    }
  });

  $('.js--lisbon').click(function(){
    map.setCenter({
      lat: 38.727432,
      lng: -9.134649
    });
  });

  $('.js--sanfran').click(function(){
    map.setCenter({
      lat: 37.771907,
      lng: -122.410959
    });
  });

  $('.js--berlin').click(function(){
    map.setCenter({
      lat: 52.514642,
      lng: 13.404152
    });
  });

  $('.js--london').click(function(){
    map.setCenter({
      lat: 51.513532,
      lng: -0.109196
    });
  });

});
