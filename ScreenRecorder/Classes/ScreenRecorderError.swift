//
//  ScreenRecorderError.swift
//  ScreenRecorder
//
//  Created by Bastien Falcou on 2/5/18.
//

import Foundation

enum ScreenRecorderError: Error {
	case alreadyRecodingVideo
	case noVideoRecordInProgress
	case videoCreationFailed
}