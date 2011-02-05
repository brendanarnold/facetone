import processing.video.*; 
import ddf.minim.*;
import ddf.minim.signals.*;

int NNODES = 5;
static int INVERSESPACE = 2;
static int EDGE = 1;
Node[] nodes;
int numPixels, i;
int[] rawPixels;
int[] edgePixels;
Capture video;
boolean isCaptured = false;
float[][] mat = { {  0,  1,  0 },
                   { -1,  0,  1 },
                   {  0, -1,  0 } };
PFont greek;
PImage invSpaceImg;
float   theta = 0.0;
int tCaptured;

Minim minim;
AudioOutput out;
GammaSignal gSig;
KSignal kSig;
SigmaSignal sSig;
WSignal wSig;
LSignal lSig;


void setup() {
  size(640, 480, P2D);
  //size(320, 240);
  frameRate(24);
  video = new Capture(this, width, height, 10);
  rawPixels = new int[width * height];
  edgePixels = new int[width * height];
  nodes = new Node[NNODES];
  nodes[0] = new Node("K");
  nodes[1] = new Node("\u0393");
  nodes[2] = new Node("L");
  nodes[3] = new Node("\u03A3");
  nodes[4] = new Node("W");
  greek = loadFont("Times-Roman-48.vlw");
  textFont(greek, 25);
  invSpaceImg = createImage(width, height, RGB);
  
  // Sound bits
  minim = new Minim(this);
  out = minim.getLineOut(Minim.MONO, 2048);
  
  
}

void draw() {
  if (video.available() && !isCaptured) 
  {
    // Copy video direct to buffer, no need for 3D
    video.read();
    video.loadPixels();
    loadPixels();
    arrayCopy(video.pixels, pixels);
    //nodeFilter(EDGE, video.pixels, pixels);
    updatePixels();
  } 
  else if (isCaptured) 
  {
    // Draw the inverse space image
    image(invSpaceImg, 0, 0);
    // Draw the nodes, annotate and join with lines 
    for (int i=0; i < NNODES; i++) {
      nodes[i].draw(false);
      if (i != (NNODES - 1)) {
        stroke(255, 0, 0);
        line(nodes[i].x, nodes[i].y, nodes[i+1].x, nodes[i+1].y);
      }
    }
  }
}

void keyPressed() {
  if (keyCode == 'X') {
    video.read();
    video.loadPixels();
    // Save picture in inverse space to image
    invSpaceImg.loadPixels();
    nodeFilter(INVERSESPACE, video.pixels, invSpaceImg.pixels);
    invSpaceImg.updatePixels();
    // Save edge filtered image
    loadPixels();
    nodeFilter(EDGE, video.pixels, edgePixels);
    updatePixels();
    findNodes();
    isCaptured = true;
    tCaptured = millis();
    // Now figure out the sound
    kSig = new KSignal(nodes[0].getFreq(), nodes[0].getVol());
    sSig = new SigmaSignal(nodes[1].getFreq(), nodes[1].getVol());
    lSig = new LSignal(nodes[2].getFreq(), nodes[2].getVol());
    gSig = new GammaSignal(nodes[3].getFreq(), nodes[3].getVol());
    wSig = new WSignal(nodes[4].getFreq(), nodes[4].getVol());
    out.addSignal(lSig);
    out.addSignal(wSig);
    out.addSignal(gSig);
    out.addSignal(kSig);
    out.addSignal(sSig);
  }
}

void nodeFilter(int type, int[] inPixels, int[] outPixels) {;
  int vert, horiz;
  if (type == INVERSESPACE) { 
    // Inverse space filter
    vert = width*2;
    horiz = height / 2;
  } else {
    // Edge filter
    vert = height;
    horiz = width;      
  }
  for (int y = 1; y < vert-1; y++) {
    for (int x = 1; x < horiz-1; x++) {
      float magnitude = 0;
      for (int ky=-1; ky <= 1; ky++) {
        for (int kx=-1; kx <= 1; kx++) {
          int pos = x + kx + (y + ky)*horiz;
          float bw = brightness(inPixels[pos]);
          if ((type == EDGE) && (bw > 100)) bw = 255;
          if ((type == EDGE) && (bw <= 100)) bw = 0;
          magnitude += bw * mat[ky+1][kx+1];
        }
      }
      magnitude = constrain(magnitude, 0, 255);
      outPixels[x + (y*horiz)] = color(255 - magnitude);
    }
  }
}

//void findNodes() {
//  nodes[0].x = 25 ; // K
//  nodes[0].y = 25;
//  nodes[1].x = 125;
//  nodes[1].y = 125;
//  nodes[2].x = 225;
//  nodes[2].y = 225;
//  nodes[3].x = 325;
//  nodes[3].y = 325;
//  nodes[4].x = 420; // W
//  nodes[4].y = 420;
//}

void findNodes() {
  int TIMEOUT = 5000;
  int n = 0;
  int t = millis();
  while (n < NNODES) {
    int rpos = int(random(width, width*height - width));
    int len = 1;
    // Look for continuous regions of edge
    if (brightness(edgePixels[rpos]) < 10) {
      while (((rpos - len) > 0) && (brightness(edgePixels[rpos - len]) < 10)) len += 1;   
    }
    // Also have a tomeout safety net incase there are no continuous regions
    if ((len > 4) || ((millis() - t) > TIMEOUT)) {
      nodes[n].x = ((rpos - len) % width);
      nodes[n].y = int((rpos - len) / width);
      //println(nodes[n].x + " " + nodes[n].y + " " + " " + len);
      n += 1;
    }   
  } 
}



void stop()
{
  out.close();
  minim.stop();
  
  super.stop();
}

