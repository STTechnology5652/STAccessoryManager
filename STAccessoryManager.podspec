Pod::Spec.new do |spec|

  spec.name         = "STAccessoryManager"
  spec.version      = "0.0.1"
  spec.summary      = "STAccessoryManager 说明."
  spec.description      = <<-DESC
  STAccessoryManager long description of the pod here.
  DESC

  spec.homepage         = 'http://github.com/coder/STAccessoryManager'
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  spec.author             = { "coder" => "123@gmail.com" }
  spec.ios.deployment_target = '13.0'

  spec.source       = { :git => "http://github/coder/STAccessoryManager.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source_files = 'STAccessoryManager/{Public,Private}/**/*.{h,m,mm,c,cpp,swift}'
  # spec.exclude_files = "STAccessoryManager/Exclude" #排除文件

  spec.project_header_files = 'STAccessoryManager/Private/**/*.{h}'
  spec.public_header_files = 'STAccessoryManager/Public/**/*.h' #此处放置组件的对外暴漏的头文件

  # ――― binary framework/lib ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #spec.vendored_frameworks = 'STAccessoryManager/Private/**/*.framework'
  #spec.vendored_libraries = 'STAccessoryManager/Private/**/*.a'

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # 放置 json,font,jpg,png等资源
  #  spec.resources = ["STAccessoryManager/{Public,Private}/**/*.{xib}"]
  #  spec.resource_bundles = {
  #    'STAccessoryManager' => ['STAccessoryManager/Assets/*.xcassets', "STAccessoryManager/{Public,Private}/**/*.{png,jpg,font,json}"]
  #  }


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.framework  = "SomeFramework"
   spec.frameworks = "ExternalAccessory"
  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }

  # 其他依赖pod
  # spec.dependency "XXXXXXXX"
   spec.dependency "STLog"

  
#   spec.subspec 'WithLoad' do |ss|
#       ss.source_files = 'YKHawkeye/Src/MethodUseTime/**/*{.h,.m}'
#       ss.pod_target_xcconfig = {
#         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YKHawkeyeWithLoad'
#       }
#       ss.dependency 'YKHawkeye/Core'
#       ss.vendored_frameworks = 'YKHawkeye/Framework/*.framework'
#     end

end
