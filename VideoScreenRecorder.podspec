#
# Be sure to run `pod lib lint ScreenRecorder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VideoScreenRecorder'
  s.version          = '0.1.0'
  s.summary          = 'Record video of your screen and save the file locally 🎥'
  s.homepage         = 'https://github.com/bastienFalcou/VideoScreenRecorder'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bastien.falcou@hotmail.com' => 'bastien@fueled.com' }
  s.source           = { :git => 'https://github.com/bastienFalcou/VideoScreenRecorder.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/BastienFalcou'

  s.description      = <<-DESC
  ScreenRecorder can record a video of your screen and save the output file locally on any iOS version:
  - Record video of your screen on any iOS version
  - Save video locally and consult previous videos for further reuse (upload video to server, see video on the phone, etc.)
  - Easily create your "stop recording" button that although seen on screen, will not be recorded in the video
                       DESC

  s.ios.deployment_target = '8.0'
  s.source_files = 'ScreenRecorder/Classes/**/*'

  # s.screenshots = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
