import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

final Map<String, Uuid> BleUuid = {
  "uuid_service": Uuid.parse('0922'),
  "uuid_wifiSet_notify": Uuid.parse('fad8'),
  "uuid_wifiSet_write": Uuid.parse('fad7'),
  "uuid_SN_notify": Uuid.parse('fae8'),
  "uuid_SN_write": Uuid.parse('fae7'),
  "uuid_wifiState_notify": Uuid.parse('faf8'),
  "uuid_wifiState_write": Uuid.parse('faf7'),
};

abstract class ReactiveState<T> {
  Stream<T> get state;
}

/// @description: 蓝牙连接类
/// @param {*}
/// @return {*}
class BleDeviceConnector extends ReactiveState<ConnectionStateUpdate> {
  BleDeviceConnector({required this.ble});
  final FlutterReactiveBle ble;
  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();
  @override
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;

  late StreamSubscription<ConnectionStateUpdate> _connection;

  Future<void> connect(String deviceId) async {
    print("start connecting to $deviceId");
    _connection = ble.connectToDevice(id: deviceId).listen((connectionState) {
      print("ConnectionState for device $deviceId : ${connectionState.connectionState}");
    }, onError: (e) => print("Connecting to device $deviceId resulted in error $e"));
  }

  Future<void> disconnect(String deviceId) async {
    try {
      print("disconnecting to device:$deviceId");
      await _connection.cancel();
    } catch (e) {
      print('Error disconnecting from a device:$e');
    } finally {
      _deviceConnectionController.add(ConnectionStateUpdate(
          deviceId: deviceId, connectionState: DeviceConnectionState.disconnected, failure: null));
    }
  }

  Future<void> dispose() async {
    await _deviceConnectionController.close();
  }
}

class BleScannerState {
  const BleScannerState({
    required this.discoveredDevices,
    required this.scanIsInProgress,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
}

/// @description: 蓝牙扫描类
/// @param {*}
/// @return {*}
class BleScanner extends ReactiveState<BleScannerState> {
  BleScanner({
    required FlutterReactiveBle ble,
  }) : _ble = ble;
  final FlutterReactiveBle _ble;
  final StreamController<BleScannerState> _stateStreamController = StreamController();

  final _devices = <DiscoveredDevice>[];

  StreamSubscription? _subscription;
  @override
  Stream<BleScannerState> get state => _stateStreamController.stream;

  void startScan(List<Uuid> serviceIds) {
    print('Start ble scan');
    _devices.clear();
    _subscription?.cancel();
    _subscription = _ble.scanForDevices(withServices: serviceIds).listen((DiscoveredDevice device) {
      final knownDeviceIndex = _devices.indexWhere((element) => element.id == device.id);
      if (knownDeviceIndex >= 0) {
        //假如存在 就更新rssi
        _devices[knownDeviceIndex] = device;
      } else {
        if (device.name == 'Kitchenidea') _devices.add(device); //只搜索田螺云厨的设备
      }
      _pushState();
    }, onError: (e) => print('Device scan fails with error: $e'));
  }

  void _pushState() {
    _stateStreamController.add(
      BleScannerState(
        discoveredDevices: _devices,
        scanIsInProgress: _subscription != null,
      ),
    );
  }

  Future<void> stopScan() async {
    print('stop scan');
    await _subscription?.cancel();
    _subscription = null;
    _pushState();
  }

  Future<void> dispose() async {
    await _stateStreamController.close();
  }
}

/// @description: 蓝牙状态类
/// @param {*}
/// @return {*}
class BleStatusMonitor extends ReactiveState<BleStatus?> {
  @override
  Stream<BleStatus?> get state => _ble.statusStream;
  BleStatusMonitor(this._ble);
  final FlutterReactiveBle _ble;
}

class BleDeviceInteractor {
  BleDeviceInteractor({
    required Future<List<DiscoveredService>> Function(String deviceId) bleDiscoverServices,
    required Future<List<int>> Function(QualifiedCharacteristic characteristic) readCharacteristic,
    required Future<void> Function(QualifiedCharacteristic characteristic,
            {required List<int> value})
        writeWithResponse,
    required Future<void> Function(QualifiedCharacteristic characteristic,
            {required List<int> value})
        writeWithOutResponse,
    required Stream<List<int>> Function(QualifiedCharacteristic characteristic)
        subscribeToCharacteristic,
  })  : _bleDiscoverServices = bleDiscoverServices,
        _readCharacteristic = readCharacteristic,
        _writeWithResponse = writeWithResponse,
        _writeWithoutResponse = writeWithOutResponse,
        _subScribeToCharacteristic = subscribeToCharacteristic;
  final Future<List<DiscoveredService>> Function(String deviceId) _bleDiscoverServices;

  final Future<List<int>> Function(QualifiedCharacteristic characteristic) _readCharacteristic;

  final Future<void> Function(QualifiedCharacteristic characteristic, {required List<int> value})
      _writeWithResponse;

  final Future<void> Function(QualifiedCharacteristic characteristic, {required List<int> value})
      _writeWithoutResponse;

  final Stream<List<int>> Function(QualifiedCharacteristic characteristic)
      _subScribeToCharacteristic;

  Future<List<DiscoveredService>> discoverServices(String deviceId) async {
    try {
      print('start discovering service for: $deviceId');
      final result = await _bleDiscoverServices(deviceId);
      return result;
    } catch (e) {
      print('Error occured when discovering services: $e');
      rethrow;
    }
  }
}
