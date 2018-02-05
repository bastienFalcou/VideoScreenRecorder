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
	@IBOutlet fileprivate var tableView: UITableView!
	@IBOutlet fileprivate var descriptionLabel: UILabel!

	fileprivate let viewOverlay = StopVideoRecordingWindow()

	fileprivate var timer: Timer?
	fileprivate let timerTimeInterval: TimeInterval = 0.1

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.reloadData()

		self.viewOverlay.onStopClick = {
			self.viewOverlay.hide {
				ScreenRecorder.shared.stopRecording()
			}
		}
	}

	override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
		if let event = event, event.subtype == .motionShake {
			self.viewOverlay.show()
			self.timer = Timer.scheduledTimer(timeInterval: self.timerTimeInterval, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)

			ScreenRecorder.shared.startRecording(with: UUID().uuidString, windowsToSkip: [self.viewOverlay.overlayWindow]) { [weak self] error, url in
				DispatchQueue.main.async {
					if let error = error {
						self?.present(error: error)
					}
					self?.timer?.invalidate()
					self?.tableView.reloadData()
					self?.descriptionLabel.text = "Shake your device to start recording..."
				}
			}
		}
	}

	fileprivate func present(error: Error) {
		let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		alertController.addAction(okAction)
		self.present(alertController, animated: true, completion: nil)
	}

	@objc fileprivate func updateTimer() {
		let seconds = TimeInterval(self.descriptionLabel.text ?? "0.0") ?? 0.0
		self.descriptionLabel.text = "\(seconds + self.timerTimeInterval)"
	}

	deinit {
		self.timer?.invalidate()
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
		let player = AVPlayer(url: videoURL)
		let playerViewController = AVPlayerViewController()
		playerViewController.player = player
		self.present(playerViewController, animated: true) {
			playerViewController.player!.play()
		}
	}
}
