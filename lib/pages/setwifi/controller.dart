import 'package:flutter_ducafecat_news_getx/common/utils/ble.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/state_manager.dart';

class SetWifiController extends GetxController {
  SetWifiController();
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late BleDeviceConnector _connector;
  late BleScanner _scanner;
  late BleStatusMonitor _status;
  @override
  void onInit() {
    super.onInit();
    _connector = BleDeviceConnector(ble: _ble);
    _scanner = BleScanner(ble: _ble);
    _status = BleStatusMonitor(_ble);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void dispose() {
    _scanner.dispose();
    _connector.dispose();
    super.dispose();
  }

  void handlerScan() {
    _scanner.startScan([]);
  }
}
