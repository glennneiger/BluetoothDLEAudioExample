//
//  MainViewController.swift
//  DLEStreamer
//
//  Created by Mostafa Berg on 22/11/2016.
//  Copyright © 2016 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController, UITextFieldDelegate,CBCentralManagerDelegate, FileStreamerDelegate {

    //MARK: - Properties
    //
    public  var peripheral     : CBPeripheral!
    public  var centralManager : CBCentralManager!
    private var uartController : UARTController!
    private var fileStreamer   : FileStreamer!
    private var trackIndex     : Int = 0
    private var tracks         : [String]!
    
    @IBAction func stopButtonTapped(_ sender: Any) {
        stopButtonTapped()
    }
    @IBAction func playButtonTapped(_ sender: Any) {
        beginStreaming()
    }
    
    @IBAction func previousButtonTapped(_ sender: Any) {
        skipTrackTapped(direction: -1)
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        skipTrackTapped(direction: 1)
    }

    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var packetCountField: UITextField!
    @IBOutlet weak var intervalField: UITextField!
    @IBOutlet weak var bleStreamingIcon: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var streamingProgress: UIProgressView!

    //MARK: - ViewController methods
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager.delegate = self
        centralManager.connect(peripheral, options: nil)
        self.title = peripheral.name!
        packetCountField.returnKeyType = .next
        intervalField.returnKeyType = .done
        
        //Load perdefined tracks and set the first one as the target
        tracks = prepareTrackList()
        trackIndex = 0
        trackTitleLabel.text = "sample_\(trackIndex + 1).bv32"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setBluetoothIconVisible(visible: false)
        self.streamingProgress.setProgress(0, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        //Disconnect when leaving view
        centralManager.cancelPeripheralConnection(peripheral)
        peripheral = nil
    }
    //MARK: - Implementation
    //
    func playButtonTapped() {
        beginStreaming()
    }
    
    func stopButtonTapped() {
        stopStreaming()
    }
    
    func skipTrackTapped(direction : Int) {
        trackIndex = abs((trackIndex + direction) % tracks.count)
        if fileStreamer != nil {
            stopStreaming()
            beginStreaming()
        }
        trackTitleLabel.text = "sample_\(trackIndex + 1).bv32"
    }
    
    func beginStreaming() {
        let resourcePath = tracks[trackIndex]
        fileStreamer = FileStreamer(withFilePath: resourcePath, andDelegate: self)
        let packetCount = UInt64(packetCountField.text!)
        let interval    = Int(intervalField.text!)
        fileStreamer.stream(withChunkSize: packetCount!, andInterval: interval!)
        updateUIToStreamingState()
    }
    
    func stopStreaming() {
        if fileStreamer != nil {
            fileStreamer.close()
            fileStreamer = nil
            updateUIToStoppedState()
        }
    }
    
    func streamChunk(aChunk : Data) {
        uartController.stream(data: aChunk)
    }
    
    //MARK: - CBCentralManagerDelegate
    //
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        uartController = UARTController(withPeripheral: peripheral)
        uartController.discoverUARTService {
            print("Peripheral ready for streaming")
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name)")
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            break
        case .poweredOn:
            break
        case .resetting:
            break
        case .unauthorized:
            break
        case .unknown:
            break
        case .unsupported:
            break
        }
    }

    //MARK: - FileStreamerDelegate
    func didReceiveChunk(data: Data, atOffset offset: UInt64, andTotalSize totalSize: UInt64) {
        streamChunk(aChunk: data)
        print(offset, totalSize)
        let completion = Float(offset) / Float(totalSize)
        self.streamingProgress.setProgress(completion, animated: true)
    }

    func reachedEOF() {
        fileStreamer.close()
        fileStreamer = nil
        updateUIToStoppedState()
        statusLabel.text = "Completed"
        self.streamingProgress.setProgress(0, animated: true)
    }
    
    func updateUIToStreamingState() {
        setBluetoothIconVisible(visible: true)
        playButton.isEnabled       = false
        packetCountField.isEnabled = false
        intervalField.isEnabled    = false
        statusLabel.text = "Streaming"
    }
    
    func updateUIToStoppedState() {
        setBluetoothIconVisible(visible: false)
        playButton.isEnabled       = true
        packetCountField.isEnabled = true
        intervalField.isEnabled    = true
        statusLabel.text = "Stopped"
    }
    
    //MARK: - UITextFieldDelegate
    public func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == packetCountField {
            intervalField.becomeFirstResponder()
        }else if textField == intervalField {
            intervalField.resignFirstResponder()
        }

        return false
    }
    
    //MARK: - Helpers
    func getResorucePath(withResourceName aResourceName: String) -> String? {
        return Bundle.main.path(forResource: aResourceName, ofType: "bv32")
    }
    
    func prepareTrackList() -> [String] {
        var tracks = [String]()
        for i in 1...21 {
            tracks.append(getResorucePath(withResourceName: "sample_\(i)")!)
        }
        return tracks
    }
    
    func setBluetoothIconVisible(visible : Bool) {
        var alphaValue : CGFloat = 0
        if visible == true {
            alphaValue = 1
        }
        UIView.animate(withDuration: 1, animations: {
            self.bleStreamingIcon.alpha = alphaValue
        })
    }
}
