Pod::Spec.new do |s|
  s.name             = 'memory_info'
  s.version          = '0.1.0'
  s.summary          = 'Get device memory and disk information.'
  s.description      = 'Native memory and disk information for Flutter.'
  s.homepage         = 'https://github.com/Persie0/memory_info'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Persie0' => '76871553+Persie0@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
