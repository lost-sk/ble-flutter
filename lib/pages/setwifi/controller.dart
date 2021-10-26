import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';

final Map<String, Uuid> BleUuid = {
  "uuid_service": Uuid.parse('0922'),
  "uuid_wifiSet_notify": Uuid.parse('fad8'),
  "uuid_wifiSet_write": Uuid.parse('fad7'),
  "uuid_SN_notify": Uuid.parse('fae8'),
  "uuid_SN_write": Uuid.parse('fae7'),
  "uuid_wifiState_notify": Uuid.parse('faf8'),
  "uuid_wifiState_write": Uuid.parse('faf7'),
};

class ReactiveBleController extends GetxController {
  final flutterReactiveBle = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanner;
  StreamSubscription<ConnectionStateUpdate>? _connector;
  final netinfo = NetworkInfo();
  String? wifiName;
  var deviceList = <DiscoveredDevice>[].obs;

  @override
  void onInit() async {
    super.onInit();
    wifiName = await netinfo.getWifiName();
    print('ReactiveBleController onInit connectivity:$wifiName');
    startScan([]);
  }

  void startScan(List<Uuid> serviceIds) {
    print('Start ble scan');
    deviceList.clear();
    //_scanner?.value.cancel();
    _scanner = flutterReactiveBle.scanForDevices(withServices: serviceIds).listen(
        (DiscoveredDevice device) {
      //print('device:$device');
      final knownDeviceIndex = deviceList.indexWhere((element) => element.id == device.id);
      if (knownDeviceIndex >= 0) {
        //假如存在 就更新rssi
        deviceList[knownDeviceIndex] = device;
      } else {
        if (device.name == 'KitchenIdea') {
          deviceList.add(device);
        } //只搜索田螺云厨的设备
      }
    }, onError: (e) => print('Device scan fails with error: $e'));
  }

  Future<void> stopScan() async {
    print('stop scan');
    print('devices:$deviceList');
    await _scanner?.cancel();
    //_scanner?.value = null;
  }

  Future<void> connect(String deviceId) async {
    print("start connecting to $deviceId");
    _connector = flutterReactiveBle
        .connectToDevice(id: deviceId, connectionTimeout: Duration(seconds: 3))
        .listen((connectionState) {
      print("ConnectionState for device $deviceId : ${connectionState.connectionState}");
    }, onError: (e) => print("Connecting to device $deviceId resulted in error $e"));
  }

  Future<void> disconnect(String deviceId) async {
    try {
      print("disconnecting to device:$deviceId");
      await _connector?.cancel();
    } catch (e) {
      print('Error disconnecting from a device:$e');
    }
  }
}
