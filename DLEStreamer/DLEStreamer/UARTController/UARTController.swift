//
//  UARTController.swift
//  DLEStreamer
//
//  Created by Mostafa Berg on 29/11/2016.
//  Copyright © 2016 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import CoreBluetooth

let uartServiceUUIDString          = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
let uartTXCharacteristicUUIDString = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
let uartRXCharacteristicUUIDString = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"


class UARTController: NSObject, CBPeripheralDelegate {
    
    //MARK: - Porperties
    private var targetPeripheral  : CBPeripheral!
    private var discoveryCallback : ((Void)->(Void))?
    private var txCharacteristic  : CBCharacteristic?
    private var rxCharacteristic  : CBCharacteristic?

    //MARK: - Implementation
    required public init(withPeripheral aPeripheral : CBPeripheral) {
        super.init()
        targetPeripheral = aPeripheral
        targetPeripheral.delegate = self
    }
    
    public func discoverUARTService(withCompletion : @escaping (Void)->(Void)) {
        discoveryCallback = withCompletion
        targetPeripheral.discoverServices([CBUUID(string: uartServiceUUIDString)])
    }

    public func stream(data : Data) {
        targetPeripheral.writeValue(data, for: rxCharacteristic!, type: .withoutResponse)
    }

    //MARK: - CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for aService in peripheral.services! {
            if aService.uuid.uuidString == uartServiceUUIDString {
                peripheral.discoverCharacteristics(
                    [
                        CBUUID(string:uartTXCharacteristicUUIDString),
                        CBUUID(string:uartRXCharacteristicUUIDString)
                    ], for: aService)
            }else{
                print("Skipping unknown service")
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if service.uuid.uuidString == uartServiceUUIDString {
            for aCharcateristic in service.characteristics! {
                if aCharcateristic.uuid.uuidString == uartRXCharacteristicUUIDString {
                    rxCharacteristic = aCharcateristic
                }
                if aCharcateristic.uuid.uuidString == uartTXCharacteristicUUIDString {
                    txCharacteristic = aCharcateristic
                }
            }
            
            if txCharacteristic != nil && rxCharacteristic != nil {
                peripheral.setNotifyValue(true, for: txCharacteristic!)
            }
        }else{
            print("Skipping charcateristic for unknown service")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print(characteristic.value!)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == txCharacteristic {
            if characteristic.isNotifying == true {
                print("Enabled TX Notifications")
                discoveryCallback?()
            }
        }
    }
}
