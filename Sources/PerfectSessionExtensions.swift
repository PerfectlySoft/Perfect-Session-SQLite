//
//  PerfectSessionExtensions.swift
//  PerfectSessionCouchDB
//
//  Created by Jonathan Guthrie on 2016-12-20.
//
//

import PerfectSession
import SQLiteStORM
import StORM

/// Internal holder for database interaction
class PerfectSessionClass: SQLiteStORM {
	/// Token (session id)
	var token			= ""
	/// Associated UserID. Optional to populate
	var userid			= ""
	/// Date created, as an Int
	var created			= 0
	/// Date updated, as an Int
	var updated			= 0
	/// Idle time set at last update
	var idle			= SessionConfig.idle
	/// Data held in storage associated with session
	var data			= [String: Any]()

	/// IP Address of Session
	var ipaddress		= ""

	/// UserAgent of Session
	var useragent		= ""


	override open func table() -> String {
		return "sessions"
	}

	override init(){
		super.init()
	}

	init(runSetup: Bool) {
		super.init()
		if runSetup { try? setup() }
	}

	init(token: String, userid: String, created: Int, updated: Int, idle: Int, data: [String: Any], ipaddress: String, useragent: String ){
		super.init()
		self.token = token
		self.userid = userid
		self.created = created
		self.updated = updated
		self.idle = idle
		self.data = data
		self.ipaddress = ipaddress
		self.useragent = useragent
	}

	override open func to(_ this: StORMRow) {
		token		= this.data["token"] as? String ?? ""
		userid		= this.data["userid"] as? String ?? ""
		created		= this.data["created"] as? Int ?? 0
		updated		= this.data["updated"] as? Int ?? 0
		idle		= this.data["idle"] as? Int ?? 0
		if let str = this.data["data"] {
			data = try! (str as! String).jsonDecode() as! [String : Any]
		}
		ipaddress		= this.data["ipaddress"] as? String ?? ""
		useragent		= this.data["useragent"] as? String ?? ""
	}

	func rows() -> [PerfectSessionClass] {
		var rows = [PerfectSessionClass]()
		for i in 0..<self.results.rows.count {
			let row = PerfectSessionClass()
			row.to(self.results.rows[i])
			rows.append(row)
		}
		return rows
	}
	
}
