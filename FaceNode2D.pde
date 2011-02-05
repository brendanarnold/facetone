import hypermedia.video.*;
import ddf.minim.*;
import ddf.minim.signals.*;

int NNODES = 5;
static int INVERSESPACE = 2;
static int EDGE = 1;
Node[] nodes;
int numPixels, i;
int[] rawPixels;
int[] edgePixels;

boolean isCaptured = false;
float[][] mat = { {  0,  1,  0 },
                   { -1,  0,  1 },
                   {  0, -1,  0 } };
PFont greek;
PImage invSpaceImg;
float   theta = 0.0;
int tCaptured;

OpenCV opencv;
Minim minim;
AudioOutput out;
GammaSignal gSig;
KSignal kSig;
SigmaSignal sSig;
WSignal wSig;
LSignal lSig;


void setup() {
  size(640, 480, P2D);
  // Camera stuff
  opencv = new OpenCV(this);
  opencv.capture(width, height);
  // Sound bits
  minim = new Minim(this);
  out = minim.getLineOut(Minim.MONO);
  
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

  
  
}

void draw() {
  if (!isCaptured) 
  {
    // Copy video direct to buffer, no need for 3D
    opencv.read();
    image(opencv.image(), 0, 0);
  } 
  else
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
    // Look for nodes by lowering threshold until 5 nodes are found
    Blob[] blobs;
    int thresh = 255;
    do {
      opencv.read();
      opencv.threshold(thresh);
      blobs = opencv.blobs(100, width * height /3, 5, true);
      thresh -= 10;
    } while (blobs.length < 5);
    // Save picture in inverse space to image
    invSpaceImg.loadPixels();
    nodeFilter(INVERSESPACE, opencv.image().pixels, invSpaceImg.pixels);
    invSpaceImg.updatePixels();
    for (i=0; i < blobs.length; i++) {
      nodes[i].x = blobs[i].centroid.x;
      nodes[i].y = blobs[i].centroid.y;
    }
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
          magnitude += bw * mat[ky+1][kx+1];
        }
      }
      magnitude = constrain(magnitude, 0, 255);
      outPixels[x + (y*horiz)] = color(255 - magnitude);
    }
  }
}


void stop()
{
  out.close();
  minim.stop();
  
  super.stop();
}

