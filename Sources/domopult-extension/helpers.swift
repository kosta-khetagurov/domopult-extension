//
//  File.swift
//  
//
//  Created by Konstantin Khetagurov on 28.08.2022.
//

import Foundation

func createFile(name: String = "result.csv", path: String = FileManager.default.currentDirectoryPath,  contents: Data) {
    let fullPath = "\(path)/\(name)"
    FileManager.default.createFile(atPath: fullPath, contents: contents)
    print("File with tickets is located at \(fullPath)")
}
