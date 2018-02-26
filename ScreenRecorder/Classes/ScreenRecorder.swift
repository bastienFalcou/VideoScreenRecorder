//
//  ScreenRecorder.swift
//  ScreenRecorder
//
//  Created by Bastien Falcou on 1/30/18.
//  Copyright © 2018 Fueled. All rights reserved.
//

import Foundation

public final class ScreenRecorder {
	public static let shared = ScreenRecorder()

	private var completionBlock: ((URL?, Error?) -> Void)?

	public var isRecording: Bool {
		if #available(iOS 11.0, *) {
			return Ios11ScreenRecorder.shared.isRecording
		} else {
			return Ios10ScreenRecorder.shared.isRecording
		}
	}

	public func startRecording(with fileName: String, windowsToSkip: [UIWindow]? = nil, startHandler: (() -> Void)? = nil, completionHandler: @escaping (URL?, Error?) -> Void) {
		self.completionBlock = completionHandler
		if #available(iOS 11.0, *) {
			Ios11ScreenRecorder.shared.startRecording(with: fileName, escapeWindows: windowsToSkip, startHandler: startHandler, completionHandler: completionHandler)
		} else {
			Ios10ScreenRecorder.shared.startRecording(with: fileName, escapeWindows: windowsToSkip, startHandler: startHandler, completionHandler: completionHandler)
		}
	}

	public func stopRecording(handler: ((URL?, Error?) -> Void)? = nil) {
		if #available(iOS 11.0, *) {
			Ios11ScreenRecorder.shared.stopRecording { url, error in
				self.completionBlock?(url, error)
				handler?(url, error)
			}
		} else {
			Ios10ScreenRecorder.shared.stopRecording { url, error in
				self.completionBlock?(url, error)
				handler?(url, error)
			}
		}
	}
}
