import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handgesture/pages/Precisions/precision_pick_page.dart';
import 'package:handgesture/pages/camera/camera_page.dart';
import 'package:handgesture/services/model_inference_service.dart';
import 'package:handgesture/services/service_locator.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool _isConnected = false;
  bool _isConnecting = false;
  double _batteryLevel = 0.75;
  String _currentMode = 'Standard Grip';
  late AnimationController _animationController;

  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;

  final List<Map<String, dynamic>> _gesturePresets = [
    {
      'name': 'Precision Pick',
      'icon': Icons.pan_tool_outlined,
      'color': Colors.blue,
      'description': 'Control Arm with pre-defined positions'
    },
    {
      'name': 'Realtime Gesture',
      'icon': Icons.create_outlined,
      'color': Colors.purple,
      'description': 'Create your own custom gestures'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _enableBluetooth();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (await Permission.bluetoothConnect.isDenied ||
        await Permission.bluetoothScan.isDenied ||
        await Permission.location.isDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Permissions Required"),
          content: const Text(
              "Please grant Bluetooth and location permissions to use this feature."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _enableBluetooth() async {
    bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (!isEnabled!) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
    _discoverDevices();
  }

  Future<void> _discoverDevices() async {
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print("Error discovering devices: $e");
    }

    setState(() {
      _devices = devices;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        _isConnected = true;
        _isConnecting = false;
      });

      // Listen for incoming data
      connection.input!.listen((data) {
        print("Data received: ${String.fromCharCodes(data)}");
      }).onDone(() {
        setState(() {
          _isConnected = false;
        });
      });
    } catch (e) {
      print("Error connecting to device: $e");
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _sendData(String data) async {
    print("Data sent: $data");
    if (_connection != null && _isConnected) {
      _connection!.output.add(Uint8List.fromList(data.codeUnits));
      await _connection!.output.allSent;
      print("Data sent: $data");
    }
  }

  void _showDeviceList() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.bluetooth, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              const Text('Select Device'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No devices found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _devices.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      BluetoothDevice device = _devices[index];
                      bool isConnected =
                          false; // Replace with your connection check logic

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isConnected
                              ? Colors.green[100]
                              : Colors.grey[200],
                          child: Icon(
                            Icons.bluetooth,
                            color:
                                isConnected ? Colors.green : Colors.grey[700],
                          ),
                        ),
                        title: Text(
                          device.name ?? 'Unknown Device',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          device.address,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: isConnected
                            // ignore: dead_code
                            ? Chip(
                                label: const Text('Connected'),
                                backgroundColor: Colors.green[100],
                                labelStyle: const TextStyle(
                                    color: Colors.green, fontSize: 12),
                              )
                            : Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey[400]),
                        onTap: () {
                          Navigator.pop(context);
                          _connectToDevice(device);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('SCAN AGAIN'),
              onPressed: () {
                // Implement your scan logic here
                Navigator.of(context).pop();
                _discoverDevices(); // Call your scan function
              },
            ),
          ],
        );
      },
    );
  }

  void _onTapCamera(BuildContext context) {
    locator<ModelInferenceService>().setModelConfig(2);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return CameraPage(
            index: 2,
            sendData: _sendData,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    if (_connection != null) {
      _connection!.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Prosthetic Control',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  _isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: _isConnected ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  if (!_isConnected) {
                    _showDeviceList();
                  } else {
                    setState(() {
                      _isConnected = false;
                    });
                  }
                  HapticFeedback.mediumImpact();
                  _animationController
                    ..reset()
                    ..forward();
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.purple.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentMode,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _isConnected ? 'Connected' : 'Disconnected',
                                  key: ValueKey<bool>(_isConnected),
                                  style: TextStyle(
                                    color: _isConnected
                                        ? Colors.blue
                                        : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: _batteryLevel),
                            duration: const Duration(milliseconds: 1000),
                            builder: (context, double value, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircularProgressIndicator(
                                      value: value,
                                      backgroundColor:
                                          Colors.grey.withOpacity(0.2),
                                      strokeWidth: 6,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        value > 0.2 ? Colors.blue : Colors.red,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(value * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Gesture Presets Section
                const Text(
                  'Control Modes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _gesturePresets.length,
                  itemBuilder: (context, index) {
                    final preset = _gesturePresets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();

                          if (preset['name'] == 'Precision Pick') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrecisionPickPage(
                                  sendData: _sendData,
                                ),
                              ),
                            );
                          } else {
                            _onTapCamera(context);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: preset['color'].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    preset['icon'],
                                    color: preset['color'],
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preset['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        preset['description'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }
}
