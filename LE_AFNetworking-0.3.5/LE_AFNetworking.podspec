Pod::Spec.new do |s|
  s.name = "LE_AFNetworking"
  s.version = "0.3.5"
  s.summary = "\u5728AFNetworingd\u7684\u57FA\u7840\u4E0A\u505A\u7684\u8FDB\u4E00\u6B65\u5C01\u88C5"
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
