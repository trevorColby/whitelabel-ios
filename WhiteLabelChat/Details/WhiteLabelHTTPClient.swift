//
//  WhiteLabelHTTPClient.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

public typealias JSON = [String: AnyObject]

typealias WhiteLabelHTTPClientCompletionHandler = (_ data: JSON?, _ error: Error?) -> ()

class WhiteLabelHTTPClient {
	enum HTTPMethod: String {
		case GET = "GET"
		case POST = "POST"
		case PUT = "PUT"
		case DELETE = "DELETE"
	}

	static let sharedClient = WhiteLabelHTTPClient()
	
	func sendRequest(_ method: HTTPMethod, path: String, parameters: [String: AnyObject]? = nil, timeoutInterval: TimeInterval = Configuration.defaultTimeoutInterval, completionHandler: WhiteLabelHTTPClientCompletionHandler?) {
		guard let baseURL = Configuration.defaultBaseURL else {
			fatalError("WhiteLabelHTTPClient.sendRequest(): baseURL is nil and Configuration.defaultBaseURL is nil, did you forget to set it to your base URL?")
		}
		self.sendRequest(method, path: path, parameters: parameters, baseURL: baseURL as URL, timeoutInterval: timeoutInterval, completionHandler: completionHandler)
	}
	
	func sendRequest(_ method: HTTPMethod, path: String, parameters: [String: AnyObject]? = nil, baseURL: URL, timeoutInterval: TimeInterval = Configuration.defaultTimeoutInterval, completionHandler: WhiteLabelHTTPClientCompletionHandler?) {
		let mainThreadCompletionHandler: WhiteLabelHTTPClientCompletionHandler = { (data, error) in
			DispatchQueue.main.async {
				completionHandler?(data, error)
			}
		}

		var path = path
		if let parameters = parameters as? [String: String], method == .GET {
			path += "?" + parameters.map { (key, value) in "\(key)=\(value)" }.joined(separator: "&")
		}
		var request = URLRequest(url: baseURL.appendingPathComponent(path))
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = method.rawValue
		if let parameters = parameters, method != .GET {
			do {
				request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions(rawValue: 0))
			} catch {
				mainThreadCompletionHandler(nil, error)
				return
			}
		}
		
		let sessionConfiguration = URLSessionConfiguration.default
		sessionConfiguration.timeoutIntervalForRequest = timeoutInterval
		sessionConfiguration.timeoutIntervalForResource = timeoutInterval
		let session = URLSession(configuration: sessionConfiguration)
		let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
			if error != nil {
				mainThreadCompletionHandler(nil, error)
				return
			}
			
			guard let response = response as? HTTPURLResponse else {
				mainThreadCompletionHandler(nil, ErrorCode.invalidResponseReceived)
				return
			}
			
			if response.statusCode >= 200 && response.statusCode <= 299 {
				var json: JSON? = nil
				if let data = data {
					do {
						json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? JSON
					} catch {
						mainThreadCompletionHandler(nil, error)
						return
					}
				}
				
				mainThreadCompletionHandler(json, nil)
			} else {
				mainThreadCompletionHandler(nil, ErrorCode.requestFailed)
			}
		}) 
		dataTask.resume()
	}
}
