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
    @IBAction func scanningButtonTapped(_ sender: Any) {
        scanButtonTapAction()
    }

    @IBOutlet weak var scanningButton: UIButton!
    @IBOutlet weak var peripheralTableView: UITableView!
    
    //MARK: - Scanner implementation
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scanButtonTapAction() {
        if centralManager.isScanning {
            centralManager.stopScan()
            scanningButton.setTitle("Scan", for: .normal)
        }else{
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            scanningButton.setTitle("Stop", for: .normal)
        }
    }
    
    func selectedPeripheral(aPeripheral : CBPeripheral) {
        performSegue(withIdentifier: showMainViewSegueIdentifier, sender: aPeripheral)
    }
    
    //MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanningButton.setTitle("Bletooth Off", for: .disabled)
        scanningButton.isEnabled = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
            scanningButton.isEnabled = true
            
            if centralManager.isScanning {
                scanningButton.setTitle("Stop", for: .normal)
            }else{
                scanningButton.setTitle("Scan", for: .normal)
            }

        }else{
            scanningButton.isEnabled = false
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
