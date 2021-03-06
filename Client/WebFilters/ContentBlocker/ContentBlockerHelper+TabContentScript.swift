/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared
import Data
import Deferred
import DissenterShared

extension ContentBlockerHelper: TabContentScript {
    class func name() -> String {
        return "TrackingProtectionStats"
    }

    func scriptMessageHandlerName() -> String? {
        return "trackingProtectionStats"
    }

    func clearPageStats() {
        stats = TPPageStats()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard isEnabled,
            let body = message.body as? [String: String],
            let urlString = body["url"],
            let mainDocumentUrl = tab?.webView?.url else {
            return
        }
        
        let domain = Domain.getOrCreate(forUrl: mainDocumentUrl)
        if let shieldsAllOff = domain.shield_allOff, Bool(truncating: shieldsAllOff) {
            // if domain is "all_off", can just skip
            return
        }
    
        guard let url = URL(string: urlString) else { return }
        
        let resourceType = TPStatsResourceType(rawValue: body["resourceType"] ?? "")
        
        let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
        if resourceType == .script && domain.isShieldExpected(.NoScript,
                                                              isPrivateBrowsing: isPrivateBrowsing) {
            self.stats = self.stats.addingScriptBlock()
            DissenterGlobalShieldStats.shared.scripts += 1
            return
        }
        
        var req = URLRequest(url: url)
        req.mainDocumentURL = mainDocumentUrl

        TPStatsBlocklistChecker.shared.isBlocked(request: req, domain: domain, resourceType: resourceType).uponQueue(.main) { listItem in
            if let listItem = listItem {
                if listItem == .https {
                    if mainDocumentUrl.scheme == "https" && url.scheme == "http" && resourceType != .image {
                        // WKWebView will block loading this URL so we can't count it due to mixed content restrictions
                        // Unfortunately, it does not check to see if a content blocker would promote said URL to https
                        // before blocking the load
                        return
                    }
                }
                self.stats = self.stats.create(byAddingListItem: listItem)
                
                // Increase global stats (here due to BlocklistName being in Client and DissenterGlobalShieldStats being
                // in DissenterShared)
                let stats = DissenterGlobalShieldStats.shared
                switch listItem {
                case .ad: stats.adblock += 1
                case .https: stats.httpse += 1
                case .tracker: stats.trackingProtection += 1
                case .image: stats.images += 1
                case .https: stats.httpse += 1
                default:
                    // TODO: #97 Add fingerprinting count here when it is integrated
                    break
                }
            }
        }
    }
}
