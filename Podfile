source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/twilio/cocoapod-specs'
source 'https://github.com/streem/cocoapods'

use_frameworks!

platform :ios, '11.0'

target 'StreemNow' do
  pod 'Streem', '~> 0.12'

end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			# This allows us to build for use in Swift 5.1.2
			#
			# At the moment, we apparently need to include this setting
			# here in our StreemNow Podfile, to be compatible with the
			# build settings used by our SDK itself.
			# Without this setting, symbol-mangling apparently becomes
			# incompatible between the SDK and this project.
			config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
		end
	end
end
