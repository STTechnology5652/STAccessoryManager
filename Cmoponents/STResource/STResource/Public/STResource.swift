//
//  STResource.swift
//  Pod
//
//  Created by coder on 2024/12/21.
//
// @_exported import XXXXXX //这个是为了对外暴露下层依赖的Pod

import Localize_Swift

public class STResource: NSObject {
    public static func image(_ name: String) -> UIImage? {
        UIImage(named: name)
    }
}

extension STResource {
    public enum STLanguage: String {
        case zh = "zh-Hans"
        case en = "en"
    }
    
    public static func setLanguage(_ lan: STLanguage? = nil) {
        if let lan {
            Localize_Swift.Localize.setCurrentLanguage(lan.rawValue)
        } 
        else {
            let defaultLan = Localize_Swift.Localize.defaultLanguage()
            Localize_Swift.Localize.setCurrentLanguage(defaultLan)
        }
    }
}


fileprivate
extension STResource {
    private static let resoutceBundleName = "STResource"
    static let languageTableName: String = "STLan"
    
    static let cur_bundle = {
        let bundle = Bundle(for: STResource.self)
        let result = bundle
        
        return result
    }()
    
    static let resourceBundle: Bundle = {
        guard let lanPath = cur_bundle.path(forResource: resoutceBundleName, ofType: "bundle"),
        let lanBundle = Bundle(path: lanPath)
        else {
            return Bundle.main
        }
        
        return lanBundle
    }()
}

extension String {
    public var stLocalLized: String {
        return self.localized(using: STResource.languageTableName, in: STResource.resourceBundle)
    }
}

extension UIColor {
    private static func colorWithName(_ name: String, defaultColor: UIColor = .red) -> UIColor {
        if #available(iOS 11.0, *) {
            let result = UIColor(named: name, in: STResource.resourceBundle, compatibleWith: nil)
            
            return result ?? defaultColor
        } else {
            return defaultColor
        }
    }
    
    @objc
    public static var c_1F2937: UIColor {
        colorWithName("c_1F2937")
    }
    
    @objc
    public static var c_333333: UIColor {
        colorWithName("c_333333")
    }
    
    @objc
    public static var c_B45309: UIColor {
        colorWithName("c_B45309")
    }
    
    
    @objc
    public static var c_main: UIColor {
        colorWithName("c_main")
    }
    
    @objc
    public static var c_theme_back: UIColor {
        colorWithName("c_theme_back")
    }
    
    @objc
    public static var c_text: UIColor {
        colorWithName("c_text")
    }
    
    @objc
    public static var c_text_warning: UIColor {
        colorWithName("c_text_warning")
    }
    
}
