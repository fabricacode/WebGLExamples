var camera, scene, renderer;
var mesh;

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
	
	// load texture
	var texture = THREE.ImageUtils.loadTexture("_images/david.jpg");
	texture.anisotropy = renderer.getMaxAnisotropy();
	
	// apply texture to material
	var material = new THREE.MeshBasicMaterial({map: texture});
	
	// apply material to mesh using cube geometry and add to scene
	mesh = new THREE.Mesh(geometry, material);
	scene.add(mesh);
	
	// add window listener for browser resizing
	window.addEventListener("resize", onWindowResize, false);
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
	mesh.rotation.x += 0.005;
	mesh.rotation.y += 0.01;
	renderer.render(scene, camera);
}