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
  
  # 包含所有源文件（包括 .h 和 .m）
  s.source_files = 'ModulePersonal/Classes/**/*.{h,m,swift}'
  
  # 资源文件
  s.resource_bundles = {
    'ModulePersonal' => ['ModulePersonal/Assets/*.xcassets']
  }
  
  # 依赖框架
  s.frameworks = 'UIKit', 'CoreBluetooth'
  
  # 其他依赖
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
