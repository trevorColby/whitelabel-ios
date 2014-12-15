Pod:: Spec.new do |spec|
  spec.platform     = 'ios', '7.0'
  spec.name         = 'WhiteLabel'
  spec.version      = '1.0.0'
  spec.summary      = 'Generic chat library using web-sockets'
  spec.author = {
    '' => ''
  }
  spec.license          = 'MIT' 
  spec.homepage         = 'https://github.com/Fueled/whiteLabel-ios'
  spec.source = {
    :git => 'https://github.com/Fueled/whiteLabel-ios.git',
    :tag => '1.0.0'
  }
  spec.ios.deployment_target = '7.0'
  spec.source_files = 'WhiteLabel/*.{h,m}'
  spec.requires_arc     = true
end