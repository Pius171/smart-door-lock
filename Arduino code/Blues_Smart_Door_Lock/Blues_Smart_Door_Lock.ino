/*
   The BLE part of this code is based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleScan.cpp
   Ported to Arduino ESP32 by Evandro Copercini

   Author: Pius Onyema Ndukwu
   License: MIT
*/
#include <Arduino.h>
#include <Notecard.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>
#include <BLEServer.h>
#include <LittleFS.h>
#include <ArduinoJson.h>
#include "FS.h"


#define DEBUG 0

#if DEBUG == 0 // chnage to one to enable debugging
#define debug(x) Serial.print(x)
#define debugln(x) Serial.println(x)
#define debugf(x,y) Serial.printf(x,y)

#else
#define debug(x)
#define debugln(x)
#endif


#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

#define productUID "com.gmail.onyemandukwu:smart_door_lock"

BLEScan *pBLEScan;
DynamicJsonDocument UUIDS(10000);
Notecard notecard;

int scanTime = 5; // In seconds
const int LOCK = 13;
const int LED = 16;
const int ATTN_PIN = 23;
const int SDA_PIN = 5;
const int SCL_PIN = 4;


// fucntion declarations
String readFile(String path);
void save(const char *filename, JsonVariant json);
void opendoor(bool isUnlocked, bool bluetoothUnlock = true);
bool validateJson(String input);

class MyCallbacks : public BLECharacteristicCallbacks
{
    void onWrite(BLECharacteristic *pCharacteristic)
    {
      std::string value = pCharacteristic->getValue();

      if (value.length() > 0)
      {
        String data = "";
        debugln("*********");
        debug("New value: ");
        for (int i = 0; i < value.length(); i++)
          data += value[i];
        // debug(value[i]);

        debugln(data);
        debugln();
        debugln("*********");

        // save new device UID
        debugln(data);
        // later write a better code to check if string is json
        if (validateJson(data))
        { // check if input is json
          // Parse the incoming JSON string
          DynamicJsonDocument incomingDoc(1024); // Adjust the size according to your JSON data
          deserializeJson(incomingDoc, data);

          // Merge the incoming JSON into the existing JSON

          for (JsonPair pair : incomingDoc.as<JsonObject>())
          {
            UUIDS[pair.key()] = pair.value();
          }
          serializeJsonPretty(UUIDS, Serial);
          debugln("json deserialized");
          save("/UUIDS.txt", UUIDS); // save UUIDS to file system
        }
      }
    }
};

class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks
{
    void onResult(BLEAdvertisedDevice advertisedDevice)
    {
      debugf("Advertised Device: %s \n", advertisedDevice.toString().c_str());
      // debugln(advertisedDevice.getServiceDataUUID().toString().c_str());
      for (JsonPair pair : UUIDS.as<JsonObject>())
      {
        const char *key = pair.key().c_str();
        const char *value = pair.value().as<const char *>(); // Adjust the type based on your data

        if (advertisedDevice.getServiceUUID().equals(BLEUUID(value)))
        {

          // Calculate the length of the concatenated string
          size_t len = strlen(key) + strlen(value) + 1; // 1 for the null terminator

          // Using dynamically allocated memory
          char *user = (char *)malloc(len);
          if (user != nullptr)
          {
            strcpy(user, key);
            strcat(user, value);

            //log who unlocked the door
            J *req = NoteNewRequest("note.update");
            JAddStringToObject(req, "file", "door_log.dbs");
            JAddStringToObject(req, "note", "doorLog");
            JAddBoolToObject(req, "sync", true);
            J *body = JCreateObject();
            JAddStringToObject(body, user, "unlocked");
            // JAddNumberToObject(body, "temp", 72.22);
            JAddItemToObject(req, "body", body);
            NoteRequest(req);
            free(user); // Remember to free the memory when done

            //update doorstate
            opendoor(true);
          }

          delay(5000);
          opendoor(false);

        }
      }
    }
};

