Pod::Spec.new do |s|
  s.name          = "EasyBleManager"
  s.version       = "1.0.1"
  s.summary       = "iOS蓝牙4.0 for Swift"
  s.description   = "1 蓝牙扫描/超时扫描 2 蓝牙连接/超时连接 3 读取数据/写入数据 "
  s.homepage      = "https://github.com/howard0103/EasyBleManager.git"
  s.license       = "MIT"
  s.author        = { "howard" => "344185723@qq.com" }
  s.platform      = :ios, "8.0"
  s.source        = { :git => "https://github.com/howard0103/EasyBleManager.git", :tag => "#{s.version}" }
  s.source_files  = "Source"
  s.exclude_files = "Classes/Exclude"
end
