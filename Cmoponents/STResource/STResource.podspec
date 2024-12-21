Pod::Spec.new do |spec|

  spec.name         = "STResource"
  spec.version      = "0.0.1"
  spec.summary      = "STResource 说明."
  spec.description      = <<-DESC
  STResource long description of the pod here.
  DESC

  spec.homepage         = 'http://github.com/coder/STResource'
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  spec.author             = { "coder" => "123@gmail.com" }
  spec.ios.deployment_target = '11.0'

  spec.source       = { :git => "http://github/coder/STResource.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source_files = 'STResource/{Public,Private}/**/*.{h,m,mm,c,cpp,swift}'
  # spec.exclude_files = "STResource/Exclude" #排除文件

  spec.project_header_files = 'STResource/Private/**/*.{h}'
  spec.public_header_files = 'STResource/Public/**/*.h' #此处放置组件的对外暴漏的头文件

  # ――― binary framework/lib ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #spec.vendored_frameworks = 'STResource/Private/**/*.framework'
  #spec.vendored_libraries = 'STResource/Private/**/*.a'

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # 放置 json,font,jpg,png等资源
  #  spec.resources = ["STResource/{Public,Private}/**/*.{xib}"]
    spec.resource_bundles = {
      'STResource' => ['STResource/Assets/*.xcassets', 'STResource/Assets/Language/*.lproj', "STResource/{Public,Private}/**/*.{png,jpg,font,json}"]
    }


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
  spec.dependency 'Localize-Swift', '~> 3.2'
  

#   spec.subspec 'WithLoad' do |ss|
#       ss.source_files = 'YKHawkeye/Src/MethodUseTime/**/*{.h,.m}'
#       ss.pod_target_xcconfig = {
#         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YKHawkeyeWithLoad'
#       }
#       ss.dependency 'YKHawkeye/Core'
#       ss.vendored_frameworks = 'YKHawkeye/Framework/*.framework'
#     end

end
