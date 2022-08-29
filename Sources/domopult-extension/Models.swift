import Foundation

struct TicketsResponse: Decodable {
    let total: UInt
    let results: [Ticket]
}

struct Guest: Decodable {
    let name: String
    let creationDate: Date

    enum PassCodingKeys: String, CodingKey {
        case name
        case pass
    }

    enum GuestCodingKeys: String, CodingKey {
        case creationDate
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: PassCodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        let pass = try values.nestedContainer(keyedBy: GuestCodingKeys.self, forKey: .pass)
        creationDate = try pass.decode(Date.self, forKey: .creationDate)
    }
}

struct Ticket: Decodable {
    let id: Int
    let fullName: String
    let guests: [Guest]?
}

enum TicketsError: Error {
    case failed(statusCode: Int)
    case noData
}

enum Route {
    case tickets(count: UInt)
    case ticketInfo(id: Int)
}
