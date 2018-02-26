//
//  Ios11ScreenRecorder.swift
//  ScreenRecorder
//
//  Created by Bastien Falcou on 2/2/18.
//  Copyright © 2018 Fueled. All rights reserved.
//
//  Adapted from https://github.com/giridharvc7/ScreenRecord

import UIKit
import AVKit
import ReplayKit

@available(iOS 11.0, *)
internal final class Ios11ScreenRecorder {
	public static let shared = Ios11ScreenRecorder()

	fileprivate(set) var isRecording = false

	fileprivate var currentVideoURL: URL?

	fileprivate var assetWriter: AVAssetWriter!
	fileprivate var videoInput: AVAssetWriterInput!

	func startRecording(with fileName: String, escapeWindows: [UIWindow]? = nil, startHandler: (() -> Void)? = nil, completionHandler: @escaping (URL?, Error?) -> Void) {
		guard !self.isRecording else {
			return completionHandler(nil, ScreenRecorderError.alreadyRecodingVideo)
		}

		self.currentVideoURL = URL(fileURLWithPath: ReplayFileCoordinator.shared.filePath(fileName))
		self.assetWriter = try! AVAssetWriter(outputURL: self.currentVideoURL!, fileType: AVFileType.mp4)

		// The size of the output video has to be a multiple of 16. A 2 pixels green line is going to be seen at the bottom and
		// on the right size of the video otherwise. Following two lines ensure this is respected.
		// Source: https://stackoverflow.com/questions/22883525
		let videoWidth = floor(UIScreen.main.bounds.size.width / 16) * 16
		let videoHeight = floor(UIScreen.main.bounds.size.height / 16) * 16

		let videoOutputSettings: [String: Any] = [
			AVVideoCodecKey: AVVideoCodecType.h264,
			AVVideoWidthKey: videoWidth,
			AVVideoHeightKey: videoHeight
		]

		self.videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
		self.videoInput.expectsMediaDataInRealTime = true
		self.assetWriter.add(self.videoInput)

		RPScreenRecorder.shared().startCapture(handler: { sample, bufferType, error in
			self.isRecording = error == nil

			if let error = error {
				DispatchQueue.main.async {
					completionHandler(nil, error)
				}
				return
			}

			if CMSampleBufferDataIsReady(sample) {
				if self.assetWriter.status == AVAssetWriterStatus.unknown {
					self.assetWriter.startWriting()
					self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
				}

				if self.assetWriter.status == AVAssetWriterStatus.failed {
					print("Error occured, status = \(self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(String(describing: self.assetWriter.error))")
					return
				}

				if bufferType == .video {
					if self.videoInput.isReadyForMoreMediaData {
						self.videoInput.append(sample)
					}
				}
			}
		}, completionHandler: { error in
			self.isRecording = error == nil

			if let error = error {
				DispatchQueue.main.async {
					completionHandler(nil, error)
				}
			} else {
				startHandler?()
			}
		})
	}

	func stopRecording(completion: ((URL?, Error?) -> Void)? = nil) {
		guard self.isRecording else {
			completion?(nil, ScreenRecorderError.noVideoRecordInProgress)
			return
		}
		RPScreenRecorder.shared().stopCapture { error in
			self.isRecording = false
			completion?(self.currentVideoURL, error)
			self.assetWriter.finishWriting {
				print(ReplayFileCoordinator.shared.allReplays)
			}
		}
	}
}
