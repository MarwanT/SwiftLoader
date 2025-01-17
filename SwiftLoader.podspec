Pod::Spec.new do |s|
  s.name             = "SwiftLoader"
  s.version          = "0.4.1"
  s.summary          = "A simple and beautiful activity indicator"
  s.description      = <<-DESC
  SwiftLoader is a simple and beautiful activity indicator written in Swift.
                       DESC
  s.homepage         = "https://github.com/Keeward/SwiftLoader"
  s.screenshots      = "https://raw.githubusercontent.com/Keeward/SwiftLoader/master/images/loadergif.gif"
  s.license          = 'MIT'
  s.author           = { "Kirill Kunst" => "kirillkunst@gmail.com" }
  s.source           = { :git => "https://github.com/Keeward/SwiftLoader.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/keeward'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'src/SwiftLoader'
  s.frameworks = 'UIKit'
end
