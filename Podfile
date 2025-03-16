platform :ios, '16.0'

target 'QRAvatarApp' do
  use_frameworks!

  # Firebase
  pod 'FirebaseAuth', '~> 10.22.0'
  pod 'FirebaseFirestore', '~> 10.22.0'
  
  # Optional: UI helpers for auth
  pod 'FirebaseUI/Auth', '~> 13.0'
  pod 'FirebaseUI/Email', '~> 13.0'
end

# This post_install hook ensures all pods use the same deployment target as your main project
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Ensure deployment target is at least iOS 16.0
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 16.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      end
      
      # Fix for Xcode 15 warnings about resource bundle signing
      if config.build_settings['CODE_SIGNING_ALLOWED'] == "YES"
        config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
      end
    end
  end
end 