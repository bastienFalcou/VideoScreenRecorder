#
# Be sure to run `pod lib lint ScreenRecorder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ScreenRecorder'
  s.version          = '0.1.0'
  s.summary          = 'Record video of your screen and save the file locally.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
ScreenRecorder can record a video of your screen and save the output file locally on any iOS version:
- Record video of your screen on any iOS version
- Save video locally and consult previous videos for further reuse (upload video to server, see video on the phone, etc.)
- Easily create your "stop recording" button that although seen on screen, will not be recorded in the video
                       DESC

  s.homepage         = 'https://github.com/bastien.falcou@hotmail.com/ScreenRecorder'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bastien.falcou@hotmail.com' => 'bastien@fueled.com' }
  s.source           = { :git => 'https://github.com/bastien.falcou@hotmail.com/ScreenRecorder.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.3'

  s.source_files = 'ScreenRecorder/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ScreenRecorder' => ['ScreenRecorder/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
