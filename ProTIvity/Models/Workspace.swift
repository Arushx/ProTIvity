import Foundation
import SwiftUI

// Ensure there's only one Workspace struct definition
struct Workspace: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var color: Color
    var categories: [String]
    var tasks: [Task] = []
    var goals: [Goal] = []
    var pages: [Page] = []
    var items: [WorkspaceItem] = []
    
    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Workspace, rhs: Workspace) -> Bool {
        lhs.id == rhs.id
    }
    
    // CodingKeys for Color encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, categories, tasks, goals, pages, items
    }
    
    // Custom encoding for Color
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        
        // Encode color as UIColor components
        if let colorComponents = color.cgColor?.components {
            let colorData = try JSONEncoder().encode(colorComponents)
            try container.encode(colorData, forKey: .color)
        }
        
        try container.encode(categories, forKey: .categories)
        try container.encode(tasks, forKey: .tasks)
        try container.encode(goals, forKey: .goals)
        try container.encode(pages, forKey: .pages)
        try container.encode(items, forKey: .items)
    }
    
    // Custom decoding for Color
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        
        // Decode color from components
        let colorData = try container.decode(Data.self, forKey: .color)
        let colorComponents = try JSONDecoder().decode([CGFloat].self, from: colorData)
        if colorComponents.count >= 3 {
            color = Color(red: Double(colorComponents[0]), 
                         green: Double(colorComponents[1]), 
                         blue: Double(colorComponents[2]))
        } else {
            color = .blue // Default color
        }
        
        categories = try container.decode([String].self, forKey: .categories)
        tasks = try container.decode([Task].self, forKey: .tasks)
        goals = try container.decode([Goal].self, forKey: .goals)
        pages = try container.decode([Page].self, forKey: .pages)
        
        // Handle optional items array for backward compatibility
        if container.contains(.items) {
            items = try container.decode([WorkspaceItem].self, forKey: .items)
        } else {
            items = []
        }
    }
    
    // Convenience initializer
    init(name: String, icon: String, color: Color, categories: [String]) {
        self.name = name
        self.icon = icon
        self.color = color
        self.categories = categories
    }
}

// Define Page model if it's not defined elsewhere
struct Page: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var content: String = ""
    var dateCreated: Date = Date()
    var dateModified: Date = Date()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Page, rhs: Page) -> Bool {
        lhs.id == rhs.id
    }
}

enum WorkspaceItem: Identifiable, Codable, Equatable {
    case page(Page)
    case folder(Folder)
    
    var id: UUID {
        switch self {
        case .page(let page):
            return page.id
        case .folder(let folder):
            return folder.id
        }
    }
    
    static func == (lhs: WorkspaceItem, rhs: WorkspaceItem) -> Bool {
        lhs.id == rhs.id
    }
    
    // Custom coding for enum
    enum CodingKeys: String, CodingKey {
        case type, page, folder
    }
    
    enum ItemType: String, Codable {
        case page, folder
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .page(let page):
            try container.encode(ItemType.page, forKey: .type)
            try container.encode(page, forKey: .page)
        case .folder(let folder):
            try container.encode(ItemType.folder, forKey: .type)
            try container.encode(folder, forKey: .folder)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemType.self, forKey: .type)
        
        switch type {
        case .page:
            let page = try container.decode(Page.self, forKey: .page)
            self = .page(page)
        case .folder:
            let folder = try container.decode(Folder.self, forKey: .folder)
            self = .folder(folder)
        }
    }
}

struct Folder: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var items: [WorkspaceItem] = []
    var isExpanded: Bool = true
    
    static func == (lhs: Folder, rhs: Folder) -> Bool {
        lhs.id == rhs.id
    }
}

struct Attachment: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var type: AttachmentType
    var url: URL
    var dateAdded: Date = Date()
    
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        lhs.id == rhs.id
    }
    
    // Custom coding for URL
    enum CodingKeys: String, CodingKey {
        case id, name, type, urlString, dateAdded
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(url.absoluteString, forKey: .urlString)
        try container.encode(dateAdded, forKey: .dateAdded)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(AttachmentType.self, forKey: .type)
        let urlString = try container.decode(String.self, forKey: .urlString)
        url = URL(string: urlString) ?? URL(fileURLWithPath: "")
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
    }
    
    init(name: String, type: AttachmentType, url: URL) {
        self.name = name
        self.type = type
        self.url = url
    }
}

enum AttachmentType: String, Codable {
    case image
    case pdf
    case document
    case other
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .pdf: return "doc.text"
        case .document: return "doc"
        case .other: return "paperclip"
        }
    }
}
