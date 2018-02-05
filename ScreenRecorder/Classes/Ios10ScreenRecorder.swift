//
//  OldScreenRecorder.swift
//  ScreenRecorder
//
//  Created by Bastien Falcou on 2/1/18.
//  Copyright © 2018 Fueled. All rights reserved.
//
//  Adapted from https://github.com/alskipp/ASScreenRecorder

import UIKit
import AVKit

internal final class Ios10ScreenRecorder {
	public static let shared = Ios10ScreenRecorder()

	fileprivate(set) var isRecording = false

	// if saveURL is nil, video will be saved into camera roll
	// this property can not be changed whilst recording is in progress
	fileprivate var videoURL: URL!

	// windows added to this array will not be recorded by the recorder
	// convenient if there is a window containing the Start/Stop buttons
	// that you do not wish to include in the video
	fileprivate var escapeWindows: [UIWindow] = []

	fileprivate var videoWriter: AVAssetWriter!
	fileprivate var videoWriterInput: AVAssetWriterInput!
	fileprivate var avAdaptor: AVAssetWriterInputPixelBufferAdaptor!
	fileprivate var displayLink: CADisplayLink!
	fileprivate var firstTimeStamp: CFTimeInterval?
	fileprivate var outputBufferPoolAuxAttributes: [Any] = []

	fileprivate var renderQueue: DispatchQueue
	fileprivate var appendPixelBufferQueue: DispatchQueue
	fileprivate var frameRenderingSemaphore: DispatchSemaphore
	fileprivate var pixelAppendSemaphore: DispatchSemaphore

	fileprivate var viewSize: CGSize = UIApplication.shared.keyWindow?.frame.size ?? UIScreen.main.bounds.size
	fileprivate var scale: CGFloat = UIScreen.main.scale

	fileprivate var outputBufferPool: CVPixelBufferPool?

	// MARK: - Public

	func startRecording(with fileName: String, escapeWindows: [UIWindow]? = nil, recordingHandler: @escaping (Error?, URL?) -> Void) {
		guard !self.isRecording else {
			return recordingHandler(ScreenRecorderError.alreadyRecodingVideo, nil)
		}
		self.setupWriter(with: fileName, escapeWindows: escapeWindows, recordingHandler: recordingHandler)
		self.isRecording = self.videoWriter!.status == .writing
		self.displayLink = CADisplayLink(target: self, selector: #selector(writeVideoFrame))
		self.displayLink?.add(to: RunLoop.main, forMode: .commonModes)
	}

	func stopRecording(completion: ((Error?, URL?) -> Void)? = nil) {
		guard self.isRecording else {
			completion?(ScreenRecorderError.noVideoRecordInProgress, nil)
			return
		}
		self.isRecording = false
		self.displayLink?.remove(from: RunLoop.main, forMode: .commonModes)
		self.completeRecordingSession(completion: completion)
	}

	// MARK: - Private

	private init() {
		self.appendPixelBufferQueue = DispatchQueue(label: "ASScreenRecorder.append_queue")
		self.renderQueue = DispatchQueue(label: "ASScreenRecorder.render_queue", qos: .userInitiated)

		self.frameRenderingSemaphore = DispatchSemaphore(value: 1)
		self.pixelAppendSemaphore = DispatchSemaphore(value: 1)

		if UIDevice.current.userInterfaceIdiom == .pad && self.scale > 1 {
			self.scale = 1.0
		}
	}

	fileprivate func setupWriter(with fileName: String, escapeWindows: [UIWindow]? = nil, recordingHandler: @escaping (Error?, URL?) -> Void) {
		let bufferAttributes: [CFString: Any] = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
																						 kCVPixelBufferCGBitmapContextCompatibilityKey: true,
																						 kCVPixelBufferWidthKey: self.viewSize.width * self.scale,
																						 kCVPixelBufferHeightKey: self.viewSize.height * self.scale,
																						 kCVPixelBufferBytesPerRowAlignmentKey: self.viewSize.width * self.scale * 4]

		self.outputBufferPool = nil

		CVPixelBufferPoolCreate(nil, nil, bufferAttributes as CFDictionary, &self.outputBufferPool)

		self.videoURL = URL(fileURLWithPath: ReplayFileCoordinator.shared.filePath(fileName))
		self.escapeWindows = escapeWindows ?? []

		do {
			try self.videoWriter = AVAssetWriter(url: self.videoURL, fileType: AVFileType.mov)
		} catch {
			return recordingHandler(ScreenRecorderError.videoCreationFailed, nil)
		}

		let pixelNumber = self.viewSize.width * self.viewSize.height * self.scale
		let videoCompression = [AVVideoAverageBitRateKey: pixelNumber * 11.4]

		let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecH264,
																				AVVideoWidthKey: Int(self.viewSize.width * self.scale),
																				AVVideoHeightKey: Int(self.viewSize.height * self.scale),
																				AVVideoCompressionPropertiesKey: videoCompression]