void setup()
{

  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);

  pinMode(LOCK, OUTPUT);
  pinMode(LED, OUTPUT);
  pinMode(ATTN_PIN, INPUT); // I recommend you use a pull down resistor here
  digitalWrite(LOCK, 1); // lock the door
  digitalWrite(LED, 1);


  if (!LittleFS.begin())
  {
    debugln("LittleFS Mount Failed");
    return;
  }

  if (LittleFS.exists("/UUIDS.txt"))
  {
    // if file containing registered
    // UUIDs exist initiate scanning
    String input = readFile("/UUIDS.txt");
    deserializeJson(UUIDS, input);
  }
  else
  {
    debugln("No UUIDS stored. Connect to the device");
  }

  notecard.begin();
  notecard.setDebugOutputStream(Serial);
  J *req = notecard.newRequest("hub.set");
  JAddStringToObject(req, "product", productUID);
  JAddStringToObject(req, "mode", "continuous");
  notecard.sendRequest(req);

  // create door_log file, if it already
  //exists nothing will happen
  req = NoteNewRequest("note.add");
  JAddStringToObject(req, "file", "door_log.dbs");
  JAddStringToObject(req, "note", "doorLog");
  JAddBoolToObject(req, "sync", true);
  J *body = JCreateObject();
  JAddStringToObject(body, "", "");
  JAddItemToObject(req, "body", body);
  NoteRequest(req);

  delay(500);
  //create note
  req = NoteNewRequest("note.add");
  JAddStringToObject(req, "file", "ds.dbs");
  JAddStringToObject(req, "note", "doorState");
  JAddBoolToObject(req, "sync", true);
  body = JCreateObject();
  JAddStringToObject(body, "", "");
  JAddItemToObject(req, "body", body);
  NoteRequest(req);


  delay(500);
  //attach ATTN to our notefile for locking the door
  // so when the file changes, ATTN is fired
  req = NoteNewRequest("card.attn");
  JAddStringToObject(req, "mode", "disarm,-all");
  NoteRequest(req);

  // then arm
  req = NoteNewRequest("card.attn");
  JAddStringToObject(req, "mode", "arm, files");

  J *files = JAddArrayToObject(req, "files");
  JAddItemToArray(files, JCreateString("ds.dbs"));

  NoteRequest(req);


  debugln("Scanning...");

  BLEDevice::init("Door Lock");

  // scanning
  pBLEScan = BLEDevice::getScan(); // create new scan
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  pBLEScan->setActiveScan(true); // active scan uses more power, but get results faster
  pBLEScan->setInterval(100);
  pBLEScan->setWindow(99); // less or equal setInterval value

  // advertsing
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE);
  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->setValue("Door is ready");

  pService->start();
  // BLEAdvertising *pAdvertising = pServer->getAdvertising();  // this still is working for backward compatibility
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  debugln("Characteristic defined! Now you can read it in your phone!");


}

void loop()
{

  if (digitalRead(ATTN_PIN)) {

    debugln("note changed");
    J *req = NoteNewRequest("note.get");
    JAddStringToObject(req, "file", "ds.dbs");
    JAddStringToObject(req, "note", "doorState");
    JAddBoolToObject(req, "sync", true);
    J *rsp = notecard.requestAndResponse(req);
    debugln(JConvertToJSONString(rsp));
    J *body = JGetObject(rsp, "body");
    char *doorState = JGetString(body, "doorState");
    debugln(doorState);

    if (strcmp(doorState, "unlocked") == 0) {
      opendoor(true, false);
      delay(3000);
      opendoor(false, false);

      //turn off ATTN_PIN
      req = NoteNewRequest("card.attn");
      JAddStringToObject(req, "mode", "arm");
      NoteRequest(req);
    }



  }

  else {

    BLEScanResults foundDevices = pBLEScan->start(scanTime, false);
    debug("Devices found: ");
    debugln(foundDevices.getCount());
    debugln("Scan done!");
    pBLEScan->clearResults(); // delete results fromBLEScan buffer to release memory
    delay(2000);
  }


}

void opendoor(bool isUnlocked, bool bluetoothUnlock) {
  digitalWrite(LOCK, !isUnlocked); // unlock the door
  digitalWrite(LED, !isUnlocked);
  if (!bluetoothUnlock) {
    J *req = NoteNewRequest("note.update");
    JAddStringToObject(req, "file", "ds.dbs");
    JAddStringToObject(req, "note", "doorState");
    JAddBoolToObject(req, "sync", true);
    J *body = JCreateObject();
    JAddStringToObject(body, "doorState", isUnlocked ? "unlocked" : "locked");
    JAddItemToObject(req, "body", body);
    NoteRequest(req);

  }
  debugln(isUnlocked ? "door unlocked" : "door locked");
}

String readFile(String path)
{
  String DoC = "";
  debug("Reading file: %s\n");
  debugln(path);

  File file = LittleFS.open(path, "r");
  if (!file)
  {
    debugln("Failed to open file for reading");
    return DoC;
  }

  debug("Read from file: ");
  while (file.available())
  {

    DoC += file.readString();
    debug(DoC);
    // delay(500);
  }
  return DoC;
}

void save(const char *filename, JsonVariant json)
{


  Serial.printf("Writing file: %s\n", filename);

  File file = LittleFS.open(filename, "w");
  Serial.printf("opening file: %s\n", filename);

  size_t n = serializeJson(json, file); // stores the number of characters serialized

  if (n == 0)
  {
    // if no character is serialized
    char buffer[50];
    sprintf(buffer, "Serializing to %s failed", filename);
    debugln(buffer);
    return;
  }
  else
  {
    char buffer[50];
    sprintf(buffer, "Serializing to %s was successful", filename);
    debugln(buffer);


  }
  file.close();
}

// Returns true if input points to a valid JSON string
bool validateJson(String input) {
  StaticJsonDocument<0> doc, filter;
  return deserializeJson(doc, input, DeserializationOption::Filter(filter)) == DeserializationError::Ok;
}
