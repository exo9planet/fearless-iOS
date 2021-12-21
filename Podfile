platform :ios, '11.0'

abstract_target 'fearlessAll' do
  use_frameworks!

  pod 'FearlessUtils', :git => 'https://github.com/soramitsu/fearless-utils-iOS.git', :commit => 'be2d169573d64b9c2a763a4d7b9ee0d64a17d59f'
  pod 'SwiftLint'
  pod 'R.swift', :inhibit_warnings => true
  pod 'SoraKeystore'
  pod 'SoraUI', '~> 1.10.3'
  pod 'IrohaCrypto', :git => 'https://github.com/soramitsu/ios-crypto.git', :commit => 'aff6415db3677878b9c7d2e5c6e951c75c766259'
  pod 'RobinHood', :git => 'https://github.com/soramitsu/robinhood-ios.git', :commit => '11aba7168859849b2a49a72d507ef0edba9965c0'
  pod 'CommonWallet/Core', :git => 'https://github.com/soramitsu/Capital-iOS.git', :commit => 'f75b450881412f0ad82ce4db7c02f7e9f08c22b0'
  pod 'SoraFoundation', '~> 1.0.0'
  pod 'SwiftyBeaver'
  pod 'Starscream', :git => 'https://github.com/ERussel/Starscream.git', :branch => 'feature/without-origin'
  pod 'ReachabilitySwift'
  pod 'SnapKit', '~> 5.0.0'
  pod 'SwiftFormat/CLI', '~> 0.47.13'
  pod 'Sourcery', '~> 1.4'
  pod 'Kingfisher', :inhibit_warnings => true
  pod 'SVGKit', :git => 'https://github.com/SVGKit/SVGKit.git', :tag => '3.0.0'
  pod 'Charts'

  target 'fearlessTests' do
    inherit! :search_paths

    pod 'Cuckoo'
    pod 'FearlessUtils', :git => 'https://github.com/soramitsu/fearless-utils-iOS.git', :commit => 'be2d169573d64b9c2a763a4d7b9ee0d64a17d59f'
    pod 'SoraFoundation', '~> 1.0.0'
    pod 'R.swift', :inhibit_warnings => true
    pod 'FireMock', :inhibit_warnings => true
    pod 'SoraKeystore'
    pod 'IrohaCrypto', :git => 'https://github.com/soramitsu/ios-crypto.git', :commit => 'aff6415db3677878b9c7d2e5c6e951c75c766259'
    pod 'RobinHood', :git => 'https://github.com/soramitsu/robinhood-ios.git', :commit => '11aba7168859849b2a49a72d507ef0edba9965c0'
    pod 'CommonWallet/Core', :git => 'https://github.com/soramitsu/Capital-iOS.git', :commit => 'f75b450881412f0ad82ce4db7c02f7e9f08c22b0'
    pod 'Sourcery', '~> 1.4'

  end

  target 'fearlessIntegrationTests'

  target 'fearless'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
