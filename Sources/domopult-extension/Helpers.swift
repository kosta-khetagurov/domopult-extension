//
//  File.swift
//  
//
//  Created by Konstantin Khetagurov on 28.08.2022.
//

import Foundation

func createFile(name: String = "result.csv", path: String = FileManager.default.currentDirectoryPath,  contents: Data) {
    let fullPath = "\(path)/\(Date.now.description).csv"
    FileManager.default.createFile(atPath: fullPath, contents: contents)
    print("File with tickets is located at \(fullPath)")
}

extension Task where Success == Never, Failure == Never {
    static func sleep(milleseconds: Double) async throws {
        let duration = UInt64(milleseconds * 1_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
