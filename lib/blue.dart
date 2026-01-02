// blue.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_ble/universal_ble.dart';

const String SERVICE_UUID = "FFF0"; 
const String WRITE_CHARACTERISTIC_UUID = "FFF1";
const String READ_CHARACTERISTIC_UUID = "FFF2";

// Now requires a device to be passed in
Future<void> connectToDevice(BleDevice device) async {
  await device.connect();

  try {
      // Requesting 512 is safe and common for modern devices
      int negotiatedMtu = await device.requestMtu(512);
      print("Final MTU negotiated: $negotiatedMtu");
      
      // Safety check: You can now send strings up to (negotiatedMtu - 3) characters
    } catch (e) {
      print("MTU Request failed: $e");
    }

  await device.discoverServices();
}

// Pass the device and the text to send
Future<void> sendStringData(BleDevice device, String text) async {
  try {
    Uint8List bytes = Uint8List.fromList(utf8.encode(text));
    BleCharacteristic characteristic = await device.getCharacteristic(
      WRITE_CHARACTERISTIC_UUID,
      service: SERVICE_UUID, 
    );
    await characteristic.write(bytes, withResponse: true);
  } catch (e) {
    print("Error sending: $e");
  }
}


Future<void> subscribeToNotifications(
  BleDevice device, 
  Function(String) onDataReceived,
) async {
  try {
    BleCharacteristic characteristic = await device.getCharacteristic(
      READ_CHARACTERISTIC_UUID,
      service: SERVICE_UUID, 
    );

    // 1. Listen to the stream of bytes
    characteristic.onValueReceived.listen((Uint8List value) {
      String decoded = utf8.decode(value);
      onDataReceived(decoded); // Send the string back to the UI
    });

    // 2. Tell the device to start pushing updates
    await characteristic.notifications.subscribe();
    print("Subscribed to updates from FFF2");
  } catch (e) {
    print("Subscription error: $e");
  }
}