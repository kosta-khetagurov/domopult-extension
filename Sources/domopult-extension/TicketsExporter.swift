import Foundation

struct Runner {
    static func run() async {
        let api = Api()
        let result = await api.ticketIds(take: 5)
        switch result {
        case .success(let ids):
            var ticketsinfo = [Ticket]()
            for ticketId in ids {
                try? await Task.sleep(milleseconds: Double.random(in: 1000...2000))
                let result = await api.ticketDetail(id: ticketId)
                switch result {
                case .success(let ticket):
                    ticketsinfo.append(ticket)
                case .failure(let error):
                    print(String(describing: error))
                }
            }
            let result = ticketsinfo.reduce(into: "") { partialResult, ticket in
                guard let guest = ticket.guests?.first else {
                    return
                }
                let (name, date) = (guest.name, guest.creationDate)
                partialResult += "\(name),\(date)\n"
            }
            createFile(contents: result.data(using: .utf8)!)
            exit(EXIT_SUCCESS)
        case .failure(let error):
            print(String(describing: error))
            exit(EXIT_FAILURE)
        }
    }
}

Task {
    await Runner.run()
}

dispatchMain()
