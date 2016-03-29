//A tool that combines Kinect depth image and blob detection and lets you adjust settings with controlP5. //<>//
//This sketch also divides the screen/floor into a grid and detects where the blobs are + turns them on and off over time (if autoPress == true)
//Additionally this sketch works with two Kinects at the same time, where their depthimages become one PGraphics
//Note that this sketch mirrors the Kinect images. 

// Blob tracking doesn't work that well when you are too close to the Kinects:
// It sees people/objects that cover the full height as two different blobs

//Update 24/3: Added a lot more ControlP5 GUI

//Update 29/3: Resizeable number of buttons + GUI cleanup + load and save properties (buggy...) + RGB view 

import org.openkinect.freenect.*;
import org.openkinect.processing.*;

import blobDetection.*;
import controlP5.*;
ControlP5 cp5;

ArrayList<Kinect> multiKinect;

int numDevices = 0;

PGraphics pg;

//DepthThreshold
PImage depthImg;

//Blob
BlobDetection theBlobDetection;
PImage img;
boolean newFrame=false;

int programHeight = 480; 

//ControlP5
int minDepth =  60;
int maxDepth = 914;

boolean positiveNegative = true;
boolean showBlobs = false;
boolean showEdges = true;
boolean showInformation = false;
float luminosityThreshold = 0.7;
float minimumBlobSize = 100;
int blurFactor = 10;
boolean mirror = true;
boolean rgbView = false;

int cropAmount = 9;

Slider2D kinect0Align;
Slider2D kinect1Align;

//Buttons
int horizontalSteps = 8;
int verticalSteps = 3;
int count;
Button[] buttons;
boolean displayNumbers = true;
boolean autoPress = false;
boolean mouseControl = true;
boolean showButtons = true;

