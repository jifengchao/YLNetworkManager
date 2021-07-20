#
# Be sure to run `pod lib lint YLNetworkManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YLNetworkManager'
  s.version          = '0.1.1'
  s.summary          = 'YLNetworkManager 网络请求二次封装'

  s.description      = 'YLNetworkManager'

  s.homepage         = 'https://github.com/jifengchao/YLNetworkManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jifengchao' => '965524749@qq.com' }

  s.ios.deployment_target = '9.0'

  # s.source           = { :path => '.' }
  s.source           = { :git => 'https://github.com/jifengchao/YLNetworkManager.git', :tag => s.version.to_s }
  # s.source_files = "YLNetworkManager/YBNetworkDefine.h","YLNetworkManager/Example/*"
  s.source_files = "YLNetworkManager/**/*","YLNetworkManager/*"

    
  # s.dependency 'AFNetworking','~> 4.0.0'
  # s.dependency 'YYCache','~> 1.0.4'



  s.subspec 'YLNetwork' do |network|
    network.source_files = 'YLNetworkManager/YLNetwork'
    network.dependency 'AFNetworking','~> 4.0.0'
    network.dependency 'YYCache','~> 1.0.4'
  end
  
  s.subspec 'Example' do |example|
    example.source_files = 'YLNetworkManager/Example'
    example.dependency 'YLNetworkManager/YLNetwork'
  end




end
