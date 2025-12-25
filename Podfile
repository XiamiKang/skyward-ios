# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

# 项目名称
target 'skyward' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # 集成Moya网络请求框架
  pod 'Moya', '~> 15.0'
  # 可选：如果需要Combine支持，可以添加
  pod 'Moya/Combine'
  pod 'lottie-ios'
  pod 'SDWebImage', '~> 5.0'
  
  pod 'CocoaMQTT'
  
  pod 'WCDB.swift'
  
  # 本地模块
#  pod 'TXKit', :path => '../TXKit'
#  pod 'TXRouterKit', :path => '../TXRouterKit'
#  pod 'TXCacheKit', :path => '../TXCacheKit'

  pod 'TXKit', :path => './skyward/Modules/Base/TXKit'
  pod 'TXRouterKit', :path => './skyward/Modules/Base/TXRouterKit'
  pod 'TXCacheKit', :path => './skyward/Modules/Base/TXCacheKit'
  
  pod 'SWKit', :path => './skyward/Modules/Common/SWKit'
  pod 'SWTheme', :path => './skyward/Modules/Common/SWTheme'
  pod 'SWNetwork', :path => './skyward/Modules/Common/SWNetwork'
  
  pod 'ModuleHome', :path => './skyward/Modules/Features/ModuleHome'
  pod 'ModuleMessage', :path => './skyward/Modules/Features/ModuleMessage'
  pod 'ModuleBootstrap', :path => './skyward/Modules/Features/ModuleBootstrap'
  pod 'ModuleLogin', :path => './skyward/Modules/Features/ModuleLogin'
  pod 'ModulePersonal', :path => './skyward/Modules/Features/ModulePersonal'
  pod 'ModuleMap', :path => './skyward/Modules/Features/ModuleMap'
  pod 'ModuleTeam', :path => './skyward/Modules/Features/ModuleTeam'

end

# 确保所有第三方库都使用统一的iOS 13.0部署目标
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
