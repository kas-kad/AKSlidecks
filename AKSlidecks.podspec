Pod::Spec.new do |s|
  s.name         = "AKSlidecks"
  s.version      = "1.0.0"
  s.summary      = "'flat' navigation for hierarchical content"
  s.description  = "AKSlidecks class implements a view controller that manages the 'flat' navigation of hierarchical content. It has a very simple interface similar to UINavigationController and supports swipe gestures to navigate back to the root of navigation stack."
  s.homepage     = "https://github.com/purrrminator/AKSlidecks"
  s.screenshots  = "http://cdn.makeagif.com/media/5-06-2014/dSyk4T.gif"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Andrey Kadochnikov" => "kaskaaddnb@gmail.com" }
  s.social_media_url   = "http://twitter.com/purrrminator"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/purrrminator/AKSlidecks.git", :tag => s.version.to_s }
  s.source_files  = "Classes", "Classes/*.{h,m}"
  s.public_header_files = "Classes/*.h"
  s.resources = "Resources/*.png"
  s.requires_arc = true
end
