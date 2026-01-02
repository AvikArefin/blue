// main.dart / ble_page.dart
import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';
import 'dart:developer' as developer;
import 'blue.dart';

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  // Local state variables (No globals!)
  List<BleDevice> discoveredDevices = [];
  BleDevice? connectedDevice;
  bool isScanning = false;
  String? lastReceivedMessage; // Store only the last received message for UI
  final TextEditingController _controller = TextEditingController();

  void _handleNewData(String data) {
    developer.log('Received BLE data: $data', name: 'BlePage');
    setState(() {
      lastReceivedMessage = data; // Update with the newest message
    });
  }

  @override
  void initState() {
    super.initState();
    // Listen for scan results and update the local list
    UniversalBle.onScanResult = (device) {
      if (!discoveredDevices.any((d) => d.deviceId == device.deviceId)) {
        setState(() {
          discoveredDevices.add(device);
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE")),
      body: Column(
        children: [
          // SCAN BUTTON
          ElevatedButton(
            onPressed: () {
              setState(() {
                discoveredDevices.clear();
                isScanning = true;
              });
              UniversalBle.startScan();
            },
            child: Text(isScanning ? "Scanning..." : "Start Scan"),
          ),

          // DEVICE LIST (Shown if not connected)
          if (connectedDevice == null)
            Expanded(
              child: ListView.builder(
                itemCount: discoveredDevices.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(discoveredDevices[i].name ?? "Unknown"),
                  onTap: () async {
                    await UniversalBle.stopScan();
                    await connectToDevice(discoveredDevices[i]);

                    // START LISTENING IMMEDIATELY
                    await subscribeToNotifications(
                      discoveredDevices[i],
                      _handleNewData,
                    );

                    setState(() {
                      connectedDevice = discoveredDevices[i];
                      isScanning = false;
                    });
                  },
                ),
              ),
            ),

          // SEND SECTION (Shown if connected)
          if (connectedDevice != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Connected to: ${connectedDevice!.name}"),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _controller)),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            // Pass the local state variable to the helper function
                            await sendStringData(
                              connectedDevice!,
                              _controller.text,
                            );
                            _controller.clear();
                          },
                        ),
                      ],
                    ),
                    // At the bottom of your build method's Column:
                    const Divider(),
                    const Text(
                      "Last Received Message:", // Changed text
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: lastReceivedMessage == null
                          ? const Center(child: Text('No messages received yet.'))
                          : SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  lastReceivedMessage!,
                                  maxLines: null,
                                  style: const TextStyle(fontSize: 16.0), // Optional: make text slightly larger
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
