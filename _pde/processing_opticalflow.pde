var ctx;
PImage img;
OpticalFlowField opticalFlowField;
int gridWidth;
int spacing, halfspacing;
float force = 30;
int resolution = 10;

void setup(){
	size(640,480);
	frameRate(30);
	ctx = externals.context;
	
	opticalFlowField = new OpticalFlowField(video.width, video.height, resolution);
	gridWidth = opticalFlowField.getGridWidth();
	spacing = width / gridWidth;
	halfspacing = spacing / 2;
}

void draw(){
	ctx.drawImage(video, 0, 0, width, height);
	img = get();
	fill(0,196);
	rect(0,0,width,height);
	
	opticalFlowField.update(img);
	drawFlowField();
}

public void drawFlowField(){
  float u,v,a,r,g,b;
  float xpos,ypos;
  
  flowField = opticalFlowField.getFlowField();
  for(int i=0; i < flowField.length; i++){
    u = flowField[i][0] * force;
    v = flowField[i][1] * force;
    a = sqrt(u*u + v*v);
    r = 0.5f * (1 + u / (a + 0.1f));
    g = 0.5f * (1 + v / (a + 0.1f));
    b = 0.5f * (2 - (r + g));
    stroke(255 * r, 255 * g, 255 * b);
    ypos = int(i / gridWidth) * spacing + halfspacing;
    xpos = (i % gridWidth) * spacing + halfspacing;
    line(xpos, ypos, xpos + u, ypos + v);
  }
}





class OpticalFlowField {
  
  // grid parameters
  private int width;        // image width
  private int height;        // image height
  private int gs;          // grid step (resolution)
  private int as;          // window size for averaging
  private int gw;          // grid width
  private int gh;          // grid height
  private int gs2;        // half grid step
  
  // regression vectors
  private float[] fx, fy, ft;
  private int fm = 27;      // length of vectors
  private float fc = 100000000;  // regularization term for regression
  private float wflow = 0.1f;    // smoothing
  
  // optical flow variables
  private float ar, ag, ab;    // used as return values from pixel averaging
  private float[] dtr, dtg, dtb;  // differentiation by time (red, green, blue)
  private float[] dxr, dxg, dxb;  // differentiation by x (red, green, blue)
  private float[] dyr, dyg, dyb;  // differentiation by y (red, green, blue)
  private float[] par, pag, pab;  // averaged grid values (red, green, blue)
  private float[] flowx, flowy;  // computed optical flow
  private float[] sflowx, sflowy;  // slowly changing version of the flow
  private float[][] flowField;  // 2D array of sflowx/sflowy values
  private int[] imgLine;      // stores pixels for mirroring
  
  // toggles
  private boolean flagMirror;    // mirror image or not

  public OpticalFlowField(final int width, final int height, final int resolution){
    this.width = width;
    this.height = height;
    this.gs = resolution;
    init();
  }
  
  private void init(){
    as = gs * 2;
    gw = width / gs;
    gh = height / gs;
    gs2 = gs / 2;
    flagMirror = false;
    imgLine = new int[width];
    
    par = new float[gw * gh];
    pag = new float[gw * gh];
    pab = new float[gw * gh];
    dtr = new float[gw * gh];
    dtg = new float[gw * gh];
    dtb = new float[gw * gh];
    dxr = new float[gw * gh];
    dxg = new float[gw * gh];
    dxb = new float[gw * gh];
    dyr = new float[gw * gh];
    dyg = new float[gw * gh];
    dyb = new float[gw * gh];
    flowx = new float[gw * gh];
    flowy = new float[gw * gh];
    sflowx = new float[gw * gh];
    sflowy = new float[gw * gh];
    flowField = new float[gw * gh][2];
    fx = new float[fm];
    fy = new float[fm];
    ft = new float[fm];
  }
  
  private void averagePixels(PImage img, int x1, int y1, int x2, int y2){
    float sumr = 0;
    float sumg = 0;
    float sumb = 0;
    int pix;
    
    // constrain to dimensions of the image
    if(x1 < 0){
      x1 = 0;
    }
    if(x2 >= width){
      x2 = width-1;
    }
    if(y1 < 0){
      y1 = 0;
    }
    if(y2 >= height){
      y2 = height-1;
    }
    
    // get RGB sum of pixels
    for(int y = y1; y <= y2; y++){
      for(int i = width * y + x1; i <= width * y + x2; i++){
        pix = img.pixels[i];
        sumb += pix & 0xFF;  // blue
        pix = pix >> 8;
        sumg += pix & 0xFF;  // green
        pix = pix >> 8;
        sumr += pix & 0xFF;  // red
      }
    }
    
    // average the RGB values
    int n = (x2 - x1 + 1) * (y2 - y1 + 1);  // number of pixels
    ar = sumr / n;
    ag = sumg / n;
    ab = sumb / n;
  }
  
  private void getNext9(float x[], float y[], int i, int j){
    y[j + 0] = x[i + 0];
    y[j + 1] = x[i - 1];
    y[j + 2] = x[i + 1];
    y[j + 3] = x[i - gw];
    y[j + 4] = x[i + gw];
    y[j + 5] = x[i - gw - 1];
    y[j + 6] = x[i - gw + 1];
    y[j + 7] = x[i + gw - 1];
    y[j + 8] = x[i + gw + 1];
  }
  
