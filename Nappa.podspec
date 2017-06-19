Pod::Spec.new do |s|
  s.name         = "Nappa"
  s.version      = "1.0"
  s.summary      = ""
  s.description  = <<-DESC
    Swift Networking Framework.
  DESC
  s.homepage     = ""
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Alexandre Mantovani Tavares" => "alexandre@live.in" }
  s.social_media_url   = ""
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => ".git", :tag => s.version.to_s }
  s.source_files  = "Nappa/**/*"
  s.frameworks  = "Foundation"
  s.dependency = 'Result', '~> 3.2'
end
