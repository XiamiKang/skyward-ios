Pod::Spec.new do |s|
  s.name             = 'ModulePersonal'
  s.version          = '0.1.0'
  s.summary          = 'Personal module for TXTS app'
  s.description      = <<-DESC
  Personal module including device management and profile features.
                       DESC
  s.homepage         = 'http://localhost/ModulePersonal'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'your@email.com' }
  s.source           = { :git => '', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  
  s.source_files = 'ModulePersonal/Classes/**/*'
  
  s.resource_bundles = {
    'ModulePersonal' => ['ModulePersonal/Assets/*.xcassets']
  }
  
  # 依赖框架（根据您的代码可能需要）
  s.frameworks = 'UIKit', 'CoreBluetooth'
  
  # 如果有其他 pod 依赖
  s.dependency 'SnapKit'
  s.dependency 'TXKit'
  s.dependency 'TXRouterKit'
  s.dependency 'SWKit'
  s.dependency 'SWTheme'
  s.dependency 'SWNetwork'
  s.dependency 'lottie-ios'
  s.dependency 'SDWebImage'
  s.dependency 'ModuleLogin'
  
end
