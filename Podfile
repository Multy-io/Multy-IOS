# Uncomment the next line to define a global platform for your project
 platform :ios, '9.0'

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
  pod 'RAMAnimatedTabBarController'
  pod 'Firebase'
  pod 'Firebase/Messaging'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Branch'
  pod 'SwiftyStoreKit'
  pod 'lottie-ios'
  pod 'UPCarouselFlowLayout'
  pod 'SwiftyContacts'
  pod 'UICircularProgressRing'
  pod 'Hash2Pics'
  
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
end
