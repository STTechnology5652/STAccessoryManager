Pod::Spec.new do |spec|

  spec.name         = "STLog"
  spec.version      = "0.0.1"
  spec.summary      = "STLog 说明."
  spec.description      = <<-DESC
  STLog long description of the pod here.
  DESC

  spec.homepage         = 'https://github.com/STTechnology5652/STLog'
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "coder" => "123@gmail.com" }
  spec.ios.deployment_target = '9.0'

  spec.source       = { :git => "https://github.com/STTechnology5652/STLog.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source_files = 'STLog/{Public,Private}/**/*.{h,m,mm,c,cpp,swift}'
  # spec.exclude_files = "STLog/Exclude" #排除文件

  # spec.project_header_files = 'STLog/Private/**/*.{h}'
  spec.public_header_files = 'STLog/Public/**/*.h' #此处放置组件的对外暴漏的头文件

  # ――― binary framework/lib ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #spec.vendored_frameworks = 'STLog/Private/**/*.framework'
  #spec.vendored_libraries = 'STLog/Private/**/*.a'

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # 放置 json,font,jpg,png等资源
  #  spec.resources = ["STLog/{Public,Private}/**/*.{xib}"]
  #  spec.resource_bundles = {
  #    'STLog' => ['STLog/Assets/*.xcassets', "STLog/{Public,Private}/**/*.{png,jpg,font,json}"]
  #  }


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"
  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }

  # 其他依赖pod
  # spec.dependency "XXXXXXXX"

#   spec.subspec 'WithLoad' do |ss|
#       ss.source_files = 'YKHawkeye/Src/MethodUseTime/**/*{.h,.m}'
#       ss.pod_target_xcconfig = {
#         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YKHawkeyeWithLoad'
#       }
#       ss.dependency 'YKHawkeye/Core'
#       ss.vendored_frameworks = 'YKHawkeye/Framework/*.framework'
#     end

end
