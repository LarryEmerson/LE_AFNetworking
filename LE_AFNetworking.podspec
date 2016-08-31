Pod::Spec.new do |s|
s.name             = 'LE_AFNetworking'
s.version          = '0.2.8'
s.summary          = '在AFNetworingd的基础上做的进一步封装'

s.homepage         = 'https://github.com/LarryEmerson/LE_AFNetworking'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'LarryEmerson' => 'larryemerson@163.com' }
s.source           = { :git => 'https://github.com/LarryEmerson/LE_AFNetworking.git', :tag => s.version.to_s }
# s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

s.ios.deployment_target = '7.0'

s.source_files = "LE_AFNetworking/Classes/*.{h,m}"

# s.resource_bundles = {
#   'LE_AFNetworking' => ['LE_AFNetworking/Assets/*.png']
# }

# s.public_header_files = 'Pod/Classes/**/*.h'
s.requires_arc = true
#s.frameworks = 'UIKit', 'MapKit', 'AssetsLibrary', 'JavaScriptCore', 'CoreTelephony', 'CFNetwork'
s.libraries = "sqlite3", "c", "icucore", "z", "stdc++.6.0.9", "xml2"

s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
s.dependency "AFNetworking", "~> 3"
#s.dependency "Qiniu"
s.dependency "LEFrameworks"
s.dependency "FMDB"
end
