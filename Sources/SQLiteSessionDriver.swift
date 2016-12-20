//
//  SQLiteSessionDriver.swift
//  Perfect-Session-SQLiteQL
//
//  Created by Jonathan Guthrie on 2016-12-19.
//
//

import PerfectHTTP
import PerfectSession

public struct SessionSQLiteDriver {
	public var requestFilter: (HTTPRequestFilter, HTTPFilterPriority)
	public var responseFilter: (HTTPResponseFilter, HTTPFilterPriority)


	public init() {
		let filter = SessionSQLiteFilter()
		requestFilter = (filter, HTTPFilterPriority.high)
		responseFilter = (filter, HTTPFilterPriority.high)
	}
}
public class SessionSQLiteFilter {
	var driver = SQLiteSessions()
	public init() {
		_ = PerfectSessionClass(runSetup: true) // runs db setup
	}
}

extension SessionSQLiteFilter: HTTPRequestFilter {

	public func filter(request: HTTPRequest, response: HTTPResponse, callback: (HTTPRequestFilterResult) -> ()) {

		var createSession = true
		if let token = request.getCookie(name: SessionConfig.name) {
			let session = driver.resume(token: token)
			if session.isValid() {
				request.session = session
				// print("Session: token \(session.token); created \(session.created); updated \(session.updated)")
				createSession = false
			} else {
				driver.destroy(token: token)
			}
		}
		if createSession {
			//start new session
			request.session = driver.start()
			// print("Session (new): token \(request.session.token); created \(request.session.created); updated \(request.session.updated)")

		}

		callback(HTTPRequestFilterResult.continue(request, response))
	}
}

extension SessionSQLiteFilter: HTTPResponseFilter {

	/// Called once before headers are sent to the client.
	public func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		driver.save(session: response.request.session)
		let sessionID = response.request.session.token
		if !sessionID.isEmpty {
			response.addCookie(HTTPCookie(name: SessionConfig.name,
			    value: "\(sessionID)",
				domain: nil,
				expires: .relativeSeconds(SessionConfig.idle),
				path: "/",
				secure: nil,
				httpOnly: true)
			)
		}

		callback(.continue)
	}

	/// Called zero or more times for each bit of body data which is sent to the client.
	public func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		callback(.continue)
	}
}
