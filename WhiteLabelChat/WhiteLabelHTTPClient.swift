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
	
	func sendRequest(method: HTTPMethod, path: String, parameters: [String: AnyObject]? = nil, completionHandler: WhiteLabelHTTPClientCompletionHandler?) {
		guard let baseURL = Configuration.defaultBaseURL else {
			fatalError("WhiteLabelHTTPClient.sendRequest(): baseURL is nil and Configuration.defaultBaseURL is nil, did you forget to set it to your base URL?")
		}
		self.sendRequest(method, path: path, parameters: parameters, baseURL: baseURL, completionHandler: completionHandler)
	}
	
	func sendRequest(method: HTTPMethod, var path: String, parameters: [String: AnyObject]? = nil, baseURL: NSURL, completionHandler: WhiteLabelHTTPClientCompletionHandler?) {
		if let parameters = parameters as? [String: String] where method == .GET {
			path += "?" + parameters.map { (key, value) in "\(key)=\(value)" }.joinWithSeparator("&")
		}
		let request = NSMutableURLRequest(URL: baseURL.URLByAppendingPathComponent(path))
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.HTTPMethod = method.rawValue
		if let parameters = parameters where method != .GET {
			do {
				request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions(rawValue: 0))
			} catch {
				completionHandler?(data: nil, error: error)
				return
			}
		}
		
		let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
			if error != nil {
				completionHandler?(data: nil, error: error)
				return
			}
			
			guard let response = response as? NSHTTPURLResponse else {
				completionHandler?(data: nil, error: ErrorCode.InvalidResponseReceived)
				return
			}
			
			if response.statusCode >= 200 && response.statusCode <= 299 {
				var json: JSON? = nil
				if let data = data {
					do {
						json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? JSON
					} catch {
						completionHandler?(data: nil, error: error)
						return
					}
				}
				
				completionHandler?(data: json, error: nil)
			} else {
				completionHandler?(data: nil, error: nil/*ErrorCode.RequestFailed*/)
			}
		}
		dataTask.resume()
	}
}
