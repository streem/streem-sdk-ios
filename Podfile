source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/twilio/cocoapod-specs'
source 'https://github.com/streem/cocoapods'

use_frameworks!

platform :ios, '11.0'

target 'StreemNow' do
  pod 'StreemKit', '~> 0.17.0'
end

post_install do |installer|
  
  load './Pods/StreemKit/configure_streemkit.rb'
  configure_streemkit(installer)

end
