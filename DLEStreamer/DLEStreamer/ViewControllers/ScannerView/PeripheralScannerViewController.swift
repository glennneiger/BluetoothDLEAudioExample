//
//  PeripheralScannerViewController.swift
//  DLEStreamer
//
//  Created by Mostafa Berg on 22/11/2016.
//  Copyright © 2016 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import CoreBluetooth

let showMainViewSegueIdentifier = "showMainView"

class PeripheralScannerViewController: UIViewController, CBCentralManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - Properties
    var centralManager : CBCentralManager!
    var discoveredPeripherals = Array<CBPeripheral>()
    
    //MARK: - UI Outlets and actions
    @IBAction func scanButtonTapped(_ sender: Any) {
        scanButtonTapAction()

    }

    @IBOutlet weak var scanButton: UIBarButtonItem!
    @IBOutlet weak var peripheralTableView: UITableView!
    
    //MARK: - Scanner implementation
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scanButtonTapAction() {
        if centralManager.isScanning {
            centralManager.stopScan()
            scanButton.title = "Start"
        }else{
            discoveredPeripherals.removeAll()
            peripheralTableView.reloadData()
            centralManager.scanForPeripherals(withServices: [CBUUID(string : uartServiceUUIDString)], options: nil)
            scanButton.title = "Stop"
        }
    }
    
    func selectedPeripheral(aPeripheral : CBPeripheral) {
        centralManager.stopScan()
        performSegue(withIdentifier: showMainViewSegueIdentifier, sender: aPeripheral)
    }
    
    //MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanButton.title = "Bluetooth Off"
        scanButton.isEnabled = false
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedPeripheral = discoveredPeripherals[indexPath.row]
        self.selectedPeripheral(aPeripheral: selectedPeripheral)
    }
    
    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "peripheralCell")
        let peripheralName = discoveredPeripherals[indexPath.row].name
        if peripheralName != nil {
            tableCell?.textLabel?.text = peripheralName!
        }else{
            tableCell?.textLabel?.text = "No name"
        }
        
        return tableCell!
    }
    
    //MARK: - CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager){
        if central.state == .poweredOn {
            scanButton.isEnabled = true
            
            if centralManager.isScanning {
                scanButton.title = "Stop"
            }else{
                scanButton.title = "Scan"
            }

        }else{
            scanButton.isEnabled = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredPeripherals.append(peripheral)
        peripheralTableView.reloadData()
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showMainViewSegueIdentifier {
            let mainView = segue.destination as? MainViewController
            //Forward the current CBCentralManager and CBperiphral
            //To the main view for further handling
            mainView?.peripheral     = sender as? CBPeripheral
            mainView?.centralManager = centralManager
        }
    }
}
