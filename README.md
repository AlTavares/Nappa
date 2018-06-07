## Nappa

[![Platforms](https://img.shields.io/cocoapods/p/Nappa.svg)](https://cocoapods.org/pods/Nappa)
[![License](https://img.shields.io/cocoapods/l/Nappa.svg)](https://raw.githubusercontent.com/AlTavares/Nappa/master/LICENSE)

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/Nappa.svg)](https://cocoapods.org/pods/Nappa)

[![Travis](https://img.shields.io/travis/AlTavares/Nappa/master.svg)](https://travis-ci.org/AlTavares/Nappa/branches)
[![JetpackSwift](https://img.shields.io/badge/JetpackSwift-framework-red.svg)](http://github.com/JetpackSwift/Framework)

Adaptable HTTP client

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Requirements

- iOS 8.0+ / Mac OS X 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 9.0+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate Nappa into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'Nappa', '~> 2.0'
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Nappa into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "AlTavares/Nappa" ~> 2.0
```
### Swift Package Manager

To use Nappa as a [Swift Package Manager](https://swift.org/package-manager/) package just add the following in your Package.swift file.

``` swift
import PackageDescription

let package = Package(
    name: "HelloNappa",
    dependencies: [
        .Package(url: "https://github.com/AlTavares/Nappa.git", "2.0.0")
    ]
)
```

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate Nappa into your project manually.

#### Git Submodules

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

```bash
$ git init
```

- Add Nappa as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

```bash
$ git submodule add https://github.com/AlTavares/Nappa.git
$ git submodule update --init --recursive
```

- Open the new `Nappa` folder, and drag the `Nappa.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `Nappa.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see two different `Nappa.xcodeproj` folders each with two different versions of the `Nappa.framework` nested inside a `Products` folder.

    > It does not matter which `Products` folder you choose from.

- Select the `Nappa.framework`.

- And that's it!

> The `Nappa.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

#### Embeded Binaries

- Download the latest release from https://github.com/AlTavares/Nappa/releases
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- Add the downloaded `Nappa.framework`.
- And that's it!

## Usage

### Basic usage
````swift
        let service = HTTPService()
        service.request(method: .get, url: "https://httpbin.org/get")
            .responseJSON { (jsonResponse) in
                switch jsonResponse.result {
                case .success(let response):
                    // do something with the result
                    print(response)
                case .failure(let error):
                    // do something in case of error
                    print(error)
                }
        }
`````

You can make requests passing those parameters

````swift
        request(method: HTTPMethod, url: String, payload: Encodable, headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil)

        request(method: HTTPMethod, url: String, data: Data, headers: Headers? = nil, parameterEncoding: ParameterEncoding? = nil)

        request(method: HTTPMethod, url: String, headers: Headers? = nil)
````

The `ParameterEncoding` changes how your payload will be encoded, the options are:

    .json -> JSON Encoding
    .form -> Form Data Encoding
    .url  -> URL Encoding, a query string is added to the URL
    .none -> no data

If there's data present and there's no set `ParameterEncoding`, it will be automatically set based on the `HTTPMethod`

If not set on the Headers, the content type is automatically set using the current `ParameterEncoding`

## License

Nappa is released under the MIT license. See [LICENSE](https://github.com/AlTavares/Nappa/blob/master/LICENSE) for details.