  private void solveFlow(int ig){
    float xx, xy, yy, xt, yt;
    float a, u, v;
    xx = xy = yy = xt = yt = 0;
    
    // prepare covariances
    for(int i=0; i < fm; i++){
      xx += fx[i] * fx[i];
        xy += fx[i] * fy[i];
        yy += fy[i] * fy[i];
        xt += fx[i] * ft[i];
        yt += fy[i] * ft[i];
    }
    
    // lease squares computation
    a = xx * yy - xy * xy + fc;   // fc is for stable computation
    u = yy * xt - xy * yt;       // x direction
    v = xx * yt - xy * xt;       // y direction
    
    // write back
    flowx[ig] = -2 * gs * u / a;   // optical flow x (pixel per frame)
    flowy[ig] = -2 * gs * v / a;   // optical flow y (pixel per frame)
  }
  
  private PImage mirrorImage(PImage img){
    img.loadPixels();
    for(int y=0; y < height; y++) {
      int ig = y * width;
          for(int x=0; x < width; x++){
            imgLine[x] = img.pixels[ig + x];
          }
          for(int x=0; x < width; x++){
            img.pixels[ig + x] = imgLine[width - 1 - x];
          }
    }
    img.updatePixels();
    return img;
  }
  
  /**
   * Returns a 2D array of flow field values.
   * @return float[index][x,y] flowField
   */
  public float[][] getFlowField(){
    return flowField;
  }
  
  /**
   * Returns number of grid cells horizontally.
   * @return int gridWidth
   */
  public int getGridWidth(){
    return gw;
  }
  
  /**
   * Returns number of grid cells vertically.
   * @return int gridHeight
   */
  public int getGridHeight(){
    return gh;
  }
  
  /**
   * Returns spacing of flow field grid on image.
   * @return int resolution
   */
  public int getResolution(){
    return gs;
  }
  
  /**
   * Returns the velocity from a single flow field cell.
   * @param normX - normalized horizontal position of flow field cell.
   * @param normY - normalized vertical position of flow field cell.
   * @return - float[xvel, yvel]
   */
  public float[] getVel(float normX, float normY){
    if(normX >= 0 && normX < 1 && normY >= 0 && normY < 1){
      int col = (int)(normX * gw);
      int row = (int)(normY * gh);
      float xvel = sflowx[row * gw + col];
      float yvel = sflowy[row * gw + col];
      float[] vel = {xvel, yvel};
      return vel;
    }
    float[] vel = {0,0};
    return vel;
  }
  
  /**
   * Pass in a new frame of video to analyze optical flow.
   * @param img - PImage of video frame.
   */
  public void update(PImage img){
    if(flagMirror){
      img = mirrorImage(img);
    }
    
    // 1st sweep: differentiation by time
    for(int ix=0; ix < gw; ix++){
      int x0 = ix * gs + gs2;
      for(int iy=0; iy < gh; iy++){
        int y0 = iy * gs + gs2;
        int ig = iy * gw + ix;
        // compute average pixel at (x0,y0)
        averagePixels(img, x0 - as, y0 - as, x0 + as, y0 + as);
        // compute time difference
        dtr[ig] = ar - par[ig];  // red
        dtg[ig] = ag - pag[ig];  // green
        dtb[ig] = ab - pab[ig];  // blue
        // save the pixel
        par[ig] = ar;
        pag[ig] = ag;
        pab[ig] = ab;
      }
    }
    
    // 2nd sweep: differentiation by x and y
    for(int ix=1; ix < gw - 1; ix++){
      for(int iy=1; iy < gh - 1; iy++){
        int ig = iy * gw + ix;
        // compute x difference
        dxr[ig] = par[ig+1] - par[ig-1];   // red
            dxg[ig] = pag[ig+1] - pag[ig-1];   // green
            dxb[ig] = pab[ig+1] - pab[ig-1];   // blue
            // compute y difference
            dyr[ig] = par[ig+gw] - par[ig-gw];   // red
            dyg[ig] = pag[ig+gw] - pag[ig-gw];   // green
            dyb[ig] = pab[ig+gw] - pab[ig-gw];   // blue
      }
    }
    
    // 3rd sweep: solving optical flow
    for(int ix=1; ix < gw - 1; ix++){
      for(int iy=1; iy < gh - 1; iy++){
        int ig = iy * gw + ix;
        // prepare vectors fx, fy, ft
        getNext9(dxr, fx, ig, 0);       // dx red
        getNext9(dxg, fx, ig, 9);       // dx green
        getNext9(dxb, fx, ig, 18);      // dx blue
        getNext9(dyr, fy, ig, 0);       // dy red
            getNext9(dyg, fy, ig, 9);       // dy green
            getNext9(dyb, fy, ig, 18);      // dy blue
            getNext9(dtr, ft, ig, 0);       // dt red
            getNext9(dtg, ft, ig, 9);       // dt green
            getNext9(dtb, ft, ig, 18);      // dt blue
            // solve for (flowx, flowy)
            solveFlow(ig);
            // smoothing
            sflowx[ig] += (flowx[ig] - sflowx[ig]) * wflow;
            sflowy[ig] += (flowy[ig] - sflowy[ig]) * wflow;
      }
    }
    
    // 4th sweep: put sflowx/sflowy in flowfield array
    for(int i=0; i < flowField.length; i++){
      flowField[i][0] = sflowx[i];
      flowField[i][1] = sflowy[i];
    }
  }

}