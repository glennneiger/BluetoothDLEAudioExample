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
    @IBAction func clearButtonTapped(_ sender: Any) {
        clearButtonAction()
    }
    @IBOutlet weak var noPeripheralsView: UILabel!
    @IBOutlet weak var scanButton: UIBarButtonItem!
    @IBOutlet weak var peripheralTableView: UITableView!
    
    //MARK: - Scanner implementation
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func clearButtonAction() {
        centralManager.stopScan()
        scanButton.title = "Scan"
        discoveredPeripherals.removeAll()
        peripheralTableView.reloadData()
        updateEmptyPeripheralView()
    }

    func scanButtonTapAction() {
        if centralManager.isScanning {
            centralManager.stopScan()
            scanButton.title = "Scan"
        } else {
            centralManager.scanForPeripherals(withServices: nil/*[CBUUID(string : uartServiceUUIDString)]*/, options: nil)
            scanButton.title = "Stop"
        }
    }
    
    func selectedPeripheral(aPeripheral : CBPeripheral) {
        centralManager.stopScan()
        performSegue(withIdentifier: showMainViewSegueIdentifier, sender: aPeripheral)
    }
    
    //MARK: - UIViewController methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.centralManager.delegate = self
        self.updateStartButtonState(withCentralManager: self.centralManager)
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
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "peripheralCell", for: indexPath)
        let peripheralName = discoveredPeripherals[indexPath.row].name
        if peripheralName != nil {
            tableCell.textLabel?.text = peripheralName!
        }else{
            tableCell.textLabel?.text = "No name"
        }

        return tableCell
    }
    
    //MARK: - CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager){
        self.updateStartButtonState(withCentralManager: central)
    }
    
    func updateStartButtonState(withCentralManager central: CBCentralManager) {
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
        if discoveredPeripherals.contains(peripheral) == false {
            discoveredPeripherals.append(peripheral)
            updateEmptyPeripheralView()
            peripheralTableView.reloadData()
        }
    }
    
    func updateEmptyPeripheralView() {
        if discoveredPeripherals.count > 0 {
            UIView.animate(withDuration: 0.3, animations: {
                self.noPeripheralsView.alpha = 0
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.noPeripheralsView.alpha = 1
            })
        }
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
