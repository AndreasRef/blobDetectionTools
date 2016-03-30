void controlP5setup() {
 
    //Shared dimensions
  int toogleWidth = 50;
  int toogleHeight = 20;
  int sliderHeight = 10;
  int sliderWidth = 100;
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
  cp5.addSlider("luminosityThreshold", 0.0, 1.0).setPosition(100, 10).setSize(sliderWidth, sliderHeight).setGroup(BlobControls).listen(true);
  cp5.addSlider("minimumBlobSize", 0, 250).setPosition(100, 45).setSize(sliderWidth, sliderHeight).setGroup(BlobControls).listen(true);
  cp5.addSlider("blurFactor", 0, 50).setPosition(100, 80).setSize(sliderWidth, sliderHeight).setGroup(BlobControls).listen(true);

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
  
  cp5.addSlider("kinect0X", -100, 100, 10, 50, sliderWidth-25, sliderHeight).setGroup(KinectControls).listen(true);
  cp5.addSlider("kinect0Y", -100, 100, 10, 70, sliderWidth-25, sliderHeight).setGroup(KinectControls).listen(true);
  
  cp5.addSlider("kinect1X", -100, 100, 10, 90, sliderWidth-25, sliderHeight).setGroup(KinectControls).listen(true);
  cp5.addSlider("kinect1Y", -100, 100, 10, 110, sliderWidth-25, sliderHeight).setGroup(KinectControls).listen(true);
 

  //Buttons GUI
  Group ButtonControls = cp5.addGroup("ButtonControls")
    .setPosition(2*width/4 + xOffset, programHeight + yOffset)
    .setSize(width/4 - xOffset*2 - 100, height-programHeight-yOffset )
    .setBackgroundColor(color(255, 50))
    ;


  cp5.addToggle("autoPress").setPosition(150, 10).setSize(toogleWidth, toogleHeight/2).setGroup(ButtonControls).listen(true);
  cp5.addToggle("mouseControl").setPosition(150, 40).setSize(toogleWidth, toogleHeight/2).setGroup(ButtonControls).listen(true);
  cp5.addToggle("showButtons").setPosition(150, 70).setSize(toogleWidth, toogleHeight/2).setGroup(ButtonControls).listen(true);
  cp5.addButton("clearSeq").setPosition(150,100).setSize(toogleWidth, toogleHeight/2).setGroup(ButtonControls).setColorBackground(color(0, 100, 50)); 
  //cp5.addBang("clearSeq").setPosition(10, 520).setSize(40, 40).setId(0);
  cp5.addSlider("horizontalSteps", 0, 10).setCaptionLabel("rows").setPosition(10, 10).setGroup(ButtonControls);
  cp5.addSlider("verticalSteps", 0, 10).setCaptionLabel("cols").setPosition(10, 30).setGroup(ButtonControls);
  
  cp5.addSlider("startX", 0, 640).setPosition(10, 60).setGroup(ButtonControls);
  cp5.addSlider("startY", 0, 240).setPosition(10, 80).setGroup(ButtonControls);
  cp5.addSlider("endX", 640, 1280).setPosition(10, 100).setGroup(ButtonControls);
  cp5.addSlider("endY", 240, 480).setPosition(10, 120).setGroup(ButtonControls);
  
  //Settings GUI
  Group SettingsControls = cp5.addGroup("SettingsControls")
    .setPosition(3*width/4 + xOffset - 100, programHeight + yOffset)
    .setSize(width/4 - xOffset*2 - 200, height-programHeight-yOffset )
    .setBackgroundColor(color(255, 50))
    ;
  
  cp5.addButton("b3", 10, 10, 10, 80, 12).setCaptionLabel("save default").setGroup(SettingsControls);
  cp5.addButton("b4", 10, 10, 40, 80, 12).setCaptionLabel("load default").setGroup(SettingsControls).setColorBackground(color(0, 100, 50));

  //cp5.loadProperties(("default.json")); //Load saved settings - overwrites ranges (!)
  
  //FrameRate
  cp5.addFrameRate().setInterval(10).setPosition(width-20, height - 10);
  
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

  if (theEvent.isFrom(cp5.getController("horizontalSteps")) 
  || theEvent.isFrom(cp5.getController("verticalSteps"))
  || theEvent.isFrom(cp5.getController("startX"))
  || theEvent.isFrom(cp5.getController("startY"))
  || theEvent.isFrom(cp5.getController("endX"))
  || theEvent.isFrom(cp5.getController("endY"))  ) {
    setupButtons();
  }
}