Pod:: Spec.new do |spec|
  spec.platform     = 'ios', '7.0'
  spec.name         = 'WhiteLabel'
  spec.version      = '1.0.0'
  spec.summary      = 'An internal library for Fueled. Generic chat library using web-sockets'
  spec.author = {
    'rhg-fueled' => 'rhg@fueled.co'
  }
  spec.license         = { :type => 'Custom', :text => 'Copyright (C) 2013-2014 Fueled. All Rights Reserved.' }
  spec.homepage        = 'https://github.com/Fueled/whiteLabel-ios'
  spec.source = {
    :git => 'https://github.com/Fueled/whiteLabel-ios.git',
    :tag => '1.0.0'
  }
  spec.ios.deployment_target = '7.0'
  spec.source_files = 'WhiteLabel-Demo/WhiteLabel/*.{h,m}'
  spec.dependency = 'SIOSocket'
  spec.requires_arc     = true
end
