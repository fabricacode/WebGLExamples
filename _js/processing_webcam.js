// create video DOM object
var video = document.createElement("video");
video.width = 320;
video.height = 240;
video.autoplay = true;

// grab url 
window.URL = window.URL || window.webkitURL;
navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia;
	
if(navigator.getUserMedia){
	navigator.getUserMedia({video: true}, function(stream){video.src = window.URL.createObjectURL(stream);}, videoFail);
}

function videoFail(e){
	console.log("broken", e);
}