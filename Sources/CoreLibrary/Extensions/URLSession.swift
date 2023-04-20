//
//  URLSession.swift
//  CoreLibrary
//
//  Created by Connor Wybranowski on 3/9/21.
//

import Foundation

extension URLSession: DataTaskHandler {

    public func executeDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        dataTask(with: request, completionHandler: completionHandler).resume()
    }
}
