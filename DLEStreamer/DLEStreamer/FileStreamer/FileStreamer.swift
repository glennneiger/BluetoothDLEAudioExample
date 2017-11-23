//
//  FileStreamer.swift
//  DLEStreamer
//
//  Created by Mostafa Berg on 30/11/2016.
//  Copyright © 2016 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit

class FileStreamer: NSObject {

    var fileHandle     : FileHandle!
    var chunkSize      : UInt64 = 0
    var cursorPosition : UInt64 = 0
    var totalSize      : UInt64 = 0
    var buffer         : Data
    var delegate       : FileStreamerDelegate
    var timer          : Timer?

    init?(withFilePath aFilePath : String, andDelegate aDelegate : FileStreamerDelegate) {

        guard let fileHandle = FileHandle(forReadingAtPath: aFilePath) else {
            return nil
        }

        self.delegate       = aDelegate
        self.fileHandle     = fileHandle
        self.chunkSize      = 20
        self.cursorPosition = 0
        self.buffer         = Data(capacity: Int(chunkSize))
        super.init()
    }
    
    public func stream(withChunkSize chunkSize : UInt64, andInterval anInterval : Int) {
        self.chunkSize = chunkSize
        totalSize = UInt64(fileLength())
        timer = Timer.scheduledTimer(timeInterval: Double(anInterval)/1000.0, target: self, selector: #selector(FileStreamer.timerEvent), userInfo: nil, repeats: true)
    }

    @objc func timerEvent() {
        if cursorPosition >= totalSize {
            timer?.invalidate()
            timer = nil
            delegate.reachedEOF()
            return
        }
        
        var data : Data
        let currentPosition = cursorPosition

        if cursorPosition + chunkSize > totalSize {
            let finalChunkSize = totalSize - cursorPosition
            data = readRange(offset: self.cursorPosition, count: finalChunkSize)
            cursorPosition += finalChunkSize
        } else {
            data = readRange(offset: self.cursorPosition, count: chunkSize)
            cursorPosition += UInt64(chunkSize)
        }

        delegate.didReceiveChunk(data: data, atOffset: currentPosition, andTotalSize: totalSize)
    }
    func readRange(offset : UInt64, count : UInt64) -> Data {
        fileHandle.seek(toFileOffset: offset)
        let data = fileHandle.readData(ofLength: Int(count))
        return data
    }
    
    public func rewind() {
        fileHandle.seek(toFileOffset: 0)
        buffer.removeAll()
    }
    
    public func close() {
        timer?.invalidate()
        fileHandle.closeFile()
        fileHandle = nil
        timer = nil
    }
    
    public func fileLength() -> Int {
        return fileHandle.availableData.count
    }
}
