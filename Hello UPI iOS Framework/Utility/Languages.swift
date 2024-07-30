//
//  Languages.swift
//  Hello UPI iOS Framework
//
//  Created by Narayan Shettigar on 22/07/24.
//

import Foundation

public enum Language {
    case none
    case hindi
    case english
    case tamil
    case telugu
    case malayalam
    case bengali
    case kannada
    case gujarathi
    case marathi
    case punjabi
    case assamese
    case odiya
    case urdu
    
    public func getValue() -> Int {
        switch self {
        case .none: return 0
        case .hindi: return 1
        case .english: return 2
        case .tamil: return 3
        case .telugu: return 4
        case .malayalam: return 5
        case .bengali: return 6
        case .kannada: return 7
        case .gujarathi: return 8
        case .marathi: return 9
        case .punjabi: return 10
        case .assamese: return 11
        case .odiya: return 12
        case .urdu: return 13
        }
    }
    
    public var capitalizedString: String {
        switch self {
        case .none: return "Select Language"
        default: return "\(self)".capitalized
        }
    }
}
