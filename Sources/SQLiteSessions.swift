//
//  CouchDBSessions.swift
//  Perfect-Session-CouchDBQL
//
//  Created by Jonathan Guthrie on 2016-12-19.
//
//

import TurnstileCrypto
import SQLiteStORM
import PerfectSession


public struct SQLiteSessions {

	/// Initializes the Session Manager. No config needed!
	public init() {}


	public func save(session: PerfectSession) {
		var s = session
		s.touch()
		// perform UPDATE
		let proxy = PerfectSessionClass()
		//find
		do {
			try proxy.find(["token":session.token])
			if proxy.results.rows.isEmpty {
				return
			}
			proxy.to(proxy.results.rows[0])
		} catch {
			print("Error retrieving session: \(error)")
		}
		// assign
		proxy.userid = s.userid
		proxy.updated = s.updated
		proxy.idle = SessionConfig.idle // update in case this has changed
		proxy.data = s.data

		// save
		do {
			try proxy.save()
		} catch {
			print("Error saving session: \(error)")
		}
	}

	public func start() -> PerfectSession {
		let rand = URandom()
		var session = PerfectSession()
		session.token = rand.secureToken

		// perform INSERT
		let proxy = PerfectSessionClass(
			token: session.token,
			userid: session.userid,
			created: session.created,
			updated: session.updated,
			idle: session.idle,
			data: session.data
		)
		_ = try? proxy.create()
		return session
	}

	/// Deletes the session for a session identifier.
	public func destroy(token: String) {
		let proxy = PerfectSessionClass()
		do {
			do {
				try proxy.find(["token":token])
				proxy.to(proxy.results.rows[0])
			} catch {
				print("Error retrieving session: \(error)")
			}
			try proxy.delete()
		} catch {
			print(error)
		}
	}

	public func resume(token: String) -> PerfectSession {
		print("Resume with token: \(token)")
		var session = PerfectSession()
		let proxy = PerfectSessionClass()
		do {
			try proxy.find(["token":token])
			if proxy.results.rows.isEmpty {
				return session
			}
			proxy.to(proxy.results.rows[0])

			session.token = token
			session.userid = proxy.userid
			session.created = proxy.created
			session.updated = proxy.updated
			session.idle = SessionConfig.idle // update in case this has changed
			session.data = proxy.data
		} catch {
			print("Error retrieving session: \(error)")
		}
		return session
	}



	func isError(_ errorMsg: String) -> Bool {
		if errorMsg.contains(string: "ERROR") {
			print(errorMsg)
			return true
		}
		return false
	}
	
}



