var camera, scene, renderer;
var mesh;
var video;
var texture;

var angle = 70;
var width = window.innerWidth;
var height = window.innerHeight;
var aspect = width/height;
var near = 1;
var far = 1000;

setup();
draw();

function setup(){
	// create renderer at full browser size
	renderer = new THREE.WebGLRenderer();
	renderer.setSize(width, height);
	document.body.appendChild(renderer.domElement);
	
	// create camera
	camera = new THREE.PerspectiveCamera(angle, aspect, near, far);
	camera.position.z = 400;
	
	// create scene
	scene = new THREE.Scene();
	
	// create cube
	var geometry = new THREE.CubeGeometry(200, 200, 200);
	
	// create video DOM object
	video = document.createElement("video");
	video.width = 640;
	video.height = 320;
	video.autoplay = true;
	
	// grab url 
	window.URL = window.URL || window.webkitURL;
	navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia;
		
	if(navigator.getUserMedia){
		navigator.getUserMedia({video: true}, function(stream){video.src = window.URL.createObjectURL(stream);}, videoFail);
	}
	
	// load texture
	texture = new THREE.Texture(video);
	
	// apply texture to material
	var material = new THREE.MeshBasicMaterial({map: texture});
	
	// apply material to mesh using cube geometry and add to scene
	mesh = new THREE.Mesh(geometry, material);
	scene.add(mesh);
	
	// add window listener for browser resizing
	window.addEventListener("resize", onWindowResize, false);
}

function videoFail(e){
	console.log("broken", e);
}

function onWindowResize(){
	width = window.innerWidth;
	height = window.innerHeight;
	aspect = width / height;
	camera.aspect = aspect;
	camera.updateProjectionMatrix();
	
	renderer.setSize(width, height);
}

function draw(){
	if(video.readyState === video.HAVE_ENOUGH_DATA){
		texture.needsUpdate = true;
	}
	requestAnimationFrame(draw);
	mesh.rotation.x += 0.005;
	mesh.rotation.y += 0.01;
	renderer.render(scene, camera);
}