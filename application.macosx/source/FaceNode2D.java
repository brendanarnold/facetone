import processing.core.*; 
import processing.xml.*; 

import processing.video.*; 
import ddf.minim.*; 
import ddf.minim.signals.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class FaceNode2D extends PApplet {

 



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
float   theta = 0.0f;
int tCaptured;

Minim minim;
AudioOutput out;
GammaSignal gSig;
KSignal kSig;
SigmaSignal sSig;
WSignal wSig;
LSignal lSig;


public void setup() {
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

public void draw() {
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

public void keyPressed() {
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

public void nodeFilter(int type, int[] inPixels, int[] outPixels) {;
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

public void findNodes() {
  int TIMEOUT = 5000;
  int n = 0;
  int t = millis();
  while (n < NNODES) {
    int rpos = PApplet.parseInt(random(width, width*height - width));
    int len = 1;
    // Look for continuous regions of edge
    if (brightness(edgePixels[rpos]) < 10) {
      while (((rpos - len) > 0) && (brightness(edgePixels[rpos - len]) < 10)) len += 1;   
    }
    // Also have a tomeout safety net incase there are no continuous regions
    if ((len > 4) || ((millis() - t) > TIMEOUT)) {
      nodes[n].x = ((rpos - len) % width);
      nodes[n].y = PApplet.parseInt((rpos - len) / width);
      //println(nodes[n].x + " " + nodes[n].y + " " + " " + len);
      n += 1;
    }   
  } 
}



public void stop()
{
  out.close();
  minim.stop();
  
  super.stop();
}


class GammaSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  
  GammaSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  public void generate(float[] samp) {
    int high = 1;
    for (int i=0; i < samp.length; i++) {
      int lambda = PApplet.parseInt(2048 / this.freq);
      if (i % lambda == 0) high *= -1;
      if (high < 0) {
        samp[i] = vol; 
      } else {
        samp[i] = 0;
      }
    }
  }
  // this is a stricly mono signal
  public void generate(float[] left, float[] right)
  {
    generate(left);
    generate(right);
  }
}
class KSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  
  KSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  public void generate(float[] samp) {
    int high = 1;
    float lambda = PApplet.parseInt(2048 / this.freq);
    for (int i=0; i < samp.length; i++) {
      samp[i] = vol*sin(TWO_PI * i / lambda);
    }
  }
  // this is a stricly mono signal
  public void generate(float[] left, float[] right)
  {
    generate(left);
    generate(right);
  }
}

class LSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  
  LSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  public void generate(float[] samp) {
    int high = 1;
    for (int i=0; i < samp.length; i++) {
      int lambda = PApplet.parseInt(2048 / this.freq);
      if (i % lambda == 0) high *= -1;
      if (high < 0) {
        samp[i] = vol; 
      } else {
        samp[i] = 0;
      }
    }
  }
  // this is a stricly mono signal
  public void generate(float[] left, float[] right)
  {
    generate(left);
    generate(right);
  }
}
class Node {
  int x, y;
  String name;
  Node(String name) {
    this.name = name;
  }
  public void draw(boolean highlight) {
    pushStyle();
    noStroke();
    int fillCol = color(255, 0, 0);
    if (highlight) fillCol = color(0, 200, 0);
    fill(fillCol);
    ellipse(this.x, this.y, 10, 10);
    text(this.name, this.x + 15, this.y + 15, 0);
    popStyle();
  }
  public float getFreq() {
    float freq = map(atan2(this.y, this.x), 0, 90, 60, 1500);
    return freq;
  }
  public float getVol() {
    float vol = map(sqrt(sq(this.x) + sq(this.y)), 0, sqrt(sq(width) + sq(height)), 0.0f, 1.0f);
    return vol;
  }
}

class SigmaSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  
  SigmaSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  public void generate(float[] samp) {
    float lambda = PApplet.parseInt(2048 / this.freq);
    for ( int i = 0; i < samp.length; i += lambda )
    {
      for ( int j = 0; j < lambda && (i+j) < samp.length; j++ )
      {
        samp[i + j] = map(j, 0, lambda, -this.vol, this.vol);
      }
    
    }
  }
  // this is a stricly mono signal
  public void generate(float[] left, float[] right)
  {
    generate(left);
    generate(right);
  }
}

class WSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  
  WSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  public void generate(float[] samp) {
    int high = 1;
    for (int i=0; i < samp.length; i++) {
      int lambda = PApplet.parseInt(2048 / this.freq);
      if (i % lambda == 0) high *= -1;
      if (high < 0) {
        samp[i] = vol; 
      } else {
        samp[i] = 0;
      }
    }
  }
  // this is a stricly mono signal
  public void generate(float[] left, float[] right)
  {
    generate(left);
    generate(right);
  }
}
  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "FaceNode2D" });
  }
}
