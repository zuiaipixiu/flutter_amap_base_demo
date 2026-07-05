#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_amap_base'
  s.version          = '1.0.0'
  s.summary          = 'A new Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  # s.dependency 'AMapSearch', '~> 7.1.0'
  s.dependency 'AMapNavi'
  s.dependency 'AMapSearch' 
  s.dependency 'AMapFoundation'
  s.dependency 'AMapLocation'
  s.dependency 'MJExtension'
  s.dependency 'Masonry'
  s.dependency 'NudeIn'

  s.static_framework = true

  s.ios.deployment_target = '8.0'
end

