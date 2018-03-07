# VideoScreenRecorder

[![Build Status](https://api.travis-ci.org/bastienFalcou/VideoScreenRecorder.svg?branch=master)](https://travis-ci.org/bastienFalcou/VideoScreenRecorder)
[![Version](https://img.shields.io/cocoapods/v/VideoScreenRecorder.svg?style=flat)](http://cocoapods.org/pods/VideoScreenRecorder)
![Swift 4.0.x](https://img.shields.io/badge/Swift-4.0.x-orange.svg)
[![License](https://img.shields.io/cocoapods/l/VideoScreenRecorder.svg?style=flat)](http://cocoapods.org/pods/VideoScreenRecorder)

VideoScreenRecorder can record a video of your screen and save the output file locally on any iOS version.

## Features

- [x] Record video of your screen _on any iOS version_
- [x] Save video locally and consult previous videos for further reuse (upload video to server, see video on the phone, etc.)
- [x] Easily create your "stop recording" button that although seen on screen, will not be recorded in the video

## Requirements

- iOS 8.0+
- Xcode 9.0+
- Swift 4.0+

## Installation

VideoScreenRecorder is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'VideoScreenRecorder'
```

## Usage

Check out the demo app for an example. It contains the following demos: **record video**, display **persisted list** of previous videos recorded, display **video preview** when selected.

### Start Recording

The `VideoScreenRecorder` singleton manager is the **Framework's central object**. It will handle recording, making sure there are not two videos being recorded simultaneously (returns an error otherwise). Recording a video can be started as follows:

```swift
VideoScreenRecorder.shared.startRecording(with: "my_file_name", windowsToSkip: nil) { url, error in
	DispatchQueue.main.async {
		if let error = error {
			// handle error
		}
		// use url
	}
}
```

The `startHandler` callback is called as soon as the Framework has **successfully started to record video**; for instance right after the user has granted the permission. It may never be called if recording doesn't start successfully.

The `completionHandler` callbak is called if there is an **error** (possibly immediately upon trying to start recording, e.g. if user denies the permission). It is called when the record **completes successfully otherwise**.

> **Note:** it is possible to pass an array of `UIWindow` objects to the `windowsToSkip` parameter. Every object included in this array will not be recorded in the video. This notably allows to create a "Stop Recording" button that only the user will see on screen at the moment of recording.

### Stop Recording

Similarly to `startRecording`, recording the video can be stopped by calling the following function:

```swift
VideoScreenRecorder.shared.stopRecording { url, error in
	DispatchQueue.main.async {
		if let error = error {
			// handle error
		}
		// use url
	}
}
```

The **URL** of the generated video will look as follow: `file:///var/mobile/Containers/Data/Application/{ApplicationUUID}/Documents/Replays/my_file_name.mp4`

## How does it work?

The `VideoScreenRecorder` object is a **Facade** that will pick the most appropriate / advanced approach to handle **screen video recording** based on your **iOS version**.

#### iOS 11+

Apple provides with the [ReplayKit](https://developer.apple.com/documentation/replaykit) Framework. Available since **iOS 9**, it is only with the **iOS 11** update that the Framework was given the ability to save the recorded videos, get their local URL and reuse them later on (for instance to upload them to a server). Before **iOS 11**, the video could only be previwed right after it was recorded—it was lost as soon as the user leaves the preview native screen.

If running on **iOS 11+**, the `VideoScreenRecorder` facade will use [ReplayKit](https://developer.apple.com/documentation/replaykit) to record the video. 

This implementation is based on [Giridhar's](https://medium.com/@giridharvc7/replaykit-screen-recording-8ee9a61dd762) blog post, and its [GitHub repository](https://github.com/giridharvc7/ScreenRecord); see there for more details.

#### Before iOS 11

Since there was no way to capture the a video of the screen before **iOS 11**, one common and accepted solution is to **record a batch of screenshots**, **store them** in an array to finally **encode them** to **generate a video**. 

If running on a version of iOS prior to **iOS 11**, the `VideoScreenRecorder` facade will choose this method to record the video.

This implementation is based on alskipp's [GitHub repository](https://github.com/alskipp/ASVideoScreenRecorder); see there for more details.

## Add Unrecorded Views

It is likely that you will want a "Stop" button that **will be seen on screen** by the user **while recording**, but that **will not be seen on the video** file generated. This is achieved by creating a new `UIWindow` and making it key window.

This window will be passed as parameter of `startRecording(with:windowsToSkip:completion:)` and be skipped while recording the screen. See how to implement it in the **VideoScreenRecorder Example** application, file `StopVideoRecordingWindow` 👌

## License

VideoScreenRecorder is available under the MIT license. See the LICENSE file for more info.
