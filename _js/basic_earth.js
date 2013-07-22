var camera, scene, renderer;	// three essentials for every WebGL project
var mesh;						// object to be rendered

var angle = 70;					// camera properties
var width = window.innerWidth;
var height = window.innerHeight;
var aspect = width / height;
var near = 1;
var far = 1000;

var radius= 100;				// planet properties
var segments = 64;
var rings = 64;

var mousePressed = false;		// mouse properties
var mouseX, mouseY;
var xvel = 0;
var yvel = 0;
var zvel = 0;
var damping = 0.95;

setup();						// create everything
draw();							// draw everything

function setup(){
	// create renderer at full browser size
	renderer = new THREE.WebGLRenderer();
	renderer.setSize(width, height);
	document.body.appendChild(renderer.domElement);
	
	// create camera
	camera = new THREE.PerspectiveCamera(angle, aspect, near, far);
	camera.position.z = 200;
	
	// create scene
	scene = new THREE.Scene();
	
	// create cube
	var geometry = new THREE.SphereGeometry(radius, segments, rings);
	
	// load texture
	var texture = THREE.ImageUtils.loadTexture("_images/world_topo_4096.jpg");
	texture.anisotropy = renderer.getMaxAnisotropy();
	
	// apply texture to material
	var material = new THREE.MeshBasicMaterial({map: texture});
	
	// apply material to mesh using cube geometry and add to scene
	mesh = new THREE.Mesh(geometry, material);
	scene.add(mesh);
	
	// add window listener for browser resizing
	window.addEventListener("resize", onWindowResize, false);
	
	// add mouse listeners to control rotation
	document.addEventListener("mousedown", onMouseDown, false);
	document.addEventListener("mouseup", onMouseUp, false);
	document.addEventListener("mousemove", onMouseMove, false);
	document.addEventListener('mousewheel', onMouseWheel, false);
}

function onMouseDown(event){
	mouseX = event.clientX;
	mouseY = event.clientY;
	mousePressed = true;
}

function onMouseUp(event){
	mousePressed = false;
}

function onMouseMove(event){
	if(mousePressed){
		var xdiff = event.clientX - mouseX;
		var ydiff = event.clientY - mouseY;
		xvel += xdiff * 0.001;
		yvel += ydiff * 0.001;
		mouseX = event.clientX;
		mouseY = event.clientY;
	}
}

function onMouseWheel(event){
	zvel += event.wheelDelta * 0.002;
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
	requestAnimationFrame(draw);
	mesh.rotation.y += xvel;
	mesh.rotation.x += yvel;
	camera.position.z += zvel;
	xvel *= damping;
	yvel *= damping;
	zvel *= damping;
	renderer.render(scene, camera);
}