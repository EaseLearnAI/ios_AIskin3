import Foundation

struct MultipartFile: Sendable {
    let fieldName: String
    let fileName: String
    let mimeType: String
    let data: Data
}

struct MultipartBody: Sendable {
    let boundary: String
    let fields: [String: String]
    let files: [MultipartFile]

    init(
        boundary: String = UUID().uuidString,
        fields: [String: String] = [:],
        files: [MultipartFile]
    ) {
        self.boundary = boundary
        self.fields = fields
        self.files = files
    }

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    func encoded() -> Data {
        var result = Data()

        for (name, value) in fields.sorted(by: { $0.key < $1.key }) {
            result.appendUTF8("--\(boundary)\r\n")
            result.appendUTF8("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            result.appendUTF8("\(value)\r\n")
        }

        for file in files {
            result.appendUTF8("--\(boundary)\r\n")
            result.appendUTF8(
                "Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n"
            )
            result.appendUTF8("Content-Type: \(file.mimeType)\r\n\r\n")
            result.append(file.data)
            result.appendUTF8("\r\n")
        }

        result.appendUTF8("--\(boundary)--\r\n")
        return result
    }
}

private extension Data {
    mutating func appendUTF8(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
