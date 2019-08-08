// blueness_LinearAct.ino
// 2016-06-07
//
// Author: Tom Zajdel
// 
// The Arduino listens to serial commands from blueness_main.py Python watcher program
//  1. Initialize the linear actuator by zeroing stepper to limit switch 
//  2. Tell the Python watcher that the Arduino is ready for further instructions
//  3. Parse commands to incrementally move the stepper as they come from the Python watcher

#include <Wire.h>
#include <Adafruit_MotorShield.h>

#define READY 'R'
#define INIT  'I'
#define BUSY  'B'
#define WAIT  'W'

const float mmPerStep = 0.025;
const   int nChars = 32;

boolean newData = false;
int   dir;
float dist;

Adafruit_MotorShield AFMS = Adafruit_MotorShield();
Adafruit_StepperMotor *stepper = AFMS.getStepper(200, 2); 

void setup() {
  // Limit switch to be connected to digital pin 7
  pinMode(7, INPUT);

  AFMS.begin(); 
  
  // Set stepper speed to 1000 rpm
  stepper->setSpeed(1000);

  // Initialize serial communications over USB, then tell the Python watcher that system is ready to continue
  Serial.begin(9600);
  Serial.write(READY);

  initializeMotor();
}

void initializeMotor() {
  // Wait for the Python watcher to command linearAct to initialize
  while (Serial.read() != INIT) {
    Serial.write(WAIT);
    delay(500);
  }
  // Until the limit switch is activated, move the stepper in 1mm increments
  while (digitalRead(7) == HIGH) {
    Serial.write(BUSY);
    runMotor(BACKWARD,  1);
  }
  // Motor is now initialized, so tell the Python watcher to continue
  stepper->release();
  Serial.write(READY);
}

void runMotor(char dir, float dist) {
  int nSteps = dist / mmPerStep;
  
  stepper->step(nSteps, dir, DOUBLE);
}

void loop() {

}
