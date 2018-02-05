//
//  ReplayFileUtil.swift
//  ScreenRecorder
//
//  Created by Bastien Falcou on 1/30/18.
//  Copyright © 2018 Fueled. All rights reserved.
//
//  Based on https://github.com/giridharvc7/ScreenRecord

import Foundation

public struct ReplayFileCoordinator {
	static func createReplaysFolder() {
		if let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
			let replayDirectoryPath = documentDirectoryPath.appending("/Replays")
			let fileManager = FileManager.default
			if !fileManager.fileExists(atPath: replayDirectoryPath) {
				do {
					try fileManager.createDirectory(atPath: replayDirectoryPath,
																					withIntermediateDirectories: false,
																					attributes: nil)
				} catch {
					print("Error creating Replays folder in documents dir: \(error)")
				}
			}
		}
	}

	static func filePath(_ fileName: String) -> String {
		self.createReplaysFolder()
		let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory = paths[0] as String
		let filePath = "\(documentsDirectory)/Replays/\(fileName).mp4"
		return filePath
	}

	static func fetchAllReplays() -> [URL] {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		let replayPath = documentsDirectory?.appendingPathComponent("/Replays")
		let directoryContents = try! FileManager.default.contentsOfDirectory(at: replayPath!, includingPropertiesForKeys: nil, options: [])
		return directoryContents
	}
}
