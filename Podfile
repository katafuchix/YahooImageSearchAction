# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'YahooImageSearchAction' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for YahooImageSearchAction
  pod 'RxCocoa'
  pod 'RxSwift'
  pod 'Action'
  pod 'RxOptional'
  pod 'Kanna'
  pod 'AlamofireImage'
  pod 'MBProgressHUD', '~> 1.2.0'
  pod 'SKPhotoBrowser'
  
  # SDK does not contain 'libarclite' at the path 対策
  post_install do |installer|
    installer.generated_projects.each do |project|
      project.targets.each do |target|
        target.build_configurations.each do |config|
          # iOS 11.0未満のものを一括で11.0に引き上げる
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
        end
      end
    end
  end
end
