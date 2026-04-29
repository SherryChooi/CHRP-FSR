// unsigned long previousMillis = 0;
// const unsigned long interval = 10;   

// int numSensors = 1;   // change when no. of fsr changes

// void setup() {
//   Serial.begin(9600);   
// }

// void loop() {
//   unsigned long currentMillis = millis();

//   if (currentMillis - previousMillis >= interval) {
//     previousMillis = currentMillis;

//     for (int i = 0; i < numSensors; i++) {
//       int rawValue = analogRead(A0);   
//       float voltage = rawValue * (5.0 / 1023.0);

//       Serial.print(voltage);
//       // Serial.print(rawValue);

//       if (i < numSensors - 1) {
//         Serial.print(",");
//       }
//     }

//     Serial.println();  
//   }
// }


//Mux control pins

int s0 = 8;

int s1 = 9;

int s2 = 10;

int s3 = 11;



//Mux in "SIG" pin

int SIG_pin = A0;



unsigned long previousMillis = 0;

const unsigned long interval = 200;



void setup() {

  pinMode(s0, OUTPUT);

  pinMode(s1, OUTPUT);

  pinMode(s2, OUTPUT);

  pinMode(s3, OUTPUT);



  // digitalWrite(s0, LOW);

  // digitalWrite(s1, LOW);

  // digitalWrite(s2, LOW);

  // digitalWrite(s3, LOW);

  Serial.begin(9600);

}



int readMux(int channel){

  int controlPin[] = {s0, s1, s2, s3};



  int muxChannel[16][4]={

    {0,0,0,0}, //channel 0

    {1,0,0,0}, //channel 1

    {0,1,0,0}, //channel 2

    {1,1,0,0}, //channel 3

    {0,0,1,0}, //channel 4

    {1,0,1,0}, //channel 5

    {0,1,1,0}, //channel 6

    {1,1,1,0}, //channel 7

    {0,0,0,1}, //channel 8

    {1,0,0,1}, //channel 9

    {0,1,0,1}, //channel 10

    {1,1,0,1}, //channel 11

    {0,0,1,1}, //channel 12

    {1,0,1,1}, //channel 13

    {0,1,1,1}, //channel 14

    {1,1,1,1}  //channel 15

  };



  //loop through the 4 sig

  for(int i = 0; i < 4; i ++){

    digitalWrite(controlPin[i], muxChannel[channel][i]);

  }



  //read the value at the SIG pin

  int val = analogRead(SIG_pin);



  //return the value

  return val;

}



void loop() {

  unsigned long currentMillis = millis();

  int sensor[8];

  float voltage[8];



  if (currentMillis - previousMillis >= interval) {

    previousMillis = currentMillis;



  // Read all 16 channels//Loop through and read all 16 values

  //Reports back Value at channel 6 is: 346

    for(int i = 0; i < 1; i ++){

      sensor[i]=readMux(0);

      voltage[i] = sensor[i] * (5.0 / 1023.0); // Convert to voltage

      Serial.print(voltage[i]); // 3 decimal places

      if (i < 7)

        Serial.print(",");  // only print commas between values

    }

    Serial.println();

  }



 }