import Foundation

final class Api {
    private let session = URLSession.shared

    private var jsonDecoder: JSONDecoder = {
        let jd = JSONDecoder()
        jd.dateDecodingStrategy = .iso8601
        return jd
    }()
    private var X_Auth_Tenant_Token: String? = {
        return ProcessInfo.processInfo.environment["X_Auth_Tenant_Token"]
    }()

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

    public func tickets(first count: UInt, completion: @escaping ((Result<[Int],Error>)->Void)) {
        guard let url = makeURL(for: .tickets(count: count)) else {
            fatalError("url building error")
        }
        let request = request(url: url)
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                return
            }
            do {
                let resultedIds = try self.jsonDecoder.decode(TicketsResponse.self, from: data).results.map({ $0.id })
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

    public func ticketDetail(id: Int, completion: @escaping (Result<Ticket, Error>)->Void) {
        guard let url = makeURL(for: .ticketInfo(id: id)) else {
            completion(.failure(TicketsError.noData))
            return
        }
        let request = request(url: url)
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                return
            }
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
                let ticket = try self.jsonDecoder.decode(Ticket.self, from: data)
                completion(.success(ticket))
                return
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func request(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(X_Auth_Tenant_Token, forHTTPHeaderField: "X-Auth-Tenant-Token")
        request.setValue("Domopult/3.4.7 (iPhone; iOS 15.6.1; Scale/3.00) BrandName: gc-expert BrandFriendlyName: Expert", forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("ru-RU;q=1, en-RU;q=0.9, os-RU;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("3.4.7", forHTTPHeaderField: "App-Version")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        return request
    }
}

private func makeURL(for route: Route) -> URL? {
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
