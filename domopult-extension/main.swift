//
//  main.swift
//  domopult-extension
//
//  Created by Konstantin Khetagurov on 27.08.2022.
//

import Foundation

let X_Auth_Tenant_Token = "YOUR_TOKEN"
let session = URLSession.shared
let jsonDecoder = JSONDecoder()
jsonDecoder.dateDecodingStrategy = .iso8601

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

func request(url: URL) -> URLRequest {
    var request = URLRequest(url: url)
    request.setValue(X_Auth_Tenant_Token, forHTTPHeaderField: "X-Auth-Tenant-Token")
    request.setValue("Domopult/3.4.7 (iPhone; iOS 15.6.1; Scale/3.00) BrandName: gc-expert BrandFriendlyName: Expert", forHTTPHeaderField: "User-Agent")
    request.setValue("*/*", forHTTPHeaderField: "Accept")
    request.setValue("ru-RU;q=1, en-RU;q=0.9, os-RU;q=0.8", forHTTPHeaderField: "Accept-Language")
    request.setValue("3.4.7", forHTTPHeaderField: "App-Version")
    request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
    return request
}

enum Route {
    case tickets(count: UInt)
    case ticketInfo(id: Int)
}

func makeURL(for route: Route) -> URL? {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = "gc-expert.domopult.ru"
    switch route {
    case .tickets(let count):
        urlComponents.path = "/api/api/clients/tickets/searchwstats"
        urlComponents.query = "page=0&size=\(count)&states=&query="
        return urlComponents.url
    case .ticketInfo(let id):
        urlComponents.path = "/api/api/clients/tickets/\(id)"
        return urlComponents.url
    }
}

/*
GET /api/api/clients/tickets?states=CLOSED&states=SOLVED&sort=ctime,desc&sort=state,desc&page=0&size=10 HTTP/1.1
Host: gc-expert.domopult.ru
X-Auth-Tenant-Token: {token}
Connection: keep-alive
Accept: *\/\*
User-Agent: Domopult/3.4.7 (iPhone; iOS 15.6.1; Scale/3.00) BrandName: gc-expert BrandFriendlyName: Expert
Accept-Language: ru-RU;q=1, en-RU;q=0.9, os-RU;q=0.8
App-Version: 3.4.7
Accept-Encoding: gzip, deflate, br
*/

func tickets(first count: UInt, completion: @escaping ((Result<[Int],Error>)->Void)) {
    guard let url = makeURL(for: .tickets(count: count)) else {
        fatalError("url building error")
    }
    let request = request(url: url)
    session.dataTask(with: request) { data, response, error in
        guard let data = data,
              error == nil else {
            return
        }
        do {
            let resultedIds = try jsonDecoder.decode(TicketsResponse.self, from: data).results.map({ $0.id })
            print("Number of tickets found: \(resultedIds.count)")
            completion(.success(resultedIds))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

/*
GET /api/api/client/tickets/727603 HTTP/1.1
Host: gc-expert.domopult.ru
X-Auth-Tenant-Token: {token}
Connection: keep-alive
Accept: *\/\*
User-Agent: Domopult/3.4.7 (iPhone; iOS 15.6.1; Scale/3.00) BrandName: gc-expert BrandFriendlyName: Expert
Accept-Language: ru-RU;q=1, en-RU;q=0.9, os-RU;q=0.8
App-Version: 3.4.7
Accept-Encoding: gzip, deflate, br
*/

func ticketDetail(id: Int, completion: @escaping (Result<Ticket, Error>)->Void) {
    guard let url = makeURL(for: .ticketInfo(id: id)) else {
        completion(.failure(TicketsError.noData))
        return
    }
    let request = request(url: url)
    session.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            completion(.failure(TicketsError.failed(statusCode: httpResponse.statusCode)))
            return
        }
        guard let data = data else {
            completion(.failure(TicketsError.noData))
            return
        }
        do {
            let ticket = try jsonDecoder.decode(Ticket.self, from: data)
            completion(.success(ticket))
            return
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

func createFile(name: String = "result.csv", path: String = FileManager.default.currentDirectoryPath,  contents: Data) {
    let fullPath = "\(path)/\(name)"
    FileManager.default.createFile(atPath: fullPath, contents: contents)
    print("file created at \(fullPath)")
}

func run() {
    tickets(first: 10) { result in
        switch result {
        case .success(let ids):
            let group = DispatchGroup()
            var ticketsinfo = [Ticket]()
            ids.forEach { ticketId in
                group.enter()
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 1000...5000))) {
                    print(ticketId)
                    ticketDetail(id: ticketId) { result in
                        switch result {
                        case .success(let ticket):
                            ticketsinfo.append(ticket)
                        case .failure(let error):
                            print(String(describing: error))
                        }
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) {
                let result = ticketsinfo.reduce(into: "") { partialResult, ticket in
                    guard let guest = ticket.guests?.first else {
                        return
                    }
                    let (name, date) = (guest.name, guest.creationDate)
                    partialResult += "\(name),\(date)\n"
                }
                createFile(contents: result.data(using: .utf8)!)
            }
        case .failure(let error):
            print(String(describing: error))
        }
    }
}

run()
RunLoop.main.run()
