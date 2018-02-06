//
//  ScreenRecorderError.swift
//  ScreenRecorder
//
//  Created by Bastien Falcou on 2/5/18.
//

import Foundation

enum VideoScreenRecorderError: Error {
	case alreadyRecoding
	case noRecordInProgress
	case creationFailed
}
