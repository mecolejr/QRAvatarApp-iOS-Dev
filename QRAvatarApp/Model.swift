import SwiftUI
import RealityKit

struct Model: Identifiable {
    let id: String
    let name: String
    var thumbnailImage: UIImage?
    var modelEntity: ModelEntity?
    var qrCode: String? // This could be a unique identifier or URL for sharing
    
    init(id: String = UUID().uuidString, name: String, thumbnailImage: UIImage? = nil, modelEntity: ModelEntity? = nil, qrCode: String? = nil) {
        self.id = id
        self.name = name
        self.thumbnailImage = thumbnailImage
        self.modelEntity = modelEntity
        self.qrCode = qrCode ?? id // Default to using the model ID as the QR code content
    }
} 