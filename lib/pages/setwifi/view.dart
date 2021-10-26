import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class SetWifiPage extends GetWidget<ReactiveBleController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('setwifi'),
      ),
      body: Column(
        children: [
          Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: () {
                    controller.startScan([]);
                  },
                  child: Text('开始')),
              ElevatedButton(
                  onPressed: () {
                    controller.stopScan();
                  },
                  child: Text('停止'))
            ],
          ),
          Obx(() {
            return Column(
                children: controller.deviceList.map((element) {
              return ListTile(
                title: Text('${element.name} ${element.rssi.toString()}db'),
                onTap: () {
                  controller.connect(element.id).then((value) => Get.defaultDialog(
                      title: '配置wifi',
                      content: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                                labelText: 'Wifi', prefixIcon: Icon(Icons.network_wifi)),
                          ),
                          TextField(
                            decoration:
                                InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.password)),
                          )
                        ],
                      )));
                },
              );
            }).toList());
          })
        ],
      ),
    );
  }
}
