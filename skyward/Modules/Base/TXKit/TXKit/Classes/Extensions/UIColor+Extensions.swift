
//
//  UIColor+Extensions.swift
//
//
//  Created by hushijun on 2024/4/2.
//  Copyright © 2024年 Longfor. All rights reserved.
//

#if os(macOS)
import Cocoa
typealias Color = NSColor
#else
import UIKit
typealias Color = UIColor
#endif

extension UIColor {
    
    /// 通过16进制的字符串创建UIColor
    ///
    /// - Parameter str: 16进制字符串#xff0c;格式为#ececec
    public convenience init (str: String) {
        let hex = (str as NSString).trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
    /// Constructing from hex value
    ///
    /// - Parameter hex: hex int value, eg: 0xf2f2f2
    /// - Parameter alpha: the alpha value(0-1)
    public convenience init(hex: Int, alpha: CGFloat = 1.0) {
        
        let red = (hex >> 16) & 0xff
        let green = (hex >> 8) & 0xff
        let blue = hex & 0xff
        
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
    
    /// Set alpha value for current color
    ///
    /// - Parameter value: the alpha value(0-1)
    /// - Returns: The alpha adjusted color
    public func alpha(_ value: CGFloat) -> UIColor {
        return withAlphaComponent(value)
    }
    
    /// The shorthand three-digit hexadecimal representation of color.
    /// #RGB defines to the color #RRGGBB.
    ///
    /// - parameter hex3: Three-digit hexadecimal value.
    /// - parameter alpha: 0.0 - 1.0. The default is 1.0.
    public convenience init(hex3: UInt16, alpha: CGFloat = 1) {
        let divisor = CGFloat(15)
        let red     = CGFloat((hex3 & 0xF00) >> 8) / divisor
        let green   = CGFloat((hex3 & 0x0F0) >> 4) / divisor
        let blue    = CGFloat( hex3 & 0x00F      ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// The shorthand four-digit hexadecimal representation of color with alpha.
    /// #RGBA defines to the color #RRGGBBAA.
    ///
    /// - parameter hex4: Four-digit hexadecimal value.
    public convenience init(hex4: UInt16) {
        let divisor = CGFloat(15)
        let red     = CGFloat((hex4 & 0xF000) >> 12) / divisor
        let green   = CGFloat((hex4 & 0x0F00) >>  8) / divisor
        let blue    = CGFloat((hex4 & 0x00F0) >>  4) / divisor
        let alpha   = CGFloat( hex4 & 0x000F       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// The six-digit hexadecimal representation of color of the form #RRGGBB.
    ///
    /// - parameter hex6: Six-digit hexadecimal value.
    public convenience init(hex6: UInt32, alpha: CGFloat = 1) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex6 & 0x0000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// The six-digit hexadecimal representation of color with alpha of the form #RRGGBBAA.
    ///
    /// - parameter hex8: Eight-digit hexadecimal value.
    public convenience init(hex8: UInt32) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex8 & 0xFF000000) >> 24) / divisor
        let green   = CGFloat((hex8 & 0x00FF0000) >> 16) / divisor
        let blue    = CGFloat((hex8 & 0x0000FF00) >>  8) / divisor
        let alpha   = CGFloat( hex8 & 0x000000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// The rgba string representation of color with alpha of the form #RRGGBBAA/#RRGGBB, throws error.
    ///
    /// - parameter rgba: String value.
    public convenience init(rgba_throws rgba: String) throws {
        guard rgba.hasPrefix("#") else {
            let error = UIColorInputError.missingHashMarkAsPrefix(rgba)
            throw error
        }
        
        let hexString: String = String(rgba[String.Index(utf16Offset: 1, in: rgba)...])
        var hexValue:  UInt32 = 0
        
        guard Scanner(string: hexString).scanHexInt32(&hexValue) else {
            let error = UIColorInputError.unableToScanHexValue(rgba)
            throw error
        }
        
        switch (hexString.count) {
        case 3:
            self.init(hex3: UInt16(hexValue))
        case 4:
            self.init(hex4: UInt16(hexValue))
        case 6:
            self.init(hex6: hexValue)
        case 8:
            self.init(hex8: hexValue)
        default:
            let error = UIColorInputError.mismatchedHexStringLength(rgba)
            throw error
        }
    }
    
    /// The rgba string representation of color with alpha of the form #RRGGBBAA/#RRGGBB, fails to default color.
    ///
    /// - parameter rgba: String value.
    #if os(macOS)
    public convenience init?(_ rgba: String, defaultColor: NSColor = NSColor.clear) {
        guard let color = try? Color(rgba_throws: rgba) else {
            self.init(cgColor: defaultColor.cgColor)
            return
        }
        self.init(cgColor: color.cgColor)
    }
    #else
    public convenience init(_ rgba: String, defaultColor: UIColor = UIColor.clear) {
        guard let color = try? UIColor(rgba_throws: rgba) else {
            self.init(cgColor: defaultColor.cgColor)
            return
        }
        self.init(cgColor: color.cgColor)
    }
    #endif
    
    /// Hex string of a UIColor instance, throws error.
    ///
    /// - parameter includeAlpha: Whether the alpha should be included.
    public func hexStringThrows(_ includeAlpha: Bool = true) throws -> String  {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        guard r >= 0 && r <= 1 && g >= 0 && g <= 1 && b >= 0 && b <= 1 else {
            let error = UIColorInputError.unableToOutputHexStringForWideDisplayColor
//            print(error.localizedDescription)
            throw error
        }
        
        if (includeAlpha) {
            return String(format: "#%02X%02X%02X%02X",
                          Int(round(r * 255)), Int(round(g * 255)),
                          Int(round(b * 255)), Int(round(a * 255)))
        } else {
            return String(format: "#%02X%02X%02X", Int(round(r * 255)),
                          Int(round(g * 255)), Int(round(b * 255)))
        }
    }
    
    /// Hex string of a UIColor instance, fails to empty string.
    ///
    ///  - parameter includeAlpha: Whether the alpha should be included.
    public func hexString(_ includeAlpha: Bool = true) -> String  {
        guard let hexString = try? hexStringThrows(includeAlpha) else {
            return ""
        }
        return hexString
    }
    
}


// MARK: -

extension UIColor {
    
    public func hex(hashPrefix: Bool = true) -> String {
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 0.0, 0.0)
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let prefix = hashPrefix ? "#" : ""
        
        return String(format: "\(prefix)%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    
    internal func rgbComponents() -> [CGFloat] {
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 0.0, 0.0)
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return [r, g, b]
    }
    
    public var isDark: Bool {
        let RGB = rgbComponents()
        return (0.2126 * RGB[0] + 0.7152 * RGB[1] + 0.0722 * RGB[2]) < 0.5
    }
    
    public var isBlackOrWhite: Bool {
        let RGB = rgbComponents()
        return (RGB[0] > 0.91 && RGB[1] > 0.91 && RGB[2] > 0.91) || (RGB[0] < 0.09 && RGB[1] < 0.09 && RGB[2] < 0.09)
    }
    
    public var isBlack: Bool {
        let RGB = rgbComponents()
        return (RGB[0] < 0.09 && RGB[1] < 0.09 && RGB[2] < 0.09)
    }
    
    public var isWhite: Bool {
        let RGB = rgbComponents()
        return (RGB[0] > 0.91 && RGB[1] > 0.91 && RGB[2] > 0.91)
    }
    
    public func isDistinct(from color: UIColor) -> Bool {
        let bg = rgbComponents()
        let fg = color.rgbComponents()
        let threshold: CGFloat = 0.25
        var result = false
        
        if abs(bg[0] - fg[0]) > threshold || abs(bg[1] - fg[1]) > threshold || abs(bg[2] - fg[2]) > threshold {
            if abs(bg[0] - bg[1]) < 0.03 && abs(bg[0] - bg[2]) < 0.03 {
                if abs(fg[0] - fg[1]) < 0.03 && abs(fg[0] - fg[2]) < 0.03 {
                    result = false
                }
            }
            result = true
        }
        
        return result
    }
    
    public func isContrasting(with color: UIColor) -> Bool {
        let bg = rgbComponents()
        let fg = color.rgbComponents()
        
        let bgLum = 0.2126 * bg[0] + 0.7152 * bg[1] + 0.0722 * bg[2]
        let fgLum = 0.2126 * fg[0] + 0.7152 * fg[1] + 0.0722 * fg[2]
        let contrast = bgLum > fgLum
            ? (bgLum + 0.05) / (fgLum + 0.05)
            : (fgLum + 0.05) / (bgLum + 0.05)
        
        return 1.6 < contrast
    }
}

// MARK: - Gradient
extension Array where Element : UIColor {
    
    public func gradient(_ transform: ((_ gradient: inout CAGradientLayer) -> CAGradientLayer)? = nil) -> CAGradientLayer {
        var gradient = CAGradientLayer()
        gradient.colors = self.map { $0.cgColor }
        
        if let transform = transform {
            gradient = transform(&gradient)
        }
        
        return gradient
    }
}




// MARK: - Color components
extension UIColor {
    
    public var redComponent : CGFloat {
        get {
            var r : CGFloat = 0
            self.getRed(&r, green: nil , blue: nil, alpha: nil)
            return r
        }
    }
    
    public var greenComponent : CGFloat {
        get {
            var g : CGFloat = 0
            self.getRed(nil, green: &g , blue: nil, alpha: nil)
            return g
        }
    }
    
    public var blueComponent : CGFloat {
        get {
            var b : CGFloat = 0
            self.getRed(nil, green: nil , blue: &b, alpha: nil)
            return b
        }
    }
    
    public var alphaComponent : CGFloat {
        get {
            var a : CGFloat = 0
            self.getRed(nil, green: nil , blue: nil, alpha: &a)
            return a
        }
    }
}

public enum UIColorInputError: Error {
    case missingHashMarkAsPrefix(String)
    case unableToScanHexValue(String)
    case mismatchedHexStringLength(String)
    case unableToOutputHexStringForWideDisplayColor
}

extension UIColorInputError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .missingHashMarkAsPrefix(let hex):
            return "Invalid RGB string, missing '#' as prefix in \(hex)"
            
        case .unableToScanHexValue(let hex):
            return "Scan \(hex) error"
            
        case .mismatchedHexStringLength(let hex):
            return "Invalid RGB string from \(hex), number of characters after '#' should be either 3, 4, 6 or 8"
            
        case .unableToOutputHexStringForWideDisplayColor:
            return "Unable to output hex string for wide display color"
        }
    }
}

