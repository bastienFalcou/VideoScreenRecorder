# ScreenRecorder

[![CI Status](http://img.shields.io/travis/bastien.falcou@hotmail.com/ScreenRecorder.svg?style=flat)](https://travis-ci.org/bastien.falcou@hotmail.com/ScreenRecorder)
[![Version](https://img.shields.io/cocoapods/v/ScreenRecorder.svg?style=flat)](http://cocoapods.org/pods/ScreenRecorder)
![Swift 3.0.x](https://img.shields.io/badge/Swift-3.0.x-orange.svg)
[![License](https://img.shields.io/cocoapods/l/ScreenRecorder.svg?style=flat)](http://cocoapods.org/pods/ScreenRecorder)

ScreenRecorder can record a video of your screen and save the output file locally on any iOS version.

## Features

- [x] Record video of your screen _on any iOS version_
- [x] Save video locally and consult previous videos for further reuse (upload video to server, see video on the phone, etc.)
- [x] Easily create your "stop recording" button that although seen on screen, will not be recorded in the video

## Requirements

- iOS 8.0+
- Xcode 9.0+
- Swift 4.0+

## Installation

ScreenRecorder is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ScreenRecorder'
```

## Usage

Check out the demo app for an example. It contains the following demos: **record video**, display **persisted list** of previous videos recorded, display **video preview** when selected.

### Start Recording

The `ScreenRecorder` singleton manager is the **Framework's central object**. It will handle recording, making sure there are not two videos being recorded simultaneously (returns an error otherwise). Recording a video can be started as follows:

```swift
ScreenRecorder.shared.startRecording(with: "my_file_name", windowsToSkip: nil) { url, error in
	DispatchQueue.main.async {
		if let error = error {
			// handle error
		}
		print(url.absoluteString)
	}
}
```

The completion **can be called immediately** if an error occurs while starting to record. It might also be **called as soon as there is an error returned**. Finally, it will also be **called when the user stops recording**, passing the URL of the saved file as argument.

> **Note:** it is possible to pass an array of `UIWindow` objects to the `windowsToSkip` parameter. Every object included in this array will not be recorded in the video. This notably allows to create a "Stop Recording" button that only the user will see on screen at the moment of recording.

### Stop Recording

Similarly to `startRecording`, recording the video can be stopped by calling the following function:

```swift
ScreenRecorder.shared.stopRecording { url, error in
	DispatchQueue.main.async {
		if let error = error {
			// handle error
		}
		print(url.absoluteString)
	}
}
```

The completion will be called following the same description as in `startRecording`.

The **URL** of the generated video will look as follow: `file:///var/mobile/Containers/Data/Application/{ApplicationUUID}/Documents/Replays/my_file_name.mp4`

## How does it work?

The `ScreenRecorder` object is a **Facade** that will pick the most appropriate / advanced approach to handle **screen video recording** based on your **iOS version**.

#### iOS 11+

Apple provides with the [ReplayKit](https://developer.apple.com/documentation/replaykit) Framework. Available since **iOS 9**, it is only with the **iOS 11** update that the Framework was given the ability to save the recorded videos, get their local URL and reuse them later on (for instance to upload them to a server). Before **iOS 11**, the video could only be previwed right after it was recorded—it was lost as soon as the user leaves the preview native screen.

If running on **iOS 11+**, the `ScreenRecorder` facade will use [ReplayKit](https://developer.apple.com/documentation/replaykit) to record the video. 

This implementation is based on [Giridhar's](https://medium.com/@giridharvc7/replaykit-screen-recording-8ee9a61dd762) blog post, and its [GitHub repository](https://github.com/giridharvc7/ScreenRecord); see there for more details.

#### Before iOS 11

Since there was no way to capture the a video of the screen before **iOS 11**, one common and accepted solution is to **record a batch of screenshots**, **store them** in an array to finally **encode them** to **generate a video**. 

If running on a version of iOS prior to **iOS 11**, the `ScreenRecorder` facade will choose this method to record the video.

This implementation is based on alskipp's [GitHub repository](https://github.com/alskipp/ASScreenRecorder); see there for more details.

## Add Unrecorded Views

It is likely that you will want a "Stop" button that **will be seen on screen** by the user **while recording**, but that **will not be seen on the video** file generated. This is achieved by creating a new `UIWindow` and making it key window.

This window will be passed as parameter of `startRecording(with:windowsToSkip:completion:)` and be skipped while recording the screen. See how to implement it in the **ScreenRecorder Example** application, file `StopVideoRecordingWindow` 👌

## License

ScreenRecorder is available under the MIT license. See the LICENSE file for more info.
