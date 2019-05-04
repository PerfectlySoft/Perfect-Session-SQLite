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
import PerfectLib
import Dispatch

public struct SessionSQLiteDriver {
	public var requestFilter: (HTTPRequestFilter, HTTPFilterPriority)
	public var responseFilter: (HTTPResponseFilter, HTTPFilterPriority)
	let queue: DispatchQueue

	public init() {
		let filter = SessionSQLiteFilter()
		requestFilter = (filter, HTTPFilterPriority.high)
		responseFilter = (filter, HTTPFilterPriority.high)
		queue = DispatchQueue(label: UUID().string)
		queue.asyncAfter(deadline: .now() + Double(SessionConfig.purgeInterval)) {
			let s = SQLiteSessions()
			s.clean()
		}
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
		if request.path != SessionConfig.healthCheckRoute {
			var createSession = true
			var session = PerfectSession()

			if let token = request.getCookie(name: SessionConfig.name) {
				// From Cookie
				session = driver.resume(token: token)
			} else if var bearer = request.header(.authorization), !bearer.isEmpty, bearer.hasPrefix("Bearer ") {
				// From Bearer Token
				bearer.removeFirst("Bearer ".count)
				session = driver.resume(token: bearer)

			} else if let s = request.param(name: "session"), !s.isEmpty {
				// From Session Link
				session = driver.resume(token: s)
			}

			if !session.token.isEmpty {
				//				var session = driver.resume(token: token)
				if session.isValid(request) {
					session._state = "resume"
					request.session = session
					createSession = false
				} else {
					driver.destroy(request, response)
				}
			}
			if createSession {
				//start new session
				request.session = driver.start(request)

			}

			// Now process CSRF
			if request.session?._state != "new" || request.method == .post {
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
			
			CORSheaders.make(request, response)
		}
		callback(HTTPRequestFilterResult.continue(request, response))
	}

	/// Wrapper enabling PerfectHTTP 2.1 filter support
	public static func filterAPIRequest(data: [String:Any]) throws -> HTTPRequestFilter {
		return SessionSQLiteFilter()
	}

}

extension SessionSQLiteFilter: HTTPResponseFilter {

	/// Called once before headers are sent to the client.
	public func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		
		guard let session = response.request.session else {
			return callback(.continue)
		}
		
		driver.save(session: session)
		let sessionID = session.token

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

	/// Wrapper enabling PerfectHTTP 2.1 filter support
	public static func filterAPIResponse(data: [String:Any]) throws -> HTTPResponseFilter {
		return SessionSQLiteFilter()
	}


	/// Called zero or more times for each bit of body data which is sent to the client.
	public func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		callback(.continue)
	}
}
