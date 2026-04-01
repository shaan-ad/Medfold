import Foundation

enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case labResult = "lab_result"
    case prescription
    case imaging
    case insurance
    case visitSummary = "visit_summary"
    case immunization
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .labResult: return "Labs"
        case .prescription: return "Rx"
        case .imaging: return "Imaging"
        case .insurance: return "Insurance"
        case .visitSummary: return "Visits"
        case .immunization: return "Immunization"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .labResult: return "flask.fill"
        case .prescription: return "pills.fill"
        case .imaging: return "xray"
        case .insurance: return "creditcard.fill"
        case .visitSummary: return "stethoscope"
        case .immunization: return "syringe.fill"
        case .other: return "doc.fill"
        }
    }
}

enum DocumentStatus: String, Codable {
    case processing
    case ready
    case error
}

struct Document: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var description: String?
    var category: DocumentCategory
    let filePath: String
    let fileType: String
    let fileSize: Int64
    var documentDate: Date?
    var providerName: String?
    var tags: [String]
    var aiSummary: String?
    var aiExtracted: [String: AnyCodable]?
    var status: DocumentStatus
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, description, category
        case filePath = "file_path"
        case fileType = "file_type"
        case fileSize = "file_size"
        case documentDate = "document_date"
        case providerName = "provider_name"
        case tags
        case aiSummary = "ai_summary"
        case aiExtracted = "ai_extracted"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Generic Codable wrapper for JSONB fields
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
