// This project is based from Runway's Processing example for PoseNet OSC messaging
// The original example was written by Anastasis Germanidis
// and adapted by George Profenza

//OSC libraries
import oscP5.*;
import netP5.*;

//Runway library
import com.runwayml.*;

import themidibus.*; 

//runway instance
RunwayOSC runway;

//Holds detected human
JSONObject data;

//for body parts
int[] bodyParts = {
  ModelUtils.POSE_NOSE_INDEX,
  ModelUtils.POSE_RIGHT_SHOULDER_INDEX,
  ModelUtils.POSE_RIGHT_ELBOW_INDEX,
  ModelUtils.POSE_RIGHT_WRIST_INDEX,
  ModelUtils.POSE_LEFT_SHOULDER_INDEX,
  ModelUtils.POSE_LEFT_ELBOW_INDEX,
  ModelUtils.POSE_LEFT_WRIST_INDEX
};

//Holds body part coordinates
float noseX, noseY, rShouldX,rShouldY, rElbowX, rElbowY, rWristX,
      rWristY, lShouldX, lShouldY, lElbowX, lElbowY, lWristX, lWristY;
    
//variables for MIDI value holding/manipulation
MidiBus myBus;
int channel = 0;
float[] ccArray = new float[5];
float[] lastValues = new float[5];
float[] currentValues = new float[5];

String[] displayNames = {"Nose (X) ", "R Wrist (Y) ", "R Shoulder (Y) ", "L Wrist (Y) ", "L Should (Y) "};


void setup(){
  size(600,400);
    
  // setup Runway
  runway = new RunwayOSC(this);
  
  MidiBus.list(); 
  myBus = new MidiBus(this, 0, 2); 
  
  for (int i = 0; i < 5; i++) {
    ccArray[i] = 110 + i;
    lastValues[i] = 0;
    currentValues[i] = 0;
  }
}

void draw(){
  background(0);
  
  handleParts(data);  //call function to grab part coordinates
  calVals();          //convert part values to MIDI
  valueFilter();      //smooth values
 
  for (int i = 0; i < 5; i++) {  
    myBus.sendControllerChange(channel, (int)ccArray[i], (int)currentValues[i]);
  }
  
  displayCCValues();
}

void handleParts(JSONObject data){
  //if humans detected
  if (data != null) {
    JSONArray human = data.getJSONArray("poses");
    
    //deconstruct human
    for(int h = 0; h < human.size(); h++) {
      JSONArray keypoints = human.getJSONArray(h);
      
      //grab body parts
      JSONArray nose = keypoints.getJSONArray(bodyParts[0]);
      JSONArray rShould = keypoints.getJSONArray(bodyParts[1]);
      JSONArray rWrist = keypoints.getJSONArray(bodyParts[3]);
      JSONArray lShould = keypoints.getJSONArray(bodyParts[4]);
      JSONArray lWrist = keypoints.getJSONArray(bodyParts[6]);
        
      //grab body part coordinates  
      noseX = nose.getFloat(0) * width;
      noseY = nose.getFloat(1) * height;
        
      rShouldX = rShould.getFloat(0) * width;
      rShouldY = rShould.getFloat(1) * height;
      rWristX = rWrist.getFloat(0) * width;
      rWristY = rWrist.getFloat(1) * height;
        
      lShouldX = lShould.getFloat(0) * width;
      lShouldY = lShould.getFloat(1) * height;
      lWristX = lWrist.getFloat(0) * width;
      lWristY = lWrist.getFloat(1) * height;

      //display body part coordinates
      ellipse((int)noseX,(int)noseY, 20, 20);
      ellipse((int)rShouldX,(int)rShouldY, 20, 20);
      ellipse((int)rWristX,(int)rWristY, 20, 20);
      ellipse((int)lShouldX,(int)lShouldY, 20, 20);
      ellipse((int)lWristX,(int)lWristY, 20, 20);
    }
  }
}

void calVals() {
  currentValues[0] = (int)((noseX/600.0)*128.0);
  currentValues[1] = (int)((rWristY/400.0)*128.0);
  currentValues[2] = (int)((rShouldY/400.0)*128.0);
  currentValues[3] = (int)((lWristY/400.0)*128.0);
  currentValues[4] = (int)((lShouldY/400.0)*128.0);
  
  for (int i = 0; i < 5; i++) {
    if (currentValues[i] < 0)
    {
      currentValues[i] = 0;
    }
    
    if (currentValues[i] > 128)
    {
      currentValues[i] = 128;
    }
  }
}

void valueFilter() {
  for (int i = 0; i < 5; i++) {
    currentValues[i] = (lastValues[i]*.5) + (currentValues[i]*.5);
    lastValues[i] = currentValues[i];
  }
}

void displayCCValues() {
  for (int i = 0; i < 5; i++)
  {
    text(displayNames[i] + "- CC " + (int)ccArray[i] + ": " + (int)currentValues[i], 10, 30 + (i * 30));
  }
}

// this is called when new Runway data is available
void runwayDataEvent(JSONObject runwayData){
  // point the sketch data to the Runway incoming data 
  data = runwayData;
}

// this is called each time Processing connects to Runway
// Runway sends information about the current model
public void runwayInfoEvent(JSONObject info){
  println(info);
}
// if anything goes wrong
public void runwayErrorEvent(String message){
  println(message);
}

// Note: if the RunwayModel was stopped and resumed while Processing is running
// it's best to reconnect to it via OSC
void keyPressed(){
  switch(key) {
    case('c'):
      /* connect to Runway */
      runway.connect();
      break;
    case('d'):
      /* disconnect from Runway */
      runway.disconnect();
      break;
  }
}
