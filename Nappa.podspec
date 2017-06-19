Pod::Spec.new do |s|
  s.name         = "Nappa"
  s.version      = "1.0"
  s.summary      = "Swift Networking Framework."
  s.description  = <<-DESC
    Wrapper around URLSession that uses Dependency injection making it easy to test network requests.
  DESC
  s.homepage     = "https://github.com/AlTavares/Nappa"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Alexandre Mantovani Tavares" => "alexandre@live.in" }
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/AlTavares/Nappa.git", :tag => s.version.to_s }
  s.source_files  = "Nappa/**/*"
  s.frameworks  = "Foundation"
  s.dependency 'Result', '~> 3.2'
end
