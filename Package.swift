// swift-tools-version:4.2
// Generated automatically by Perfect Assistant Application
// Date: 2017-10-03 20:20:46 +0000
import PackageDescription
let package = Package(
	name: "PerfectSessionSQLite",
	products: [
		.library(name: "PerfectSessionSQLite", targets: ["PerfectSessionSQLite"])
	],
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-Session.git", from: "3.0.0"),
		.package(url: "https://github.com/SwiftORM/SQLite-StORM.git", from: "3.0.0"),
	],
	targets: [
		.target(name: "PerfectSessionSQLite", dependencies: ["PerfectSession", "SQLiteStORM"])
	]
)
