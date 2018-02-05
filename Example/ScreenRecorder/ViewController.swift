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



	func startRecording(with fileName: String, completion: @escaping (Error?, URL?) -> Void) {
		self.viewOverlay.show()
		ScreenRecorder.shared.startRecording(with: fileName, windowsToSkip: [self.viewOverlay.overlayWindow], completion: completion)
	}

	func stopRecording() {

	}
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return ReplayFileCoordinator.allReplays.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "previewCellReuseIdentifier", for: indexPath)
		cell.textLabel?.text = ReplayFileCoordinator.allReplays[indexPath.row].lastPathComponent
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let videoURL = ReplayFileCoordinator.allReplays[indexPath.row]
		let player = AVPlayer(url: videoURL)
		let playerViewController = AVPlayerViewController()
		playerViewController.player = player
		self.present(playerViewController, animated: true) {
			playerViewController.player!.play()
		}
	}
}
