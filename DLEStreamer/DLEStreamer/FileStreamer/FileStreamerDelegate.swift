//
//  FileStreamerDelegate.swift
//  DLEStreamer
//
//  Created by Mostafa Berg on 30/11/2016.
//  Copyright © 2016 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit

protocol FileStreamerDelegate {
    func didReceiveChunk(data : Data, atOffset : UInt64, andTotalSize : UInt64)
    func reachedEOF()
}
