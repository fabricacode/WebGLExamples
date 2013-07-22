var ctx;
PImage img;

void setup(){
	size(640,480);
	frameRate(30);
	ctx = externals.context;
}

void draw(){
	pushMatrix();
	translate(width,0);
	scale(-1,1);
	ctx.drawImage(video, 0, 0, width, height);
	img = get();
	popMatrix();
}