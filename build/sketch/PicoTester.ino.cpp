#include <Arduino.h>
#line 1 "C:\\Users\\pasqu\\OneDrive\\Desktop\\Team_ISAAC\\PicoTester\\PicoTester.ino"


// Pin configurabili
const int outputPin = 2;      // GPIO che invia 3.3V al pin GND da testare (tramite resistenza)
const int analogReadPin = 26; // ADC che legge la tensione sull'altro lato della resistenza
const int selectPIN_1= 4;     // GPIO per i segnali select del demux
const int selectPIN_2= 5;
const int selectPIN_3= 6;

// Valore soglia (in 0-1023) per distinguere GND collegato da scollegato
const int threshold = 300; // Circa 1V, tarabile, perchè il GND vicino all'alimentazione è soggetto a un valore più alto

#line 13 "C:\\Users\\pasqu\\OneDrive\\Desktop\\Team_ISAAC\\PicoTester\\PicoTester.ino"
void setup();
#line 24 "C:\\Users\\pasqu\\OneDrive\\Desktop\\Team_ISAAC\\PicoTester\\PicoTester.ino"
void loop();
#line 13 "C:\\Users\\pasqu\\OneDrive\\Desktop\\Team_ISAAC\\PicoTester\\PicoTester.ino"
void setup() {
  Serial.begin(9600);

  pinMode(outputPin, OUTPUT);
  pinMode(selectPIN_1, OUTPUT);
  pinMode(selectPIN_2, OUTPUT);
  pinMode(selectPIN_3, OUTPUT);

  digitalWrite(outputPin, HIGH); // Invia 3.3V al GND da testare
}

void loop() {
  int analogValue = analogRead(analogReadPin);
  float voltage = (analogValue / 1023.0) * 3.3;

  Serial.print("Lettura ADC in tensione: ");
  Serial.print(voltage, 3);
  Serial.print(" V");

  if (analogValue < threshold) {
    Serial.println(" --> GND collegato correttamente");
  } else {
    Serial.println(" --> GND NON collegato!");
  }

  delay(1000); // Legge ogni secondo
}
