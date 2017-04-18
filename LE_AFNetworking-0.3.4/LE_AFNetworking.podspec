Pod::Spec.new do |s|
  s.name = "LE_AFNetworking"
  s.version = "0.3.4"
  s.summary = "\u{5728}AFNetworingd\u{7684}\u{57fa}\u{7840}\u{4e0a}\u{505a}\u{7684}\u{8fdb}\u{4e00}\u{6b65}\u{5c01}\u{88c5}"
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"LarryEmerson"=>"larryemerson@163.com"}
  s.homepage = "https://github.com/LarryEmerson/LE_AFNetworking"
  s.libraries = ["sqlite3", "c", "icucore", "z", "stdc++.6.0.9", "xml2"]
  s.requires_arc = true
  s.xcconfig = {"HEADER_SEARCH_PATHS"=>"$(SDKROOT)/usr/include/libxml2"}
  s.source = { :path => '.' }

  s.ios.deployment_target    = '7.0'
  s.ios.vendored_framework   = 'ios/LE_AFNetworking.framework'
end
