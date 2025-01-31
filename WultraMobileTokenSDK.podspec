Pod::Spec.new do |s|
  s.name = 'WultraMobileTokenSDK'
  s.version = '1.12.0'
  # Metadata
  s.license = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.summary = 'High level PowerAuth based library written in swift'
  s.homepage = 'https://github.com/wultra/mtoken-sdk-ios'
  s.social_media_url = 'https://twitter.com/wultra'
  s.author = { 'Wultra s.r.o.' => 'support@wultra.com' }
  s.source = { :git => 'https://github.com/wultra/mtoken-sdk-ios.git', :tag => s.version }
  # Deployment targets
  s.swift_version = '5.9'
  s.ios.deployment_target = '12.0'
  
  # 'Core' subspec
  s.subspec 'Core' do |sub|
    sub.source_files = 'WultraMobileTokenSDK/WultraMobileToken.swift'
    sub.dependency 'WultraMobileTokenSDK/Operations'
    sub.dependency 'WultraMobileTokenSDK/Push'
    sub.dependency 'WultraMobileTokenSDK/Inbox'
  end

  s.default_subspecs = 'Core'
  
  # 'Common' subspec
  s.subspec 'Common' do |sub|
    sub.source_files = 'WultraMobileTokenSDK/Common/**/*.swift'
    sub.dependency 'PowerAuth2', '~> 1.9.2'
    sub.dependency 'WultraPowerAuthNetworking', '~> 1.5.0'
  end
  
  # 'Operations' subspec
  s.subspec 'Operations' do |sub|
    sub.source_files = 'WultraMobileTokenSDK/Operations/**/*.swift'
    sub.dependency 'WultraMobileTokenSDK/Common'
  end
  
  # 'Push' subspec
  s.subspec 'Push' do |sub|
    sub.source_files = 'WultraMobileTokenSDK/Push/**/*.swift'
    sub.dependency 'WultraMobileTokenSDK/Common'
  end

  # 'Inbox' subspec
  s.subspec 'Inbox' do |sub|
    sub.source_files = 'WultraMobileTokenSDK/Inbox/**/*.swift'
    sub.dependency 'WultraMobileTokenSDK/Common'
  end

end
