class Button {
  int row;
  int column;
  int x, y;                 // The x- and y-coordinates
  float w;                  // Width
  float h;                  // Height
  color baseGray;           // Default gray value 
  color overGray;           // Value when mouse is over the button
  color pressGray;          // Value when mouse is over and pressed
  boolean over = false;     // True when the mouse is over 
  boolean prevOver = false;
  boolean pressed = false;  // True when the mouse is over and pressed
  int state;
  long startTime = 0;

  Button(int _row, int _column, int _x, int _y, float _w, float _h, color b, color o, color p) {

    row = _row;
    column = _column; 
    x = _x;
    y = _y;
    w = _w;
    h = _h;
    baseGray = b;
    overGray = o;
    pressGray = p;
  }

  // Updates the over field every frame
  void update(float x, float y) {

    float bX = x;
    float bY = y;


    if ((bX >= this.x) && (bX <= this.x+w) && 
      (bY >= this.y) && (bY <= this.y+h)) {    
      over = true;
    } else {
      //over = false;
    }
    state = int(pressed);

    //if (over == true && prevOver ==! over) {
    //  startTime = millis();
    //}
    //if (over == true && millis() - startTime > 2000) {
    //  pressed =! pressed;
    //  startTime = millis();
    //}
    //prevOver = over;
  }
  void autoPress() {
    //if (over == true) {
    if (over == true && prevOver ==! over) {
     startTime = millis();
    }
    if (over == true && millis() - startTime > 2000) {
     pressed =! pressed;
     startTime = millis();
    }
    prevOver = over;
  }

  boolean press() {  
    if (over == true) {
      pressed =! pressed;
      return true;
    } else {
      return false;
    }
  }


  void display() {

    if (pressed == true) {
      fill(pressGray, 100);
    } else if (over == true) {
      fill(overGray, 100);
    } else {
      fill(baseGray, 100);
    }
    stroke(255);
    rect(x, y, w, h);
  }


  void displayNumbers() {
    pushStyle();
    textAlign(CENTER);
    textSize(10);
    fill(255, 0, 0);
    text(row + " " + column + " " + state, x+w/2, y+h/2);
    popStyle();
  }
}