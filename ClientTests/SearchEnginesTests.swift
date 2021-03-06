/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Foundation
import XCTest
import Shared
import DissenterShared

class SearchEnginesTests: XCTestCase {
    
    private let DefaultSearchEngineName = "DuckDuckGo"
    // BRAVE TODO: This list is not accurate because Dissenter uses many more engines
    private let ExpectedEngineNames = ["Qwant", "Bing", "DuckDuckGo", "Google", "StartPage"]
    
    override func setUp() {
        super.setUp()
        
        Preferences.Search.defaultEngineName.reset()
        Preferences.Search.defaultPrivateEngineName.reset()
        Preferences.Search.disabledEngines.reset()
        Preferences.Search.orderedEngines.reset()
        Preferences.Search.showSuggestions.reset()
        PrivateBrowsingManager.shared.isPrivateBrowsing = false
    }

    func testIncludesExpectedEngines() {
        // Verify that the set of shipped engines includes the expected subset.
        let profile = MockProfile()
        let engines = SearchEngines(files: profile.files).orderedEngines
        XCTAssertTrue((engines?.count)! >= ExpectedEngineNames.count)

        for engineName in ExpectedEngineNames {
            XCTAssertTrue(((engines?.filter { engine in engine.shortName == engineName })?.count)! > 0)
        }
    }

    func testDefaultEngineOnStartup() {
        // If this is our first run, Google should be first for the en locale.
        let profile = MockProfile()
        let engines = SearchEngines(files: profile.files)
        XCTAssertEqual(engines.defaultEngine().shortName, DefaultSearchEngineName)
        // The default is `DefaultSearchEngineName` for both regular and private browsing.
        // Different search engine options might apply to certain regions.
        // Default locale for running tests should be en_US.
        XCTAssertEqual(engines.defaultEngine(forType: .privateMode).shortName, DefaultSearchEngineName)
        XCTAssertEqual(engines.orderedEngines[0].shortName, DefaultSearchEngineName)
    }

    func testAddingAndDeletingCustomEngines() {
        let testEngine = OpenSearchEngine(engineID: "ATester", shortName: "ATester", image: UIImage(), searchTemplate: "http://firefox.com/find?q={searchTerm}", suggestTemplate: nil, isCustomEngine: true)
        let profile = MockProfile()
        let engines = SearchEngines(files: profile.files)
        engines.addSearchEngine(testEngine)
        XCTAssertEqual(engines.orderedEngines[1].engineID, testEngine.engineID)

        engines.deleteCustomEngine(testEngine)
        let deleted = engines.orderedEngines.filter {$0 == testEngine}
        XCTAssertEqual(deleted, [])
    }

    func testDefaultEngine() {
        let profile = MockProfile()
        let engines = SearchEngines(files: profile.files)
        let engineSet = engines.orderedEngines
        
        engines.setDefaultEngine((engineSet?[0])!.shortName, forType: .standard)
        XCTAssertTrue(engines.isEngineDefault((engineSet?[0])!))
        XCTAssertFalse(engines.isEngineDefault((engineSet?[1])!))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet?[0].shortName)

