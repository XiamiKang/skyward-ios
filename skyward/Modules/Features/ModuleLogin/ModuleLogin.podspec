Pod::Spec.new do |s|
  s.name             = 'ModuleLogin'
  s.version          = '1.0.0'
  s.summary          = 'A lightweight login module for iOS apps'
  s.description      = <<-DESC
  LoginModule provides a complete login and registration flow with customizable UI and routing support.
                       DESC

  s.homepage         = 'http://localhost/ModuleLogin'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :git => 'http://localhost/LoginModule.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'ModuleLogin/Classes/**/*'
  
  s.resource_bundles = {
    'ModuleLogin' => ['ModuleLogin/Assets/*.xcassets']
  }

  # 添加 SnapKit 依赖
  s.dependency 'SnapKit'
  s.dependency 'TXKit'
  s.dependency 'TXRouterKit'
  s.dependency 'SWKit'
  s.dependency 'SWTheme'
  s.dependency 'SWNetwork'
  
  
end
