Pod::Spec.new do |spec|

  spec.name         = "STAllBase"
  spec.version      = "0.0.1"
  spec.summary      = "STAllBase 说明."
  spec.description      = <<-DESC
  STAllBase long description of the pod here.
  DESC

  spec.homepage         = 'http://github.com/coder/STAllBase'
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  spec.author             = { "coder" => "123@gmail.com" }
  spec.ios.deployment_target = '9.0'

  spec.source       = { :git => "http://github/coder/STAllBase.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source_files = 'STAllBase/{Public,Private}/**/*.{h,m,mm,c,cpp,swift}'
  # spec.exclude_files = "STAllBase/Exclude" #排除文件

  spec.project_header_files = 'STAllBase/Private/**/*.{h}'
  spec.public_header_files = 'STAllBase/Public/**/*.h' #此处放置组件的对外暴漏的头文件

  # ――― binary framework/lib ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #spec.vendored_frameworks = 'STAllBase/Private/**/*.framework'
  #spec.vendored_libraries = 'STAllBase/Private/**/*.a'

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # 放置 json,font,jpg,png等资源
  #  spec.resources = ["STAllBase/{Public,Private}/**/*.{xib}"]
  #  spec.resource_bundles = {
  #    'STAllBase' => ['STAllBase/Assets/*.xcassets', "STAllBase/{Public,Private}/**/*.{png,jpg,font,json}"]
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
  spec.dependency "Then"
  spec.dependency 'SnapKit'
  spec.dependency 'Then'
  spec.dependency 'Toast-Swift'
  spec.dependency 'RxSwift'
  spec.dependency 'RxCocoa'
  spec.dependency 'RxRelay'
  spec.dependency 'STABaseUI'

#   spec.subspec 'WithLoad' do |ss|
#       ss.source_files = 'YKHawkeye/Src/MethodUseTime/**/*{.h,.m}'
#       ss.pod_target_xcconfig = {
#         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YKHawkeyeWithLoad'
#       }
#       ss.dependency 'YKHawkeye/Core'
#       ss.vendored_frameworks = 'YKHawkeye/Framework/*.framework'
#     end

end
