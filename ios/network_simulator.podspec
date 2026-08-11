#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'network_simulator'
  s.version          = '0.1.0'
  s.summary          = 'Local VPN network condition simulator for Flutter.'
  s.description      = <<-DESC
Real traffic shaping via NEPacketTunnelProvider for Flutter debug builds.
iOS support is experimental and needs device testing.
                       DESC
  s.homepage         = 'https://github.com/Darkmintis/network_simulator'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Darkmintis' => 'https://github.com/Darkmintis' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
