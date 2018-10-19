# Uncomment the next line to define a global platform for your project
 platform :ios, '10.0'

target 'Multy' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Multy

  pod 'RealmSwift'
  pod 'R.swift'
  pod 'LTMorphingLabel'
  pod 'ZFRippleButton'
  pod 'ButtonProgressBar-iOS'
  pod 'CryptoSwift', '~> 0.9.0'
  pod 'SecurityExtensions'
  pod 'GGLInstanceID'
  pod 'Alamofire'
  pod 'Socket.IO-Client-Swift'
  pod 'RevealingSplashView'
  pod 'RAMAnimatedTabBarController', '~> 3.5.0'
  pod 'Firebase'
  pod 'Firebase/Messaging'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Branch'
  pod 'SwiftyStoreKit'
  pod 'lottie-ios'
  pod 'UPCarouselFlowLayout'
  pod 'SwiftyContacts'
  pod 'UICircularProgressRing', '~> 3.3.2'
  pod 'Hash2Pics'
  
  #dapp
#  pod 'Result'
  pod 'TrustCore', :git=>'https://github.com/TrustWallet/trust-core', :commit=>'b539f0ff5d5fa344ba0b910c09bc9c65cb863660'
  pod 'TrustWeb3Provider', :git=>'https://github.com/TrustWallet/trust-web3-provider', :commit=>'f4e0ebb1b8fa4812637babe85ef975d116543dfd'
  pod 'JSONRPCKit', :git=> 'https://github.com/bricklife/JSONRPCKit.git'
  pod 'StatefulViewController'

  target 'MultyTests' do
      inherit! :search_paths
    
      # Pods for testing
      pod 'Quick'
      pod 'Nimble'
  end
  
  target 'MultyUITests' do
      inherit! :complete
      
      # Pods for testing
      pod 'Quick'
      pod 'Nimble'
      pod 'Firebase'
      
  end
end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
    
    installer.pods_project.targets.each do |target|
        if ['JSONRPCKit'].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '3.0'
            end
        end
#        if ['TrustKeystore'].include? target.name
#            target.build_configurations.each do |config|
#                config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
#            end
#        end
    end
end
