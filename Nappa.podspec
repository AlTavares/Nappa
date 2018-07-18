Pod::Spec.new do |s|
 s.name = 'Nappa'
 s.version = '2.2.0'
 s.license = { :type => "MIT", :file => "LICENSE" }
 s.summary = 'Wrapper around URLSession that uses Dependency injection making it easy to test network requests.'
 s.homepage = 'https://github.com/AlTavares/Nappa'
 s.social_media_url = 'https://twitter.com/al_tavares'
 s.authors = { "Alexandre Mantovani tavares" => "alexandre@live.in" }
 s.source = { :git => "https://github.com/AlTavares/Nappa.git", :tag => s.version.to_s }
 s.platforms = { :ios => "8.0", :osx => "10.10", :tvos => "9.0", :watchos => "2.0" }
 s.requires_arc = true

 s.default_subspec = "Core"
 s.subspec "Core" do |ss|
     ss.source_files  = "Sources/**/*.swift"
     ss.framework  = "Foundation"
     ss.dependency 'Result', '~> 4.0.0'
 end

end