void setup() {
  size(1280, 640);
  pg = createGraphics(1280, 480); 

  numDevices = Kinect.countDevices();
  println("number of Kinect v1 devices  "+numDevices);

  multiKinect = new ArrayList<Kinect>();

  //iterate though all the devices and activate them
  for (int i  = 0; i < numDevices; i++) {
    Kinect tmpKinect = new Kinect(this);
    tmpKinect.enableMirror(mirror);
    tmpKinect.activateDevice(i);
    tmpKinect.initDepth();
    tmpKinect.initVideo();
    multiKinect.add(tmpKinect);
  }
  depthImg = new PImage(640, 480);

  // BlobDetection
  // img which will be sent to detection 
  img = new PImage(1280/4, 480/4); //a smaller copy of the frame is faster, but less accurate. Between 2 and 4 is normally fine
  theBlobDetection = new BlobDetection(img.width, img.height);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setThreshold(luminosityThreshold); // will detect bright areas whose luminosity > luminosityThreshold (reverse if setPosDiscrimination(false);

  //ControlP5
  cp5 = new ControlP5(this);
  //cp5.getProperties().setFormat(ControlP5.SERIALIZED);

  //Shared dimensions
  int toogleWidth = 50;
  int toogleHeight = 20;
  int sliderHeight = 10;
  int sliderWidth = 150;
  int xOffset = 2;
  int yOffset = 20;

  //Blob GUI
  Group BlobControls = cp5.addGroup("BlobControls")
    .setPosition(0 + xOffset, programHeight + yOffset)
    .setSize(width/4 - xOffset*2, height-programHeight-yOffset)
    .setBackgroundColor(color(255, 50))
    ;

  cp5.addToggle("showInformation").setPosition(10, 10).setSize(toogleWidth, toogleHeight).setGroup(BlobControls).listen(true);
  cp5.addToggle("showBlobs").setPosition(10, 50).setSize(toogleWidth, toogleHeight).setGroup(BlobControls).listen(true);
  cp5.addToggle("showEdges").setPosition(10, 90).setSize(toogleWidth, toogleHeight).setGroup(BlobControls).listen(true);
  cp5.addSlider("luminosityThreshold", 0.0, 1.0).setPosition(150, 10).setSize(sliderWidth, sliderHeight).setGroup(BlobControls).listen(true);
  cp5.getController("luminosityThreshold").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(5);
  cp5.addSlider("minimumBlobSize", 0, 250).setPosition(150, 45).setSize(sliderWidth, sliderHeight).setGroup(BlobControls).listen(true);
  cp5.getController("minimumBlobSize").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(5);
  cp5.addSlider("blurFactor", 0, 50).setPosition(150, 80).setSize(sliderWidth, sliderHeight).setGroup(BlobControls).listen(true);
  cp5.getController("blurFactor").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(5);

  //Kinect GUI
  Group KinectControls = cp5.addGroup("KinectControls")
    .setPosition(width/4 + xOffset, programHeight + yOffset)
    .setSize(width/4 - xOffset*2, height-programHeight-yOffset )
    .setBackgroundColor(color(255, 50))
    ;

  cp5.addSlider("minDepth", 0, 1000, 10, 10, sliderWidth-25, sliderHeight).setGroup(KinectControls).listen(true);
  cp5.addSlider("maxDepth", 0, 1000, 10, 30, sliderWidth-25, sliderHeight).setGroup(KinectControls).listen(true);
  cp5.addSlider("cropAmount", 0,130,  190, 60, sliderWidth-75, sliderHeight).setGroup(KinectControls).listen(true);
  
  cp5.addToggle("mirror").setPosition(190, 10).setSize(toogleWidth, toogleHeight).setGroup(KinectControls).listen(true);
  cp5.addToggle("rgbView").setPosition(250, 10).setSize(toogleWidth, toogleHeight).setGroup(KinectControls).listen(true);
  kinect0Align = cp5.addSlider2D("kinect0Align").setPosition(10, 50).setSize(75, 75).setMinMax(-50, -50, 50, 50).setValue(0, 0).setGroup(KinectControls);
  kinect1Align = cp5.addSlider2D("kinect1Align").setPosition(100, 50).setSize(75, 75).setMinMax(-50, -50, 50, 50).setValue(0, 0).setGroup(KinectControls);


  //Buttons GUI
  Group ButtonControls = cp5.addGroup("ButtonControls")
    .setPosition(2*width/4 + xOffset, programHeight + yOffset)
    .setSize(width/4 - xOffset*2 - 100, height-programHeight-yOffset )
    .setBackgroundColor(color(255, 50))
    ;


  cp5.addToggle("autoPress").setPosition(10, 10).setSize(toogleWidth, toogleHeight).setGroup(ButtonControls).listen(true);
  cp5.addToggle("mouseControl").setPosition(10, 50).setSize(toogleWidth, toogleHeight).setGroup(ButtonControls).listen(true);
  cp5.addToggle("showButtons").setPosition(10, 90).setSize(toogleWidth, toogleHeight).setGroup(ButtonControls).listen(true);
  cp5.addSlider("horizontalSteps", 0, 10).setPosition(100, 10).setGroup(ButtonControls);
  cp5.getController("horizontalSteps").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(5);
  cp5.addSlider("verticalSteps", 0, 10).setPosition(100, 45).setGroup(ButtonControls);
  cp5.getController("verticalSteps").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(5);

  //Settings GUI
  Group SettingsControls = cp5.addGroup("SettingsControls")
    .setPosition(3*width/4 + xOffset - 100, programHeight + yOffset)
    .setSize(width/4 - xOffset*2 - 200, height-programHeight-yOffset )
    .setBackgroundColor(color(255, 50))
    ;

  cp5.addButton("b3", 10, 10, 10, 80, 12).setCaptionLabel("save default").setGroup(SettingsControls);
  cp5.addButton("b4", 10, 10, 40, 80, 12).setCaptionLabel("load default").setGroup(SettingsControls).setColorBackground(color(0, 100, 50));

  cp5.addBang("reset").setPosition(width -50, height-50).setSize(20, 20);

  //FrameRate
  cp5.addFrameRate().setInterval(10).setPosition(width-20, height - 10);

  setupButtons();
}

