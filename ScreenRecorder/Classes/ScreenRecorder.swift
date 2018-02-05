//
//  ScreenRecorder.swift
//  ScreenRecorder
//
//  Created by Bastien Falcou on 1/30/18.
//  Copyright © 2018 Fueled. All rights reserved.
//

import Foundation
import AVKit

public final class ScreenRecorder {
	public static let shared = ScreenRecorder()

	private var completionBlock: ((Error?, URL?) -> Void)?

	var isRecording: Bool {
		if #available(iOS 11.0, *) {
			return Ios11ScreenRecorder.shared.isRecording
		} else {
			return Ios10ScreenRecorder.shared.isRecording
		}
	}

	func startRecording(with fileName: String, windowsToSkip: [UIWindow]? = nil, completion: @escaping (Error?, URL?) -> Void) {
		self.completionBlock = completion
		if #available(iOS 11.0, *) {
			Ios11ScreenRecorder.shared.startRecording(with: fileName, escapeWindows: windowsToSkip, recordingHandler: completion)
		} else {
			Ios10ScreenRecorder.shared.startRecording(with: fileName, escapeWindows: windowsToSkip, recordingHandler: completion)
		}
	}

	func stopRecording(handler: ((Error?, URL?) -> Void)? = nil) {
		if #available(iOS 11.0, *) {
			Ios11ScreenRecorder.shared.stopRecording { error, url in
				self.completionBlock?(error, url)
				handler?(error, url)
			}
		} else {
			Ios10ScreenRecorder.shared.stopRecording { error, url in
				self.completionBlock?(error, url)
				handler?(error, url)
			}
		}
	}
}
