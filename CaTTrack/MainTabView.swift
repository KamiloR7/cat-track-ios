//
//  MainTabView.swift
//  CaTTrack
//
//  The "footer" mentioned in the spec is a UITabBarController in
//  UIKit terms. SwiftUI's TabView is its declarative wrapper.
//
//  Three tabs: Home / + (Add Log) / Calendar.
//
//  The middle "+" tab does not display a screen; tapping it opens
//  LogEntrySheet as a modal and immediately snaps the selection
//  back to Home. This is the standard SwiftUI workaround for the
//  "central action button" pattern.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    
    enum Tab: Hashable {
        case home, add, calendar
    }
    
    @State private var selection: Tab = .home
    @State private var isLogSheetPresented: Bool = false
    
    var body: some View {
        TabView(selection: $selection) {
            
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            // Empty placeholder for the "+" tab. Selecting this tag
            // triggers the modal via .onChange below.
            Color.clear
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(Tab.add)
            
            CalendarTabView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)
        }
        .onChange(of: selection) { _, newValue in
            if newValue == .add {
                isLogSheetPresented = true
                // Snap back so the placeholder Color.clear is never shown.
                // DispatchQueue defers until after the current run loop tick.
                DispatchQueue.main.async {
                    selection = .home
                }
            }
        }
        .sheet(isPresented: $isLogSheetPresented) {
            LogEntrySheet()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.previewMock)
        .modelContainer(for: [User.self, Pet.self, PetGoals.self, LogEntry.self, Item.self],
                        inMemory: true)
}
