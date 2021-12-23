//
//  SiteListVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import HotKey
import Carbon

class SiteListVC: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: - Variables
    
    /// List of sites that will be displayed in this view. Originates from the `Valet` object.
    var sites: [Valet.Site] = []
    
    /// Array that contains various apps that might open a particular site directory.
    var applications: [Application] {
        return App.shared.detectedApplications
    }
    
    /// String that was last searched for. Empty by default.
    var lastSearchedFor = ""
    
    // MARK: - Helper Variables
    
    var selectedSite: Valet.Site? {
        if tableView.selectedRow == -1 {
            return nil
        }
        return sites[tableView.selectedRow]
    }
    
    // MARK: - Display
    
    public static func create(delegate: NSWindowDelegate?) {
        let storyboard = NSStoryboard(name: "Main" , bundle : nil)
        
        let windowController = storyboard.instantiateController(
            withIdentifier: "siteListWindow"
        ) as! SiteListWC
        
        windowController.window!.title = "site_list.title".localized
        windowController.window!.subtitle = "site_list.subtitle".localized
        windowController.window!.delegate = delegate
        windowController.window!.styleMask = [
            .titled, .closable, .resizable, .miniaturizable
        ]
        windowController.window!.minSize = NSSize(width: 550, height: 200)
        windowController.window!.delegate = windowController
        windowController.positionWindowInTopLeftCorner()
        
        App.shared.siteListWindowController = windowController
    }
    
    public static func show(delegate: NSWindowDelegate? = nil) {
        if (App.shared.siteListWindowController == nil) {
            Self.create(delegate: delegate)
        }
        
        App.shared.siteListWindowController!.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        tableView.doubleAction = #selector(self.doubleClicked(sender:))
        if !Valet.shared.sites.isEmpty {
            // Preloaded list
            sites = Valet.shared.sites
            searchedFor(text: lastSearchedFor)
        } else {
            reloadSites()
        }
    }
    
    // MARK: - Async Operations
    
    /**
     Disables the UI so the user cannot interact with it.
     Also shows a spinner to indicate that we're busy.
     */
    private func setUIBusy() {
        progressIndicator.startAnimation(nil)
        tableView.alphaValue = 0.3
        tableView.isEnabled = false
    }
    
    /**
     Re-enables the UI so the user can interact with it.
     */
    private func setUINotBusy() {
        progressIndicator.stopAnimation(nil)
        tableView.alphaValue = 1.0
        tableView.isEnabled = true
    }
    
    /**
     Executes a specific callback and fires the completion callback,
     while updating the UI as required. As long as the completion callback
     does not fire, the app is presumed to be busy and the UI reflects this.
     
     - Parameter execute: Callback of the work that needs to happen.
     - Parameter completion: Callback that is fired when the work is done.
     */
    private func waitAndExecute(_ execute: @escaping () -> Void, completion: @escaping () -> Void = {})
    {
        setUIBusy()
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            execute()
            
            DispatchQueue.main.async { [self] in
                completion()
                setUINotBusy()
            }
        }
    }
    
    // MARK: - Site Data Loading
    
    func reloadSites() {
        waitAndExecute {
            Valet.shared.reloadSites()
        } completion: { [self] in
            sites = Valet.shared.sites
            searchedFor(text: lastSearchedFor)
        }
    }
    
    // MARK: - Table View Delegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sites.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let userCell = tableView.makeView(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "siteItem"), owner: self
        ) as? SiteListCell else { return nil }
        
        userCell.populateCell(with: sites[row])
        
        return userCell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        reloadContextMenu()
    }
    
    @objc func doubleClicked(sender: Any) {
        guard self.selectedSite != nil else {
            return
        }
        
        self.openInBrowser()
    }
    
    // MARK: Secure & Unsecure
    
    @objc public func toggleSecure() {
        let rowToReload = tableView.selectedRow
        let originalSecureStatus = selectedSite!.secured
        let action = selectedSite!.secured ? "unsecure" : "secure"
        let selectedSite = selectedSite!
        let command = "cd '\(selectedSite.absolutePath!)' && sudo \(Paths.valet) \(action) && exit;"
        
        waitAndExecute {
            Shell.run(command, requiresPath: true)
        } completion: { [self] in
            selectedSite.determineSecured(Valet.shared.config.tld)
            if selectedSite.secured == originalSecureStatus {
                Alert.notify(
                    message: "site_list.alerts_status_not_changed.title".localized,
                    info: "site_list.alerts_status_not_changed.desc".localized(command)
                )
            } else {
                let newState = selectedSite.secured ? "secured" : "unsecured"
                LocalNotification.send(
                    title: "site_list.alerts_status_changed.title".localized,
                    subtitle: "site_list.alerts_status_changed.desc"
                        .localized(
                            "\(selectedSite.name!).\(Valet.shared.config.tld)",
                            newState
                        )
                )
            }
            
            tableView.reloadData(forRowIndexes: [rowToReload], columnIndexes: [0])
            tableView.deselectRow(rowToReload)
            tableView.selectRowIndexes([rowToReload], byExtendingSelection: true)
        }
    }
    
    // MARK: Open in Browser & Finder
    
    @objc public func openInBrowser() {
        let prefix = selectedSite!.secured ? "https://" : "http://"
        let url = URL(string: "\(prefix)\(selectedSite!.name!).\(Valet.shared.config.tld)")
        if url != nil {
            NSWorkspace.shared.open(url!)
        } else {
            warnAboutInvalidFolderAction()
        }
    }
    
    @objc public func openInFinder() {
        Shell.run("open '\(selectedSite!.absolutePath!)'")
    }
    
    @objc public func openInTerminal() {
        Shell.run("open -b com.apple.terminal '\(selectedSite!.absolutePath!)'")
    }
    
    @objc public func unlinkSite() {
        guard let site = selectedSite else {
            return
        }
        
        if site.aliasPath == nil {
            return
        }
        
        Alert.confirm(
            onWindow: view.window!,
            messageText: "site_list.confirm_unlink".localized(site.name),
            informativeText: "site_link.confirm_link".localized,
            buttonTitle: "site_list.unlink".localized,
            secondButtonTitle: "Cancel",
            style: .critical,
            onFirstButtonPressed: {
                Shell.run("valet unlink \(site.name!)", requiresPath: true)
                self.reloadSites()
            }
        )
    }
    
    private func warnAboutInvalidFolderAction() {
        _ = Alert.present(
            messageText: "site_list.alert.invalid_folder_name".localized,
            informativeText: "site_list.alert.invalid_folder_name_desc".localized
        )
    }
    
    // MARK: - (Search) Text Field Delegate
    
    func searchedFor(text: String) {
        lastSearchedFor = text
        
        let searchString = text.lowercased()
        
        if searchString.isEmpty {
            sites = Valet.shared.sites
            tableView.reloadData()
            return
        }
        
        sites = Valet.shared.sites.filter({ site in
            return site.name.lowercased().contains(searchString)
        })
        
        tableView.reloadData()
    }
    
    // MARK: - Context Menu
    
    @objc func openWithEditor(sender: EditorMenuItem) {
        guard let editor = sender.editor else { return }
        editor.openDirectory(file: selectedSite!.absolutePath!)
    }
    // MARK: - Deinitialization
    
    deinit {
        print("VC deallocated")
    }
}