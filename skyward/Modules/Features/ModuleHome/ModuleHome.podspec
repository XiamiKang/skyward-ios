#
# Be sure to run `pod lib lint ModuleHome.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ModuleHome'
  s.version          = '0.1.0'
  s.summary          = 'A short description of ModuleHome.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/赵波/ModuleHome'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '赵波' => 'zbo900801@gmail.com' }
  s.source           = { :git => 'https://github.com/赵波/ModuleHome.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '14.0'

  s.source_files = 'ModuleHome/Classes/**/*'
  
  s.resource_bundles = {
    'ModuleHome' => ['ModuleHome/Assets/*.xcassets']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'SnapKit'
  s.dependency 'TXKit'
  s.dependency 'TXRouterKit'
  s.dependency 'SWKit'
  s.dependency 'SWTheme'
  s.dependency 'SWNetwork'
  s.dependency 'ModulePersonal'
  s.dependency 'ModuleMap'
  
end
