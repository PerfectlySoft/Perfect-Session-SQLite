//
//  SQLiteSessionDriver.swift
//  Perfect-Session-SQLiteQL
//
//  Created by Jonathan Guthrie on 2016-12-19.
//
//

import PerfectHTTP
import PerfectSession
import PerfectLogger

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
			if session.isValid(request) {
				request.session = session
				request.session._state = "resume"
				createSession = false
			} else {
				driver.destroy(token: token)
			}
		}
		if createSession {
			//start new session
			request.session = driver.start(request)

		}

		// Now process CSRF
		if request.session._state != "new" || request.method == .post {
			//print("Check CSRF Request: \(CSRFFilter.filter(request))")
			if !CSRFFilter.filter(request) {

				switch SessionConfig.CSRF.failAction {
				case .fail:
					response.status = .notAcceptable
					callback(.halt(request, response))
					return
				case .log:
					LogFile.info("CSRF FAIL")

				default:
					print("CSRF FAIL (console notification only)")
				}
			}
		}
		

		callback(HTTPRequestFilterResult.continue(request, response))
	}
}

extension SessionSQLiteFilter: HTTPResponseFilter {

	/// Called once before headers are sent to the client.
	public func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		driver.save(session: response.request.session)
		let sessionID = response.request.session.token

		// 0.0.6 updates
		var domain = ""
		if !SessionConfig.cookieDomain.isEmpty {
			domain = SessionConfig.cookieDomain
		}

		if !sessionID.isEmpty {
			response.addCookie(HTTPCookie(name: SessionConfig.name,
				value: "\(sessionID)",
				domain: domain,
				expires: .relativeSeconds(SessionConfig.idle),
				path: SessionConfig.cookiePath,
				secure: SessionConfig.cookieSecure,
				httpOnly: SessionConfig.cookieHTTPOnly,
				sameSite: SessionConfig.cookieSameSite
				)
			)

			// CSRF Set Cookie
			if SessionConfig.CSRF.checkState {
				//print("in SessionConfig.CSRFCheckState")
				CSRFFilter.setCookie(response)
			}

		}

		callback(.continue)
	}

	/// Called zero or more times for each bit of body data which is sent to the client.
	public func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		callback(.continue)
	}
}
