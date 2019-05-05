import XCTest

import sslTestTests

var tests = [XCTestCaseEntry]()
tests += sslTestTests.allTests()
XCTMain(tests)