void draw() {
  background(0);

  pg.beginDraw();
  pg.background(0);
  for (int i  = 0; i < multiKinect.size(); i++) {
    //Kinect tmpKinect = (Kinect)multiKinect.get(i);
    //image(tmpKinect.getVideoImage(), 640*i, 0);
    multiKinect.get(i).enableMirror(mirror);

    //Threshold 
    int[] rawDepth = multiKinect.get(i).getRawDepth();
    for (int j=0; j < rawDepth.length; j++) {
      if (rawDepth[j] >= minDepth && rawDepth[j] <= maxDepth) {
        depthImg.pixels[j] = color(255);
      } else {
        depthImg.pixels[j] = color(0);
      }
    }
    depthImg.updatePixels();

    //Small hack for removing strange black bars in the left side of the depth images (might not be necessary for other setups)...
    //int cropAmount = 9;
    PImage croppedDepthImage = depthImg.get(cropAmount, 0, depthImg.width-cropAmount, depthImg.height);
    if (i==0) {
      pg.image(croppedDepthImage, croppedDepthImage.width*i+kinect0Align.getArrayValue()[0], 0+kinect0Align.getArrayValue()[1], croppedDepthImage.width, 480); //Be aware that this results in some empty (black) pixels all the way to the left
    } else if (i==1) {
      pg.image(croppedDepthImage, croppedDepthImage.width*i+kinect1Align.getArrayValue()[0], 0+kinect1Align.getArrayValue()[1], croppedDepthImage.width, 480); //Be aware that this results in some empty (black) pixels all the way to the left
    }
    //pg.image(depthImg, 640*i, 0); //Full image without crop
  }
  pg.endDraw();

  image(pg, 0, 0);


  img.copy(pg, 0, 0, pg.width, pg.height, 0, 0, img.width, img.height);
  fastblur(img, blurFactor);
  theBlobDetection.computeBlobs(img.pixels);
  drawBlobsAndEdges(showBlobs, showEdges, showInformation);
  theBlobDetection.setThreshold(luminosityThreshold); 
  theBlobDetection.activeCustomFilter(this);

  if (rgbView) {
    for (int i  = 0; i < multiKinect.size(); i++) {
      pushStyle();
      tint(255, 150);
      Kinect tmpKinect = (Kinect)multiKinect.get(i);

      //int cropAmount = 9;
      //PImage croppedRGBImage = tmpKinect.getVideoImage().get(cropAmount, 0, 640-cropAmount, 480);
      //if (i==0) {
      //  image(croppedRGBImage, croppedRGBImage.width*i+kinect0Align.getArrayValue()[0], 0+kinect0Align.getArrayValue()[1], croppedRGBImage.width, 480); //Be aware that this results in some empty (black) pixels all the way to the left
      //} else if (i==1) {
      //  image(croppedRGBImage, croppedRGBImage.width*i+kinect1Align.getArrayValue()[0], 0+kinect1Align.getArrayValue()[1], croppedRGBImage.width, 480); //Be aware that this results in some empty (black) pixels all the way to the left
      //}


      
      //image(croppedRGBImage, 640*i, 0);
      image(tmpKinect.getVideoImage(), 640*i, 0);
      popStyle();
    }
  }  

  //Buttons
  pushStyle();
  for (Button button : buttons) {
    button.over=false;

    if (mouseControl) {
      button.update(mouseX, mouseY);
    } else {

      Blob b;
      //EdgeVertex eA, eB;
      for (int n=0; n<theBlobDetection.getBlobNb(); n++)
      {
        b=theBlobDetection.getBlob(n);

        button.update(b.xMin*width/1 + b.w*width/2, b.yMin*programHeight + b.h*programHeight/2);
      }
    }
    if (autoPress) button.autoPress();
    if (showButtons) { 
      button.display();
      if (displayNumbers) button.displayNumbers();
    }
  }
  popStyle();

  pushStyle();
  fill(255);
  textSize(16);
  textAlign(LEFT);
  text("BLOBS: " + theBlobDetection.getBlobNb(), 152, height-5);
  popStyle();
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
              eA.x*width/1, eA.y*480, 
              eB.x*width/1, eB.y*480
              );
        }
      }

      // Blobs
      if (drawBlobs)
      {
        strokeWeight(1);
        stroke(255, 0, 0);
        rect(
          b.xMin*width/1, b.yMin*480, 
          b.w*width/1, b.h*480
          );
      }

      //Information (Calculate and display the center of each blob)
      if (blobInformation) {
        pushStyle();
        ellipseMode(CENTER);
        fill(0, 255, 0);
        ellipse(b.xMin*width/1 + b.w*width/2, b.yMin*480 + b.h*480/2, 25, 25);

        textSize(12);
        textAlign(CENTER, CENTER);
        fill(255);
        text("#" + n + "\n (" + round(b.xMin*width/1 + b.w*width/2) +"," + round(b.yMin*480 + b.h*480/2) + ")", b.xMin*width/1 + b.w*width/2, b.yMin*480 + b.h*480/2);
        popStyle();
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

public void reset() {
  minDepth =  60;
  maxDepth = 914;
  positiveNegative = true;
  showBlobs = true;
  showEdges = true;
  showInformation = true;
  luminosityThreshold = 0.7;
  minimumBlobSize = 100;
  blurFactor = 10;
  println("reset settings");
  clearSeq();
}


void b3(float v) {
  cp5.saveProperties("default", "default");
}

void b4(float v) {
  cp5.loadProperties(("default.json"));
}


void clearSeq() {
  for (Button button : buttons) {
    button.state = 0;
    button.pressed = false;
  }
}

void controlEvent(ControlEvent theEvent) {

  if (theEvent.isFrom(cp5.getController("horizontalSteps")) || theEvent.isFrom(cp5.getController("verticalSteps"))) {
    setupButtons();
  }
}

void setupButtons () {

  count = horizontalSteps * verticalSteps;
  buttons = new Button[count];

  int index = 0;
  for (int i = 0; i < horizontalSteps; i++) { 
    for (int j = 0; j < verticalSteps; j++) {
      // Inputs: row, column, x, y, w, h , base color, over color, press color
      buttons[index++] = new Button(i, j, i*1280/horizontalSteps, j*480/verticalSteps, 1280/horizontalSteps, 480/verticalSteps, color(122), color(255), color(0));
    }
  }
}