// What `capsjump profiles --json` prints for each profile: no account when nobody is signed
// in (never a placeholder), the folders that share its window label, and the fields a site
// in it writes, which are `SiteAccount.fields`, the rule the window and the starter use.

import Foundation
import Testing
@testable import CapsJumpCore

@Suite struct ProfileListingTests {
    @Test func listsEachProfileInChromeOrder() throws {
        let c = try catalog()
        let listing = c.listing
        #expect(listing.profiles.map(\.folder) == c.profiles.map(\.directory))
        let first = try #require(listing.profiles.first)
        #expect(first == ProfileListing.Entry(
            folder: "Profile 1", account: "alex@acme.dev", name: "acme.dev", windowLabel: "Alex (acme.dev)",
            sharedWith: [], site: .init(account: "alex@acme.dev", profile: "Profile 1")
        ))
    }

    @Test func aSignedOutProfileHasNoAccount() throws {
        let entry = try #require(try catalog().listing.profiles.first { $0.folder == "Profile 26" })
        #expect(entry.account == nil)
        #expect(entry.site == .init(account: "kim@initech.com", profile: nil))
    }

    @Test func siteFieldsAreTheRuleTheWindowUses() throws {
        let c = try catalog()
        for (profile, entry) in zip(c.profiles, c.listing.profiles) {
            let (account, folder) = SiteAccount.fields(for: profile, in: c)
            #expect(entry.site == .init(account: account, profile: folder))
        }
    }

    @Test func aSharedLabelNamesTheOtherFolders() {
        let c = ProfileCatalog(profiles: [
            ChromeProfile(directory: "A", name: "Work", email: "", givenName: ""),
            ChromeProfile(directory: "B", name: "Work", email: "", givenName: ""),
            ChromeProfile(directory: "C", name: "Home", email: "", givenName: ""),
        ])
        #expect(c.listing.profiles.map(\.sharedWith) == [["B"], ["A"], []])
    }

    @Test func printsNullForNoAccountAndLeavesOutAProfileTheSiteDoesNotNeed() throws {
        let c = ProfileCatalog(profiles: [ChromeProfile(directory: "Default", name: "Home", email: "", givenName: "")])
        #expect(try JSONOutput.render(c.listing) == """
        {
          "profiles" : [
            {
              "account" : null,
              "folder" : "Default",
              "name" : "Home",
              "sharedWith" : [

              ],
              "site" : {
                "account" : "Home"
              },
              "windowLabel" : "Home"
            }
          ]
        }
        """)
    }
}
