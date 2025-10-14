#line 1 "C:\\Users\\franc\\Desktop\\isaac\\minions\\pico-tester\\lib\\Display\\src\\Display.cpp"
#include "Display.h"

Display::Display() {
  
}

/*
 * Initialization of the display.
 * Sets basic graphic settings and shows the team's logo.
 */
void Display::begin() {
  display.begin(DISPLAY_ADDR, true);
  display.setRotation(2);
  display.setTextSize(1);
  display.setTextColor(SH110X_WHITE);
  display.clearDisplay();
  display.display();
  showLogo();
}

/**
 * Displays the team's logo.
 */
void Display::showLogo() {
  display.clearDisplay();
  display.drawBitmap(44, 4,  bitmap_logo_isaac, 41, 58, 1);
  display.display();
}






/**
 * Handles display via recorded interrupts. 
 * This function needs to be called as often as possible.
 * If no button is pressed for more than #MENUTIMEOUT automatically returns to the logo.
 */
void Display::handleGUI() {
  bool change = false;

  if(nav > 0) {
    change = true;
    nav--;
    menupos++;
    if (menupos >= NMENUS) menupos = 0;
    else menutime = millis();
  } else if(menupos != 0 && millis() - menutime > (MENUTIMEOUT * 1000)) {
    change = true;
    menupos = 0;
  }

  switch (menupos) {
    case 0:
      if(change) showLogo();
      break;
 
  }
}

/**
 * NAV button ISR.
 */
void Display::navInterrupt() {
  int now = millis();
  if (now - lastnav > DEBOUNCE) {
    nav++;
    lastnav = now;
  }
}


/**
 * OK button ISR.
 */
void Display::okInterrupt() {
  int now = millis();
  if (now - lastok > DEBOUNCE) {
    ok++;
    lastok = now;
  }
}