        engines.setDefaultEngine((engineSet?[1])!.shortName, forType: .standard)
        XCTAssertFalse(engines.isEngineDefault((engineSet?[0])!))
        XCTAssertTrue(engines.isEngineDefault((engineSet?[1])!))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet?[1].shortName)

        let engines2 = SearchEngines(files: profile.files)
        // The default engine should have been persisted.
        XCTAssertTrue(engines2.isEngineDefault((engineSet?[1])!))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet?[1].shortName)
    }
    
    func testSetPrivateDefaultEngine() {
        let profile = MockProfile()
        let engines = SearchEngines(files: profile.files)
        let engineSet = engines.orderedEngines!
        
        let firstEngine = engineSet[0]
        let secondEngine = engineSet[1]
        
        engines.setDefaultEngine(firstEngine.shortName, forType: .standard)
        XCTAssertTrue(engines.isEngineDefault(firstEngine, type: .privateMode))
        XCTAssertFalse(engines.isEngineDefault(secondEngine, type: .privateMode))
    }

    func testOrderedEngines() {
        let profile = MockProfile()
        let engines = SearchEngines(files: profile.files)

        engines.orderedEngines = [ExpectedEngineNames[4], ExpectedEngineNames[2], ExpectedEngineNames[0]].map { name in
            for engine in engines.orderedEngines {
                if engine.shortName == name {
                    return engine
                }
            }
            XCTFail("Could not find engine: \(name)")
            return engines.orderedEngines.first!
        }
        XCTAssertEqual(engines.orderedEngines[0].shortName, ExpectedEngineNames[4])
        XCTAssertEqual(engines.orderedEngines[1].shortName, ExpectedEngineNames[2])
        XCTAssertEqual(engines.orderedEngines[2].shortName, ExpectedEngineNames[0])

        let engines2 = SearchEngines(files: profile.files)
        // The ordering should have been persisted.
        XCTAssertEqual(engines2.orderedEngines[0].shortName, ExpectedEngineNames[4])
        XCTAssertEqual(engines2.orderedEngines[1].shortName, ExpectedEngineNames[2])
        XCTAssertEqual(engines2.orderedEngines[2].shortName, ExpectedEngineNames[0])
    }

    func testQuickSearchEngines() {
        let profile = MockProfile()
        let engines = SearchEngines(files: profile.files)
        let engineSet = engines.orderedEngines

        // You can't disable the default engine.
        engines.setDefaultEngine((engineSet?[1])!.shortName, forType: .standard)
        engines.disableEngine((engineSet?[1])!)
        XCTAssertTrue(engines.isEngineEnabled((engineSet?[1])!))

        // The default engine is not included in the quick search engines.
        XCTAssertEqual(0, engines.quickSearchEngines.filter { engine in engine.shortName == engineSet?[1].shortName }.count)

        // Enable and disable work.
        engines.enableEngine((engineSet?[0])!)
        XCTAssertTrue(engines.isEngineEnabled((engineSet?[0])!))
        XCTAssertEqual(1, engines.quickSearchEngines.filter { engine in engine.shortName == engineSet?[0].shortName }.count)

        engines.disableEngine((engineSet?[0])!)
        XCTAssertFalse(engines.isEngineEnabled((engineSet?[0])!))
        XCTAssertEqual(0, engines.quickSearchEngines.filter { engine in engine.shortName == engineSet?[0].shortName }.count)

        // Setting the default engine enables it.
        engines.setDefaultEngine((engineSet?[0])!.shortName, forType: .standard)
        XCTAssertTrue(engines.isEngineEnabled((engineSet?[1])!))

        // Setting the order may change the default engine, which enables it.
        engines.orderedEngines = [(engineSet?[2])!, (engineSet?[1])!, (engineSet?[0])!]
        XCTAssertTrue(engines.isEngineEnabled((engineSet?[2])!))

        // The enabling should be persisted.
        engines.enableEngine((engineSet?[2])!)
        engines.disableEngine((engineSet?[1])!)
        engines.enableEngine((engineSet?[0])!)

        let engines2 = SearchEngines(files: profile.files)
        XCTAssertTrue(engines2.isEngineEnabled((engineSet?[2])!))
        XCTAssertFalse(engines2.isEngineEnabled((engineSet?[1])!))
        XCTAssertTrue(engines2.isEngineEnabled((engineSet?[0])!))
    }

    func testSearchSuggestionSettings() {
        let profile = MockProfile()
        let engines = SearchEngines(files: profile.files)

        // By default, you shouldnt see search suggestions as this sends all users searches to their selected search
        // engine
        XCTAssertFalse(engines.shouldShowSearchSuggestions)

        // Setting should be persisted.
        engines.shouldShowSearchSuggestions = true

        let engines2 = SearchEngines(files: profile.files)
        XCTAssertTrue(engines2.shouldShowSearchSuggestions)
    }

    func testUnorderedSearchEngines() {
        let unorderedList = ["DuckDuckGo", "Bing", "Qwant", "StartPage", "Google"]
        ["zh-TW", "en-CA", "de-DE", "en-US"].forEach {
            XCTAssertEqual(SearchEngines.getUnorderedBundledEnginesFor(locale: Locale(identifier: $0)).compactMap({$0.shortName}), unorderedList)
        }
        
        let russianList = ["DuckDuckGo", "Яндекс", "Qwant", "StartPage", "Google"]
        XCTAssertEqual(SearchEngines.getUnorderedBundledEnginesFor(locale: Locale(identifier: "ru")).compactMap({$0.shortName}), russianList)
    }

    func testGetOrderedEngines() {
        // setup an existing search engine in the profile
        let profile = MockProfile()
        profile.prefs.setObject(["DuckDuckGo"], forKey: "search.orderedEngineNames")
        let engines = SearchEngines(files: profile.files)
        XCTAssert(engines.orderedEngines.count > 1, "There should be more than one search engine")
        XCTAssertEqual(engines.orderedEngines.first!.shortName, "DuckDuckGo", "DuckDuckGo should be the first search engine")
    }

}
