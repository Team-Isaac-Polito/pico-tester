#line 1 "C:\\Users\\pasqu\\OneDrive\\Desktop\\Team_ISAAC\\PicoTester\\PicoTester.ino"
#include <Arduino.h>

// Pin configurabili
const int outputPin = 2;      // GPIO che invia 3.3V al pin GND da testare (tramite resistenza)
const int analogReadPin = 26; // ADC che legge la tensione sull'altro lato della resistenza
const int selectPIN1_1= 4;     // GPIO per i segnali select del primo demux
const int selectPIN1_2= 5;
const int selectPIN1_3= 6;
const int selectPIN2_1= 9;     // GPIO per i segnali select del secondo
const int selectPIN2_2= 10;
const int selectPIN2_3= 11;

// Valore soglia (in 0-1023) per distinguere GND collegato da scollegato
const int threshold = 300; // Circa 1V, tarabile, perchè il GND vicino all'alimentazione è soggetto a un valore più alto

// Vettori per l'analisi dei GND
int disconnectedGND[8]; // Array per memorizzare i GND non collegati a nessun altro
int disconnectednumber=0; // Contatore per i GND non collegati
int GNDtotest[7]={0,1,2,3,4,5,6}; // Array per memorizzare quali GND sono ancora da testare
int totestnumber=0; // Contatore per i GND da testare
int precedenttotestnumber=7; // Contatore per i GND da testare calcolato nella precedente iterazione

//Matrice per ottenere i vari possibili gruppi di GND collegati tra loro, nel caso peggiore dove fossero collegati a due a due sarebbero 4 gruppi, di dimensione max 8
int groups[4][8];
int groupnumber=0; // Contatore per il numero di gruppi
int groupdimension=0; // Contatore per la dimensione del gruppo durante l'iterazione
int groupdimensions[4]={0}; // Vettore per le dimensioni dei gruppi durante l'iterazione


#line 30 "C:\\Users\\pasqu\\OneDrive\\Desktop\\Team_ISAAC\\PicoTester\\PicoTester.ino"
void setup();
#line 44 "C:\\Users\\pasqu\\OneDrive\\Desktop\\Team_ISAAC\\PicoTester\\PicoTester.ino"
void loop();
#line 30 "C:\\Users\\pasqu\\OneDrive\\Desktop\\Team_ISAAC\\PicoTester\\PicoTester.ino"
void setup() {
  Serial.begin(9600);

  pinMode(outputPin, OUTPUT);
  pinMode(selectPIN1_1, OUTPUT);
  pinMode(selectPIN1_2, OUTPUT);
  pinMode(selectPIN1_3, OUTPUT);
  pinMode(selectPIN2_1, OUTPUT);
  pinMode(selectPIN2_2, OUTPUT);
  pinMode(selectPIN2_3, OUTPUT);

  digitalWrite(outputPin, HIGH); // Invia 3.3V al GND da testare
}

void loop() {
  i=GNDtotest[0]; // Inizializza i al primo GND da testare
  while (i<=6) { // 6 perchè l'ultimo pin non viene testato come primo perche è gia stato sempre testato come secondo
    digitalWrite(selectPIN1_1, i & 0x01); // Imposta il LSB
    digitalWrite(selectPIN1_2, (i >> 1) & 0x01); // Imposta il secondo bit
    digitalWrite(selectPIN1_3, (i >> 2) & 0x01); // Imposta il MSB

    j=GNDtotest[1]; // Inizializza j al secondo GND da testare
    n=1;
    while (n<=precedenttotestnumber) { // 7 perchè l'ultimo pin non viene testato come primo perche è gia stato sempre testato come secondo
      digitalWrite(selectPIN2_1, j & 0x01); 
      digitalWrite(selectPIN2_2, (j >> 1) & 0x01); 
      digitalWrite(selectPIN2_3, (j >> 2) & 0x01); 

      delay(100); // Attendi un attimo per stabilizzare il segnale

      int analogValue = analogRead(analogReadPin);
      if (analogReadPin < threshold) {
        groupdimension++; // Incrementa di uno
        groups[groupnumber][groupdimension]=j; // Aggiungi il jesimo GND al gruppo in una posizione successiva alla prima per permettere di mettere li l'iesimo a cui risulta collegato
      } else {
        GNDtotest[totestnumber]=j; // GND non collegato, dunque da testare
        totestnumber++; 
      }
      n++;
      j=GNDtotest[n];
    }
    
    groupdimensions[groupnumber]=groupdimension; // Salva la dimensione del gruppo corrente

    if (totestnumber==0) {
      groups[groupnumber][0]=i; // Aggiungi il GND corrente al gruppo
      break; // Esci dal ciclo se non ci sono più GND da testare
    } else if (totestnumber=7-i){ //se l'iesimo è scollegato da tutti gli altri è isolato
      disconnectedGND[disconnectednumber]=i; 
      disconnectednumber++; 
    } else if (totestnumber==1) { //se solo un GND risulta scollegato vuol dire che è isolato da tutti gli altri
      groups[groupnumber][0]=i;
      disconnectedGND[disconnectednumber]=GNDtotest[totestnumber]; 
      disconnectednumber++;
      break; // se era solo uno da testare ed è gia possibile classificarlo si puòuscire
    } else {
      groups[groupnumber][0]=i;
    }
    
    precedenttotestnumber=totestnumber-1; // Salva il numero di GND da testare per la prossima iterazione
    
    if (GNDtotest[0]==0){
      break; // il primo GND da testare non può essere il primo, esci dal ciclo
    } else {
      groupnumber++; // Incrementa il numero del gruppo
      groupdimension=0; // Resetta la dimensione del gruppo per il prossimo ciclo
      totestnumber=0; // Resetta il contatore dei GND da testare
      i=GNDtotest[0]; // Prendi il primo GND da testare
    }
    
  }  
  
  k=0;
  while (groupdimensions[k]=!=0) { // finche la dimensione di un gruppo è diversa da 0 lo si rappresenta
    serial.println("I GND:");
    for (int j=0; j<groupdimensions[k]; j++) {
      serial.print(" ");
      serial.print(groups[k][j]);
    }
    serial.print(" sono collegati tra loro");
    k++;
  }
  serial.println("I GND:");
  for (int j=0; j<disconnectednumber; j++) {
    serial.print(" ");
    serial.print(disconnectedGND[j]);
  }
  serial.print(" sono completamente isolati");

  delay(1000); // Legge ogni secondo
}
