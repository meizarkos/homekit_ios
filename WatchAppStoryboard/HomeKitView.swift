import SwiftUI
import HomeKit

struct HomeKitView: View {
    @ObservedObject var homeKitManager = HomeKitManager.shared
    @State private var newHomeName: String = ""
    @State private var showingDeleteAlert = false
    @State private var accessoryToDelete: (HMAccessory, HMHome)?
    
    var body: some View {
        NavigationView {
            List {
                // Section des maisons
                if !homeKitManager.homes.isEmpty {
                    Section(header: Text("Maisons")) {
                        ForEach(homeKitManager.homes, id: \.uniqueIdentifier) { home in
                            NavigationLink(destination: ModeListView(name: home.name, temperature: 12, sound: 21, luminosity: 22)) {
                                HStack {
                                    Label(home.name, systemImage: "house")
                                    Spacer()
                                    if home == homeKitManager.homeManager.primaryHome {
                                        Text("Principale")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    homeKitManager.removeHome(home)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                            
                            // Accessoires
                            ForEach(home.accessories, id: \.uniqueIdentifier) { accessory in
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text(accessory.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Button(role: .destructive) {
                                        accessoryToDelete = (accessory, home)
                                        showingDeleteAlert = true
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.leading)
                            }
                        }
                    }
                } else {
                    Section {
                        Text("Aucune maison configurée.")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section des accessoires trouvés
                Section(header: HStack {
                    Text("Accessoires trouvés (\(homeKitManager.foundAccessories.count))")
                    Spacer()
                    Button("🔄") {
                        homeKitManager.refreshAll()
                    }
                }) {
                    if homeKitManager.foundAccessories.isEmpty {
                        Text("Aucun accessoire détecté.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(homeKitManager.foundAccessories, id: \.uniqueIdentifier) { accessory in
                            HStack {
                                Text(accessory.name)
                                Spacer()
                                Button("Ajouter") {
                                    homeKitManager.addAccessoryToHome(accessory)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
                // Section des boutons et champ de texte
                Section {
                    HStack {
                        Button("🔍 Scanner") {
                            homeKitManager.startScanning()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("🛑 Arrêter") {
                            homeKitManager.stopScanning()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("🔄 Rafraîchir") {
                            homeKitManager.refreshAll()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        TextField("Nom de la maison", text: $newHomeName)
                        
                        Button("Ajouter maison") {
                            if !newHomeName.isEmpty {
                                homeKitManager.addHome(named: newHomeName)
                                newHomeName = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle("HomeKit Scanner")
            .alert("Supprimer l'accessoire ?", isPresented: $showingDeleteAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    if let (accessory, home) = accessoryToDelete {
                        homeKitManager.removeAccessory(accessory, from: home)
                    }
                }
            } message: {
                if let (accessory, _) = accessoryToDelete {
                    Text("Voulez-vous vraiment supprimer \(accessory.name) ?")
                }
            }
        }
    }
}
