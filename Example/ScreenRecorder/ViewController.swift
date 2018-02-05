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

	fileprivate let viewOverlay = VideoControlsWindow()

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
			ScreenRecorder.shared.startRecording(with: UUID().uuidString, windowsToSkip: [self.viewOverlay.overlayWindow]) { [weak self] error, url in
				DispatchQueue.main.async {
					self?.tableView.reloadData()
				}
			}
		}
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
