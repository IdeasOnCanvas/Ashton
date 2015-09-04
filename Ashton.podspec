Pod::Spec.new do |s|
  s.name         = "Ashton"
  s.version      = "1.0.0"
  s.summary      = "Converts NSAttributedStrings between AppKit, CoreText, UIKit and HTML."
  s.homepage     = "https://github.com/IdeasOnCanvas/Ashton"

  s.license      = { :type => 'MIT', :file => 'MIT-LICENSE.txt' }
  s.author       = { "Martin Schuerrer" => "martin@schuerrer.org" }

  s.source       = { :git => "https://github.com/IdeasOnCanvas/Ashton.git", :tag => "v#{s.version}" }

  s.ios.deployment_target = '7.0'
  s.ios.frameworks = 'CoreText'
  s.ios.source_files = 'Ashton/*.{h,m}'
  s.ios.exclude_files = 'Ashton/AshtonAppKit.{h,m}'

  s.osx.deployment_target = '10.7'
  s.osx.frameworks = 'CoreText'
  s.osx.source_files = 'Ashton/*.{h,m}'
  s.osx.exclude_files = 'Ashton/AshtonUIKit.{h,m}'
  
  s.watchos.deployment_target = '2.0'
  s.watchos.frameworks = 'CoreText'
  s.watchos.source_files = 'Ashton/*.{h,m}'
  s.watchos.exclude_files = 'Ashton/AshtonAppKit.{h,m}'

  s.requires_arc = true
end
