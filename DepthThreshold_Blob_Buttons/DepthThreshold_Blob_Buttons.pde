//A tool that combines Kinect depth image and blob detection and lets you adjust settings with controlP5. 
//This sketch also divides the floor into a grid and detects where the blobs are + turns them on and off

//ORIGINAL EXAMPLES: 
//1) bd_webcam example --- Blob Detection Library --- http://www.v3ga.net/processing/BlobDetection/ 
//2) Depth threshold example --- OpenKinect Library --- https://github.com/shiffman/OpenKinect-for-Processing  
//3) Example 8 (about buttons), Chapther 33 -  Second Edition of Processing: A Programming Handbook for Visual Designers and Artists 

import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import blobDetection.*;
import controlP5.*;
ControlP5 cp5;

Kinect kinect;

// Depth image
PImage depthImg;

//Blob
BlobDetection theBlobDetection;
PImage img;
boolean newFrame=false;

//ControlP5
int minDepth =  60; // Which pixels do we care about?
int maxDepth = 966; //914

int programHeight = 480;
boolean positiveNegative = true;
boolean showBlobs = true;
boolean showEdges = true;
boolean showInformation = true;
float luminosityThreshold = 0.5;
float minimumBlobSize = 100;
int blurFactor = 30;


//Buttons
int horizontalSteps = 6;
int verticalSteps = 3;
int count;
//PVector control;

Button[] buttons;
boolean displayNumbers = true;
boolean autoPress = true;


void setup() {
  size(1280, 640); // Originally 1280 - main program runs 1280x480. The extra height is for controlP5 interface.

  kinect = new Kinect(this);
  kinect.initDepth();

  // Blank image
  depthImg = new PImage(kinect.width, kinect.height);

  // BlobDetection
  // img which will be sent to detection (a smaller copy of the cam frame will propably be faster, but less accurate);
  img = new PImage(80*8, 60*8); 
  theBlobDetection = new BlobDetection(img.width, img.height);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setThreshold(luminosityThreshold); // will detect bright areas whose luminosity > luminosityThreshold (reverse if setPosDiscrimination(false);

  int sliderHeight = 20;
  int sliderWidth = 150;
  int xOffset = 150;

  //ControlP5
  cp5 = new ControlP5(this);
  cp5.addToggle("showInformation").setPosition(45, programHeight +10).setSize(50, 20).listen(true);
  cp5.getController("showInformation").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.addToggle("showBlobs").setPosition(130, programHeight +10).setSize(50, 20).listen(true);
  cp5.getController("showBlobs").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.addToggle("showEdges").setPosition(215, programHeight +10).setSize(50, 20).listen(true);
  cp5.getController("showEdges").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.addSlider("luminosityThreshold", 0.0, 1.0, 150 + xOffset, programHeight + 10, sliderWidth, sliderHeight).listen(true);
  cp5.getController("luminosityThreshold").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.addSlider("minimumBlobSize", 0, 250, 350 + xOffset, programHeight + 10, sliderWidth, sliderHeight).listen(true);
  cp5.getController("minimumBlobSize").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.addSlider("blurFactor", 0, 50, 550 + xOffset, programHeight + 10, sliderWidth, sliderHeight).listen(true);
  cp5.getController("blurFactor").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.addSlider("minDepth", 0, 1000, 750 + xOffset, programHeight + 10, sliderWidth, sliderHeight).listen(true);
  cp5.getController("minDepth").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.addSlider("maxDepth", 0, 1000, 950 + xOffset, programHeight + 10, sliderWidth, sliderHeight).listen(true);
  cp5.getController("maxDepth").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.addBang("reset", width -50, height-50, 20, 20);


  //Buttons
  float w = 640/horizontalSteps;
  float h = 480/verticalSteps;

  count = horizontalSteps * verticalSteps;
  buttons = new Button[count];

  int index = 0;
  for (int i = 0; i < horizontalSteps; i++) { 
    for (int j = 0; j < verticalSteps; j++) {
      // Inputs: row, column, x, y, w, h , base color, over color, press color
      buttons[index++] = new Button(i, j, i*640/horizontalSteps, j*480/verticalSteps, w, h, color(122), color(255), color(0));
    }
  }
}

void draw() {
  //image(kinect.getDepthImage(), 0, 0);   // Draw the raw image

  noStroke();
  fill(0);
  rect(0, 0, width, height);  //Draw background rect

  // Threshold the depth image
  int[] rawDepth = kinect.getRawDepth();
  for (int i=0; i < rawDepth.length; i++) {
    if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth) {
      depthImg.pixels[i] = color(255);
    } else {
      depthImg.pixels[i] = color(0);
    }
  }

  img.copy(depthImg, 0, 0, depthImg.width, depthImg.height, 0, 0, img.width, img.height);
  fastblur(img, blurFactor);
  theBlobDetection.computeBlobs(img.pixels);
  drawBlobsAndEdges(showBlobs, showEdges, showInformation);
  theBlobDetection.setThreshold(luminosityThreshold); 
  theBlobDetection.activeCustomFilter(this);

  pushStyle();
  fill(255);
  textSize(24);
  textAlign(LEFT);
  text("BLOBS:" + theBlobDetection.getBlobNb(), 10, height- 30);
  popStyle();


  // Draw the thresholded image
  depthImg.updatePixels();
  image(depthImg, kinect.width, 0);

  pushStyle();
  for (Button button : buttons) {
    button.over=false;
    Blob b;
    //EdgeVertex eA, eB;
    for (int n=0; n<theBlobDetection.getBlobNb(); n++)
    {
      b=theBlobDetection.getBlob(n);

      button.update(b.xMin*width/2 + b.w*width/4, b.yMin*programHeight + b.h*programHeight/2);
      
    }
    if (autoPress) button.autoPress();
      button.display();
      if (displayNumbers) button.displayNumbers();
    }
    popStyle();

    ellipseMode(CENTER);
 
  }

  // ==================================================
  // drawBlobsAndEdges()
  // ==================================================
  void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges, boolean blobInformation)
  {
    noFill();
    Blob b;
    EdgeVertex eA, eB;
    for (int n=0; n<theBlobDetection.getBlobNb(); n++)
    {
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
                eA.x*width/2, eA.y*programHeight, 
                eB.x*width/2, eB.y*programHeight
                );
          }
        }

        // Blobs
        if (drawBlobs)
        {
          strokeWeight(1);
          stroke(255, 0, 0);
          rect(
            b.xMin*width/2, b.yMin*programHeight, 
            b.w*width/2, b.h*programHeight
            );
        }

        //Information (Calculate and display the center of each blob)
        if (blobInformation) {
          pushStyle();
          textSize(12);
          textAlign(CENTER, CENTER);
          fill(255);
          text("#" + n + "\n (" + round(b.xMin*width/2 + b.w*width/4) +"," + round(b.yMin*programHeight + b.h*480/2) + ")", b.xMin*width/2 + b.w*width/4, b.yMin*programHeight + b.h*programHeight/2);
          popStyle();
        }
      }
    }
  }

  boolean newBlobDetectedEvent(Blob b) // Filtering blobs (discard "little" ones)
  {
    int w = (int)(b.w * width);
    int h = (int)(b.h * programHeight);
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


  void mousePressed() {
    if (mouseY < programHeight) {
    for (Button button : buttons) {
      button.press();
    }
  }
  }

  public void reset() {
    minDepth =  60;
    maxDepth = 914;
    positiveNegative = true;
    showBlobs = true;
    showEdges = true;
    showInformation = true;
    luminosityThreshold = 0.5;
    minimumBlobSize = 100;
    blurFactor = 30;
    println("reset settings");
  }