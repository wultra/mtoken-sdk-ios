Pod::Spec.new do |s|
  s.name = 'WultraMobileTokenSDK'
  s.version = '2.4.0'
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
  
  # Source files
  s.source_files = 'WultraMobileTokenSDK/**/*.{swift}'
  
  # Dependencies
  s.dependency 'PowerAuth2', '~> 1.9.5'
  s.dependency 'WultraPowerAuthNetworking', '~> 1.5.1'

end