		self.videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
		self.videoWriterInput.expectsMediaDataInRealTime = true
		self.videoWriterInput.transform = self.videoTransformForDeviceOrientation

		self.avAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.videoWriterInput, sourcePixelBufferAttributes: nil)

		self.videoWriter.add(self.videoWriterInput)
		self.videoWriter.startWriting()
		self.videoWriter.startSession(atSourceTime: CMTime(seconds: 0.0, preferredTimescale: 1000))
	}

	fileprivate var videoTransformForDeviceOrientation: CGAffineTransform {
		switch UIDevice.current.orientation {
		case .landscapeLeft:
			return CGAffineTransform(rotationAngle: -CGFloat.pi / 2.0)
		case .landscapeRight:
			return CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
		case .portraitUpsideDown:
			return CGAffineTransform(rotationAngle: CGFloat.pi)
		default:
			return .identity
		}
	}

	@objc fileprivate func writeVideoFrame() {
		// throttle the number of frames to prevent meltdown
		// technique gleaned from Brad Larson's answer here: http://stackoverflow.com/a/5956119
		if self.frameRenderingSemaphore.wait(timeout: DispatchTime.now()) != .success {
			return
		}
		self.renderQueue.async {
			if !self.videoWriterInput.isReadyForMoreMediaData {
				return
			}

			if self.firstTimeStamp == nil {
				self.firstTimeStamp = self.displayLink.timestamp
			}
			let elapsed: CFTimeInterval = self.displayLink.timestamp - self.firstTimeStamp!
			let time = CMTimeMakeWithSeconds(elapsed, 1000)

			var unmanagedPixelBuffer: CVPixelBuffer? = nil
			let bitmapContext = self.createPixelBufferAndBitmapContext(pixelBuffer: &unmanagedPixelBuffer)

			// draw each window into the context (other windows include UIKeyboard, UIAlert)
			// FIX: UIKeyboard is currently only rendered correctly in portrait orientation
			DispatchQueue.main.sync {
				UIGraphicsPushContext(bitmapContext)
				for window in UIApplication.shared.windows where !self.escapeWindows.contains(window) {
					window.drawHierarchy(in: CGRect(x: 0.0, y: 0.0, width: window.frame.size.width, height: window.frame.size.height), afterScreenUpdates: false)
				}
				UIGraphicsPopContext()
			}

			// append pixelBuffer on a async dispatch_queue, the next frame is rendered whilst this one appends
			// must not overwhelm the queue with pixelBuffers, therefore:
			// check if _append_pixelBuffer_queue is ready
			// if it’s not ready, release pixelBuffer and bitmapContext
			if self.pixelAppendSemaphore.wait(timeout: DispatchTime.now()) == .success {
				self.appendPixelBufferQueue.async {
					let success = self.avAdaptor.append(unmanagedPixelBuffer!, withPresentationTime: time)
					if !success {
						print("Warning, unable to write buffer to video")
					}
					CVPixelBufferUnlockBaseAddress(unmanagedPixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
					self.pixelAppendSemaphore.signal()
				}
			} else {
				CVPixelBufferUnlockBaseAddress(unmanagedPixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
			}
			self.frameRenderingSemaphore.signal()
		}
	}

	fileprivate func createPixelBufferAndBitmapContext(pixelBuffer: UnsafeMutablePointer<CVPixelBuffer?>) -> CGContext {
		CVPixelBufferPoolCreatePixelBuffer(nil, self.outputBufferPool!, pixelBuffer)
		CVPixelBufferLockBaseAddress(pixelBuffer.pointee!, CVPixelBufferLockFlags(rawValue: 0))

		let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
		let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer.pointee!),
														width: CVPixelBufferGetWidth(pixelBuffer.pointee!),
														height: CVPixelBufferGetHeight(pixelBuffer.pointee!),
														bitsPerComponent: 8,
														bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer.pointee!),
														space: CGColorSpaceCreateDeviceRGB(),
														bitmapInfo: bitmapInfo.rawValue)!

		context.scaleBy(x: self.scale, y: self.scale)
		let flipVertical = CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: -1.0, tx: 0.0, ty: self.viewSize.height)
		context.concatenate(flipVertical)

		return context
	}

	fileprivate func completeRecordingSession(completion: ((Error?, URL?) -> Void)? = nil) {
		self.renderQueue.async {
			self.appendPixelBufferQueue.async {
				self.videoWriterInput.markAsFinished()
				self.videoWriter.finishWriting {
					self.cleanup()
					DispatchQueue.main.async {
						completion?(nil, self.videoURL)
					}
				}
			}
		}
	}

	fileprivate func cleanup() {
		self.avAdaptor = nil
		self.videoWriterInput = nil
		self.videoWriter = nil
		self.firstTimeStamp = 0.0
		self.outputBufferPoolAuxAttributes.removeAll()
		self.escapeWindows.removeAll()
	}
}
