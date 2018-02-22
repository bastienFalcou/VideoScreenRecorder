//
//  WindowUtil.swift
//  Garage
//
//  Created by Bastien Falcou on 1/30/18.
//  Copyright © 2018 Fueled. All rights reserved.
//
//  Based on https://github.com/giridharvc7/ScreenRecord

import UIKit

internal final class StopVideoRecordingWindow {
	fileprivate(set) var overlayWindow = UIWindow()
	fileprivate let stopButton = UIButton()

	var onStopClick: (() -> Void)?

	init() {
		self.stopButton.setTitle("STOP", for: .normal)
		self.stopButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize)
		self.stopButton.backgroundColor = .red
		self.stopButton.frame = CGRect(x: 0.0, y: 0.0, width: 60.0, height: 60.0)

		self.stopButton.layer.cornerRadius = min(self.stopButton.frame.size.height, self.stopButton.frame.size.width) / 2.0
		self.stopButton.clipsToBounds = true

		self.stopButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)

		self.overlayWindow.addSubview(self.stopButton)
		self.overlayWindow.windowLevel = CGFloat.greatestFiniteMagnitude

		self.overlayWindow.backgroundColor = .clear
		self.overlayWindow.frame = CGRect(x: UIScreen.main.bounds.width - 90.0,
																			y: UIScreen.main.bounds.height - 90.0,
																			width: 60.0,
																			height: 60.0)
	}

	@objc fileprivate func stopRecording() {
		self.onStopClick?()
	}

	private func pulse() {
		let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
		pulseAnimation.duration = 0.5
		pulseAnimation.fromValue = 1
		pulseAnimation.toValue = 0.8
		pulseAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		pulseAnimation.autoreverses = true
		pulseAnimation.repeatCount = .greatestFiniteMagnitude
		self.overlayWindow.layer.add(pulseAnimation, forKey: "com.ScreenRecorder.stop.transform.scale")
	}

	func show() {
		DispatchQueue.main.async {
			self.overlayWindow.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
			self.overlayWindow.alpha = 0.0
			self.overlayWindow.isHidden = false
			self.overlayWindow.makeKeyAndVisible()

			UIView.animate(withDuration: 0.15, animations: {
				self.overlayWindow.transform = .identity
				self.overlayWindow.alpha = 1.0
			}, completion: { _ in
				self.pulse()
			})
		}
	}

	func hide(completion: (() -> Void)? = nil) {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.15, animations: {
				self.overlayWindow.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
				self.overlayWindow.alpha = 0.0
			}, completion: { _ in
				self.overlayWindow.isHidden = true
				completion?()
			})
		}
	}
}
