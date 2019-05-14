// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import DissenterShared
@testable import Data
@testable import Client

class SafeBrowsingTests: XCTestCase {
    
    let domainsList = Set<String>(arrayLiteral: "dissenter.com", "example.com")

    override func setUp() {
        super.setUp()
        
        Preferences.Shields.blockPhishingAndMalware.reset()
        DataController.shared = DataController()
    }

    override func tearDown() {
        DataController.viewContext.reset()
        super.tearDown()
    }

    func testShouldBlock() {
        let sb = SafeBrowsing(domainList: domainsList)
        
        XCTAssert(sb.shouldBlock(URL(string: "http://dissenter.com")!))
        XCTAssert(sb.shouldBlock(URL(string: "https://dissenter.com")!))
        
        // Make sure subdomains are blocked too.
        XCTAssert(sb.shouldBlock(URL(string: "https://www.dissenter.com")!))
        
        XCTAssertFalse(sb.shouldBlock(URL(string: "https://dissenterxxx.com")!))
        XCTAssert(sb.shouldBlock(URL(string: "https://example.com")!))
        XCTAssertFalse(sb.shouldBlock(URL(string: "https://foo.com")!))
    }
    
    func testShouldBlockGlobalShieldOff() {
        let sb = SafeBrowsing(domainList: domainsList)
        
        Preferences.Shields.blockPhishingAndMalware.value = false
        XCTAssertFalse(sb.shouldBlock(URL(string: "https://dissenter.com")!))
        XCTAssertFalse(sb.shouldBlock(URL(string: "https://example.com")!))
        XCTAssertFalse(sb.shouldBlock(URL(string: "https://foo.com")!))
    }
    
    func testShouldBlockLocalShields() {
        let context = DataController.viewContext
        let sb = SafeBrowsing(domainList: domainsList)
        
        let dissenterUrl = URL(string: "https://dissenter.com")!
        let exampleUrl = URL(string: "https://example.com")!
        
        // Dissenter domain will have safe browsing shield turned off.
        // No need to call getOrCreateForUrl here.
        Domain.setDissenterShieldInternal(forUrl: dissenterUrl, shield: .SafeBrowsing, isOn: false, isPrivateBrowsing: false, context: .existing(context))
        
        // example.com will have default value nil which means true
        _ = Domain.getOrCreate(forUrl: exampleUrl)
        
        // Global shield on, local shield should have precedence over global shield
        XCTAssertFalse(sb.shouldBlock(dissenterUrl))
        XCTAssert(sb.shouldBlock(exampleUrl))
        
        Preferences.Shields.blockPhishingAndMalware.value = false
        Domain.setDissenterShieldInternal(forUrl: exampleUrl, shield: .SafeBrowsing, isOn: true, isPrivateBrowsing: false, context: .existing(context))
        
        XCTAssertFalse(sb.shouldBlock(dissenterUrl))
        XCTAssert(sb.shouldBlock(exampleUrl))
        
    }
}
