import SwiftUI
import HomeKit

struct HomeKitView: View {
    @EnvironmentObject var homeKitManager: HomeKitManager
    @State private var newHomeName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // --- Homes LIST ---
                if homeKitManager.homeManager.homes.isEmpty {
                    Text("Aucune maison configurée.")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        Section(header: Text("Maisons")) {
                            ForEach(homeKitManager.homeManager.homes, id: \.uniqueIdentifier) { home in
                                Text(home.name)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }

                Divider()

                // --- Found accessories LIST ---
                List {
                    Section(header: Text("Accessoires trouvés")) {
                        if homeKitManager.foundAccessories.isEmpty {
                            Text("Aucun accessoire détecté.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(homeKitManager.foundAccessories, id: \.uniqueIdentifier) { accessory in
                                HStack {
                                    Text(accessory.name)
                                    Spacer()
                                    Button("Add") {
                                        homeKitManager.addAccessoryUsingUrl(name: "Test",url:URL(string:"X-HM://005EBG2PAJPX5")!)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                
                Divider()

                HStack {
                    Button("🔍 Start scanning") {
                        homeKitManager.startScanning()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("🛑 Stop") {
                        homeKitManager.stopScanning()
                    }
                    .buttonStyle(.bordered)
                }

                // --- Add home ---
                HStack {
                    TextField("Nom de la maison", text: $newHomeName)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Ajouter") {
                        if !newHomeName.isEmpty {
                            homeKitManager.addHome(named: newHomeName)
                            newHomeName = ""
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("HomeKit Scanner")
        }
    }
}
