//
//  WindowUtil.swift
//  Garage
//
//  Created by Bastien Falcou on 1/30/18.
//  Copyright © 2018 Fueled. All rights reserved.
//
//  Based on https://github.com/giridharvc7/ScreenRecord

import UIKit

internal final class VideoControlsWindow {
	fileprivate var stopButton = UIButton(type: UIButtonType.custom)
	fileprivate var stopButtonColor = UIColor(red: 0.30, green: 0.67, blue: 0.99, alpha: 1.00)

	fileprivate(set) var overlayWindow = UIWindow(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: 30.0))
	var onStopClick: (() -> Void)?

	init() {
		self.setupViews()
	}

	// MARK: - Private
	fileprivate func initViews() {
		self.overlayWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 30))
		self.stopButton = UIButton(type: UIButtonType.custom)
	}

	fileprivate func setupViews() {
		self.initViews()

		self.stopButton.setTitle("Stop Recording", for: .normal)
		self.stopButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
		self.stopButton.backgroundColor = self.stopButtonColor

		self.stopButton.addTarget(self, action: #selector(stopRecording), for: UIControlEvents.touchDown)

		self.stopButton.frame = overlayWindow.frame
		self.overlayWindow.addSubview(self.stopButton)
		self.overlayWindow.windowLevel = CGFloat.greatestFiniteMagnitude
	}

	@objc fileprivate func stopRecording() {
		self.onStopClick?()
	}

	// MARK: - Public
	func show() {
		DispatchQueue.main.async {
			self.stopButton.transform = CGAffineTransform(translationX: 0.0, y: -30.0)
			self.overlayWindow.isHidden = false
			self.overlayWindow.makeKeyAndVisible()
			UIView.animate(withDuration: 0.3) {
				self.stopButton.transform = CGAffineTransform.identity
			}
		}
	}

	func hide(completion: (() -> Void)? = nil) {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.3, animations: {
				self.stopButton.transform = CGAffineTransform(translationX: 0.0, y: -30.0)
			}, completion: { (animated) in
				self.overlayWindow.isHidden = true
				self.stopButton.transform = CGAffineTransform.identity
				completion?()
			})
		}
	}
}
