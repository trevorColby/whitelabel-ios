//
//  WhiteLabelHTTPClient.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

public typealias JSON = [String: AnyObject]

typealias WhiteLabelHTTPClientCompletionHandler = (data: JSON?, error: ErrorType?) -> ()

class WhiteLabelHTTPClient {
	enum HTTPMethod: String {
		case GET = "GET"
		case POST = "POST"
		case PUT = "PUT"
		case DELETE = "DELETE"
	}

	static let sharedClient = WhiteLabelHTTPClient()
	
	func sendRequest(method: HTTPMethod, path: String, parameters: [String: AnyObject]? = nil, timeoutInterval: NSTimeInterval = Configuration.defaultTimeoutInterval, completionHandler: WhiteLabelHTTPClientCompletionHandler?) {
		guard let baseURL = Configuration.defaultBaseURL else {
			fatalError("WhiteLabelHTTPClient.sendRequest(): baseURL is nil and Configuration.defaultBaseURL is nil, did you forget to set it to your base URL?")
		}
		self.sendRequest(method, path: path, parameters: parameters, baseURL: baseURL, timeoutInterval: timeoutInterval, completionHandler: completionHandler)
	}
	
	func sendRequest(method: HTTPMethod, path: String, parameters: [String: AnyObject]? = nil, baseURL: NSURL, timeoutInterval: NSTimeInterval = Configuration.defaultTimeoutInterval, completionHandler: WhiteLabelHTTPClientCompletionHandler?) {
		let mainThreadCompletionHandler: WhiteLabelHTTPClientCompletionHandler = { (data, error) in
			dispatch_async(dispatch_get_main_queue()) {
				completionHandler?(data: data, error: error)
			}
		}

		var path = path
		if let parameters = parameters as? [String: String] where method == .GET {
			path += "?" + parameters.map { (key, value) in "\(key)=\(value)" }.joinWithSeparator("&")
		}
		let request = NSMutableURLRequest(URL: baseURL.URLByAppendingPathComponent(path)!)
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.HTTPMethod = method.rawValue
		if let parameters = parameters where method != .GET {
			do {
				request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions(rawValue: 0))
			} catch {
				mainThreadCompletionHandler(data: nil, error: error)
				return
			}
		}
		
		let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
		sessionConfiguration.timeoutIntervalForRequest = timeoutInterval
		sessionConfiguration.timeoutIntervalForResource = timeoutInterval
		let session = NSURLSession(configuration: sessionConfiguration)
		let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
			if error != nil {
				mainThreadCompletionHandler(data: nil, error: error)
				return
			}
			
			guard let response = response as? NSHTTPURLResponse else {
				mainThreadCompletionHandler(data: nil, error: ErrorCode.InvalidResponseReceived)
				return
			}
			
			if response.statusCode >= 200 && response.statusCode <= 299 {
				var json: JSON? = nil
				if let data = data {
					do {
						json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? JSON
					} catch {
						mainThreadCompletionHandler(data: nil, error: error)
						return
					}
				}
				
				mainThreadCompletionHandler(data: json, error: nil)
			} else {
				mainThreadCompletionHandler(data: nil, error: ErrorCode.RequestFailed)
			}
		}
		dataTask.resume()
	}
}
