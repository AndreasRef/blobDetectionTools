//A simple GUItool for testing out functionality in the BlobDetection library and finding the right values for your project. 
//Andreas Refsgaard 2016: www.andreasrefsgaard.dk

// - BlobDetection library - http://www.v3ga.net/processing/BlobDetection/index-page-documentation.html
// - Super Fast Blur v1.1 by Mario Klingemann <http://incubator.quasimondo.com>

// Also see https://github.com/bgcallam/Cloud-Attractor for inspiration

//Test comment laptop to test Github sync

import processing.video.*;
import blobDetection.*;
import controlP5.*;
ControlP5 cp5;

Capture cam;
BlobDetection theBlobDetection;
PImage img;
boolean newFrame=false;

int programHeight = 480;

boolean positiveNegative = true;
boolean showBlobs = true;
boolean showEdges = true;
float luminosityThreshold = 0.8;
float minimumBlobSize = 10;

void setup()
{
  size(640, 640); // Originally 640x480 - main program runs 640x480 and the extra height is for controlP5 interface
  background(0);
  cam = new Capture(this, 40*4, 30*4, 15); 
  cam.start();

  // BlobDetection
  // img which will be sent to detection (a smaller copy of the cam frame);
  img = new PImage(80*8, 60*8); //Originally just 80x60
  theBlobDetection = new BlobDetection(img.width, img.height);
  theBlobDetection.setPosDiscrimination(positiveNegative); // True: Find bright areas - False: Find dark areas
  theBlobDetection.setThreshold(luminosityThreshold); // will detect bright areas whose luminosity > 0.2f;
  theBlobDetection.activeCustomFilter(this);
   
  //ControlP5
  cp5 = new ControlP5(this);
  cp5.addToggle("showBlobs").setPosition(10, programHeight +10).setSize(50, 20);
  cp5.addToggle("showEdges").setPosition(65, programHeight +10).setSize(50, 20);
  cp5.addSlider("luminosityThreshold", 0.0, 1.0, 150, programHeight + 25, width-300, 25);
  cp5.addSlider("minimumBlobSize", 0, 300, 150, programHeight + 65, width-300, 25);
}

void captureEvent(Capture cam)
{
  cam.read();
  newFrame = true;
}

void draw()
{
  if (newFrame)
  {
    newFrame=false;
    image(cam, 0, 0, 640, 480);
    img.copy(cam, 0, 0, cam.width, cam.height, 
      0, 0, img.width, img.height);
    fastblur(img, 2);
    theBlobDetection.computeBlobs(img.pixels);
    drawBlobsAndEdges(showBlobs, showEdges);
  }

  theBlobDetection.setThreshold(luminosityThreshold); 

  pushStyle();
  noStroke();
  fill(0);
  rect(0, programHeight, width, height-programHeight);
  fill(255);
  textSize(12);
  textAlign(LEFT);
  if (positiveNegative) { 
    text("find bright areas", 10, height - 75);
  } else {
    text("find dark areas", 10, height - 75);
  }
  text("filtered blobs:" + "?", 10, height - 50);
  text("total blobs:" + theBlobDetection.getBlobNb(), 10, height - 25);
  popStyle();
}

void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges)
{
  noFill();
  Blob b;
  EdgeVertex eA, eB;
  for (int n=0; n<theBlobDetection.getBlobNb(); n++)
  {
    println(theBlobDetection.getBlob(0).h*480);

if ((theBlobDetection.getBlob(n).w*width + theBlobDetection.getBlob(n).h*480)>minimumBlobSize) {
    b=theBlobDetection.getBlob(n);


    if (b!=null)

        {
          // Edges
          if (drawEdges)
          {
            strokeWeight(3);
            stroke(0, 255, 0);
            for (int m=0; m<b.getEdgeNb(); m++)
            {
              eA = b.getEdgeVertexA(m);
              eB = b.getEdgeVertexB(m);
              if (eA !=null && eB !=null)
                line(
                  eA.x*width, eA.y*480, 
                  eB.x*width, eB.y*480
                  );
            }
          }

          // Blobs
          if (drawBlobs)
          {
            strokeWeight(1);
            stroke(255, 0, 0);
            rect(
              b.xMin*width, b.yMin*480, 
              b.w*width, b.h*480
              );

            //Calculate and display the center of each blob
            pushStyle();
            textAlign(CENTER, CENTER);
            fill(0, 0, 255);
            text(n + "*" + round(b.xMin*width + b.w*width/2) +"," + round(b.yMin*480 + b.h*480/2), b.xMin*width + b.w*width/2, b.yMin*480 + b.h*480/2);
            popStyle(); 
        }
        }
      }
  }
}


boolean newBlobDetectedEvent(Blob b) // Filtering blobs (discard "little" ones)
{
  int w = (int)(b.w * width);
  int h = (int)(b.h * 480);
  if (w >= minimumBlobSize || h >= minimumBlobSize) {
    return true;
  } else {
  return false;
  }
}


// ==================================================
// Super Fast Blur v1.1
// by Mario Klingemann 
// <http://incubator.quasimondo.com>
// ==================================================
void fastblur(PImage img, int radius)
{
  if (radius<1) {
    return;
  }
  int w=img.width;
  int h=img.height;
  int wm=w-1;
  int hm=h-1;
  int wh=w*h;
  int div=radius+radius+1;
  int r[]=new int[wh];
  int g[]=new int[wh];
  int b[]=new int[wh];
  int rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw;
  int vmin[] = new int[max(w, h)];
  int vmax[] = new int[max(w, h)];
  int[] pix=img.pixels;
  int dv[]=new int[256*div];
  for (i=0; i<256*div; i++) {
    dv[i]=(i/div);
  }

  yw=yi=0;

  for (y=0; y<h; y++) {
    rsum=gsum=bsum=0;
    for (i=-radius; i<=radius; i++) {
      p=pix[yi+min(wm, max(i, 0))];
      rsum+=(p & 0xff0000)>>16;
      gsum+=(p & 0x00ff00)>>8;
      bsum+= p & 0x0000ff;
    }
    for (x=0; x<w; x++) {

      r[yi]=dv[rsum];
      g[yi]=dv[gsum];
      b[yi]=dv[bsum];

      if (y==0) {
        vmin[x]=min(x+radius+1, wm);
        vmax[x]=max(x-radius, 0);
      }
      p1=pix[yw+vmin[x]];
      p2=pix[yw+vmax[x]];

      rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
      gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
      bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
      yi++;
    }
    yw+=w;
  }

  for (x=0; x<w; x++) {
    rsum=gsum=bsum=0;
    yp=-radius*w;
    for (i=-radius; i<=radius; i++) {
      yi=max(0, yp)+x;
      rsum+=r[yi];
      gsum+=g[yi];
      bsum+=b[yi];
      yp+=w;
    }
    yi=x;
    for (y=0; y<h; y++) {
      pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
      if (x==0) {
        vmin[y]=min(y+radius+1, hm)*w;
        vmax[y]=max(y-radius, 0)*w;
      }
      p1=x+vmin[y];
      p2=x+vmax[y];

      rsum+=r[p1]-r[p2];
      gsum+=g[p1]-g[p2];
      bsum+=b[p1]-b[p2];

      yi+=w;
    }
  }
}