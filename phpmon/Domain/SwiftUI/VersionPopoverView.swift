//
//  VersionPopoverView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct VersionPopoverView: View {

    @State var site: ValetSite

    @State var validPhpVersions: [PhpVersionNumber]

    @State var parent: NSPopover!

    func getTitle() -> String {
        if site.composerPhpSource == .unknown {
            return "alert.composer_php_requirement.unable_to_determine".localized
        }

        return "alert.composer_php_requirement.title".localized(
            "\(site.name).\(Valet.shared.config.tld)",
            site.composerPhp
        )
    }

    func getSource() -> String {
        var information = ""

        if site.isolatedPhpVersion != nil {
            information += "alert.composer_php_isolated.desc".localized(
                site.isolatedPhpVersion!.versionNumber.homebrewVersion,
                PhpEnv.phpInstall.version.short
            )
            information += "\n\n"
        }

        information += "alert.composer_php_requirement.type.\(site.composerPhpSource.rawValue)"
            .localized

        return information
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(getTitle())
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            Text(getSource())
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
            if !validPhpVersions.isEmpty {
                // Suggestions for alternative PHP versions
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 5) {
                        Image(systemName: "info.circle.fill")
                            .renderingMode(.template)
                            .foregroundColor(Color("AppColor"))
                        Text("alert.php_suggestions".localized)
                            .font(.subheadline)
                            .foregroundColor(Color("AppColor"))

                    }.padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                    HStack {
                        ForEach(validPhpVersions, id: \.self) { version in
                            Button("site_link.switch_to_php".localized(version.homebrewVersion), action: {
                                MainMenu.shared.switchToPhpVersion(version.homebrewVersion)
                                parent?.close()
                            })
                        }
                    }
                }
            } else {
                if site.composerPhpSource != .unknown {
                    HStack(alignment: .center, spacing: 5) {
                        Image(systemName: "checkmark.seal.fill")
                            .renderingMode(.template)
                            .foregroundColor(Color("IconColorGreen"))
                        Text("alert.php_version_ideal".localized)
                            .font(.subheadline)
                            .foregroundColor(Color("IconColorGreen"))
                    }.padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Image(systemName: "questionmark.circle.fill")
                            .renderingMode(.template)
                            .foregroundColor(Color.secondary)
                        Text("alert.unable_to_determine_is_fine".localized)
                            .font(.subheadline)
                            .foregroundColor(Color.secondary)
                    }.padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                }
            }
        }.frame(width: 400, height: nil, alignment: .center)
            .padding(20)
            .background(
                Color(NSColor.windowBackgroundColor).padding(-80)
            )
    }
}

struct VersionPopoverView_Previews: PreviewProvider {
    static var previews: some View {
        VersionPopoverView(
            site: ValetSite(
                fakeWithName: "amazingwebsite",
                tld: "test",
                secure: true,
                path: "/path/to/site",
                linked: true,
                constraint: ""
            ),
            validPhpVersions: [],
            parent: nil
        )
        VersionPopoverView(
            site: ValetSite(
                fakeWithName: "amazingwebsite",
                tld: "test",
                secure: true,
                path: "/path/to/site",
                linked: true,
                constraint: "^8.1"
            ),
            validPhpVersions: [],
            parent: nil
        )
        VersionPopoverView(
            site: ValetSite(
                fakeWithName: "anothersite",
                tld: "test",
                secure: true,
                path: "/path/to/site",
                linked: true,
                constraint: "^8.0"
            ),
            validPhpVersions: [
                PhpVersionNumber(major: 8, minor: 0, patch: 0),
                PhpVersionNumber(major: 8, minor: 1, patch: 0)
            ],
            parent: nil
        )
    }
}
