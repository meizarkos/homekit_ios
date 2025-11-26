import SwiftUI
import HomeKit

struct HomeKitView: View {
    @EnvironmentObject var homeKitManager: HomeKitManager
    @State private var newHomeName: String = ""
    @State private var selectedHome: HMHome?
    
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
                                Button(action: {
                                    selectedHome = home
                                    homeKitManager.printAccessoriesFromHome(home)
                                }) {
                                    HStack {
                                        Label(home.name, systemImage: "house")
                                        Spacer()
                                        Text("\(home.accessories.count)")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                
                Divider()
                
                // --- NOUVEAU : Accessoires de la maison sélectionnée ---
                if let home = selectedHome {
                    List {
                        Section(header: Text("Accessoires de \(home.name)")) {
                            if home.accessories.isEmpty {
                                Text("Aucun accessoire dans cette maison")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(home.accessories, id: \.uniqueIdentifier) { accessory in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(accessory.name)
                                                .font(.headline)
                                            Text(accessory.room?.name ?? "Aucune pièce")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        if !accessory.isReachable {
                                            Text("Hors ligne")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                }
                
                Divider()
                
                // --- Found accessories LIST ---
                List {
                    Section(header: Text("Nouveaux accessoires détectés")) {
                        if homeKitManager.foundAccessories.isEmpty {
                            Text("Aucun nouvel accessoire détecté.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(homeKitManager.foundAccessories, id: \.uniqueIdentifier) { accessory in
                                HStack {
                                    Text(accessory.name)
                                    Spacer()
                                    Button("Add") {
                                        homeKitManager.addAccessoryToHome(accessory)
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
            .onAppear {
                // Sélectionner automatiquement la première maison au démarrage
                if let firstHome = homeKitManager.homeManager.homes.first {
                    selectedHome = firstHome
                    homeKitManager.printAccessoriesFromHome(firstHome)
                }
            }
        }
    }
}
