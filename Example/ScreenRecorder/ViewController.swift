//
//  ViewController.swift
//  ScreenRecorder
//
//  Created by bastien.falcou@hotmail.com on 02/05/2018.
//  Copyright (c) 2018 bastien.falcou@hotmail.com. All rights reserved.
//

import UIKit
import AVKit
import ScreenRecorder

final class ViewController: UIViewController {
	@IBOutlet fileprivate(set) var tableView: UITableView!
	@IBOutlet fileprivate(set) var descriptionLabel: UILabel!

	fileprivate let stopButtonWindow = StopVideoRecordingWindow()

	fileprivate var timer: Timer?
	let timerTimeInterval: TimeInterval = 0.1

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.reloadData()

		// On stop button tapped, the stop button window is hidden and we can stop recording the video.
		// 'stopRecording' can be called with a callback notably returning the URL and error if needed.

		self.stopButtonWindow.onStopClick = {
			VideoScreenRecorder.shared.stopRecording()
			self.stopButtonWindow.hide()
		}
	}

	override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
		if let event = event, event.subtype == .motionShake {

			// Start recording, the framework will internally choose the most appropriate method to record the video. If iOS 11+ will relly on
			// ReplayKit, if prior version will take a batch of screenshots and use them to encode the video.
			//
			// The 'startHandler' callback is called as soon as the Framework has successfully started to record video; for instance right after
			// the user has granted the permission. It may never be called if recording doesn't start successfully.
			//
			// The 'completionHandler' callbak is called if there is an error (possibly immediately upon trying to start recording, e.g. if user
			// denies the permission). It is called when the record completes successfully otherwise.

			VideoScreenRecorder.shared.startRecording(with: UUID().uuidString, windowsToSkip: [self.stopButtonWindow.overlayWindow], startHandler: { [weak self] in
				DispatchQueue.main.async {
					self?.startTimer()
				}
			}, completionHandler: { [weak self] url, error in
				DispatchQueue.main.async {
					if let error = error {
						self?.present(error: error)
					}
					self?.timer?.invalidate()
					self?.tableView.reloadData()
					self?.descriptionLabel.text = "Shake your device to start recording..."
				}
			})
		}
	}

	deinit {
		self.timer?.invalidate()
	}

	fileprivate func present(error: Error) {
		let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		alertController.addAction(okAction)
		self.present(alertController, animated: true, completion: nil)
	}

	fileprivate func startTimer() {
		class WeakTarget: NSObject {
			weak var viewController: ViewController!

			init(viewController: ViewController) {
				self.viewController = viewController
			}

			@objc func updateTimer() {
				let seconds = TimeInterval(self.viewController.descriptionLabel.text ?? "0.0") ?? 0.0
				self.viewController.descriptionLabel.text = "\(seconds + self.viewController.timerTimeInterval)"
			}
		}
		let weakTarget = WeakTarget(viewController: self)
		self.timer = Timer.scheduledTimer(timeInterval: self.timerTimeInterval, target: weakTarget, selector: #selector(WeakTarget.updateTimer), userInfo: nil, repeats: true)
		self.stopButtonWindow.show()
	}
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return ReplayFileCoordinator.shared.allReplays.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "previewCellReuseIdentifier", for: indexPath)
		cell.textLabel?.text = ReplayFileCoordinator.shared.allReplays[indexPath.row].lastPathComponent
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let videoURL = ReplayFileCoordinator.shared.allReplays[indexPath.row]

		// Build and display the video with AVPlayer
		let player = AVPlayer(url: videoURL)
		let playerViewController = AVPlayerViewController()
		playerViewController.player = player
		self.present(playerViewController, animated: true) {
			playerViewController.player!.play()
		}
	}
}
