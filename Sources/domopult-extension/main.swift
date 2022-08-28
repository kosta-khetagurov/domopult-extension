import Foundation

let api = Api()
api.tickets(first: 10) { result in
    switch result {
    case .success(let ids):
        let group = DispatchGroup()
        var ticketsinfo = [Ticket]()
        ids.forEach { ticketId in
            group.enter()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 1000...5000))) {
                api.ticketDetail(id: ticketId) { result in
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
            exit(EXIT_SUCCESS)
        }
    case .failure(let error):
        print(String(describing: error))
        exit(EXIT_FAILURE)
    }
}

dispatchMain()
