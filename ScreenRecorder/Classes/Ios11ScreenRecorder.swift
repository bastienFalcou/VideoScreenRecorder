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

	func startRecording(with fileName: String, escapeWindows: [UIWindow]? = nil, recordingHandler: @escaping (Error?, URL?) -> Void) {
		guard !self.isRecording else {
			return recordingHandler(ScreenRecorderError.alreadyRecodingVideo, nil)
		}

		self.currentVideoURL = URL(fileURLWithPath: ReplayFileCoordinator.filePath(fileName))
		self.assetWriter = try! AVAssetWriter(outputURL: self.currentVideoURL!, fileType: AVFileType.mp4)
		let videoOutputSettings: [String: Any] = [
			AVVideoCodecKey: AVVideoCodecType.h264,
			AVVideoWidthKey: UIScreen.main.bounds.size.width,
			AVVideoHeightKey: UIScreen.main.bounds.size.height
		]

		self.videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
		self.videoInput.expectsMediaDataInRealTime = true
		self.assetWriter.add(self.videoInput)

		RPScreenRecorder.shared().startCapture(handler: { sample, bufferType, error in
			self.isRecording = error == nil

			if let error = error {
				DispatchQueue.main.async {
					recordingHandler(error, nil)
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
					recordingHandler(error, nil)
				}
			}
		})
	}

	func stopRecording(completion: ((Error?, URL?) -> Void)? = nil) {
		guard self.isRecording else {
			completion?(ScreenRecorderError.noVideoRecordInProgress, nil)
			return
		}
		RPScreenRecorder.shared().stopCapture { error in
			self.isRecording = false
			completion?(error, self.currentVideoURL)
			self.assetWriter.finishWriting {
				print(ReplayFileCoordinator.fetchAllReplays())
			}
		}
	}
}
