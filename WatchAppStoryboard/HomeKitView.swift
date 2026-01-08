


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
                            NavigationLink(destination: ModeListView(name: home.name, temperature: 20, sound: 50, luminosity: 70)) {
                                HStack {
                                    Label(home.name, systemImage: "house")
                                    Spacer()
                                    Text("\(home.accessories.count)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    if home == homeKitManager.homeManager.primaryHome {
                                        Text("Principale")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .padding(.leading, 4)
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
                                    Image(systemName: getAccessoryIcon(for: accessory))
                                        .foregroundColor(getAccessoryColor(for: accessory))
                                    VStack(alignment: .leading) {
                                        Text(accessory.name)
                                            .font(.subheadline)
                                        Text(accessory.room?.name ?? "Aucune pièce")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    if !accessory.isReachable {
                                        Text("Hors ligne")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
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
                    Text("Nouveaux accessoires (\(homeKitManager.foundAccessories.count))")
                    Spacer()
                    Button("Rafraîchir") {
                        homeKitManager.refreshAll()
                    }
                    .font(.caption)
                }) {
                    if homeKitManager.foundAccessories.isEmpty {
                        Text("Aucun accessoire détecté.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(homeKitManager.foundAccessories, id: \.uniqueIdentifier) { accessory in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(accessory.name)
                                    Text("Non apparié")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                                Button("Ajouter") {
                                    homeKitManager.addAccessoryToHome(accessory)
                                }
                                .buttonStyle(.borderedProminent)
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
                        
                        Button("Ajouter") {
                            if !newHomeName.isEmpty {
                                homeKitManager.addHome(named: newHomeName)
                                newHomeName = ""
                            }
                        }
                        .disabled(newHomeName.isEmpty)
                    }
                }
            }
            .navigationTitle("HomeKit")
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
            .onAppear {
                // Charger les maisons au démarrage
                homeKitManager.refreshAll()
            }
        }
    }
    
    private func getAccessoryIcon(for accessory: HMAccessory) -> String {
        switch accessory.category.categoryType {
        case HMAccessoryCategoryTypeLightbulb:
            return "lightbulb.fill"
        case HMAccessoryCategoryTypeSwitch:
            return "power"
        case HMAccessoryCategoryTypeOutlet:
            return "outlet"
        case HMAccessoryCategoryTypeFan:
            return "fan.fill"
        case HMAccessoryCategoryTypeThermostat:
            return "thermometer"
        default:
            return "square.grid.2x2"
        }
    }
    
    private func getAccessoryColor(for accessory: HMAccessory) -> Color {
        if !accessory.isReachable {
            return .gray
        }
        
        switch accessory.category.categoryType {
        case HMAccessoryCategoryTypeLightbulb:
            return .yellow
        case HMAccessoryCategoryTypeSwitch:
            return .blue
        case HMAccessoryCategoryTypeOutlet:
            return .orange
        case HMAccessoryCategoryTypeFan:
            return .cyan
        case HMAccessoryCategoryTypeThermostat:
            return .red
        default:
            return .gray
        }
    }
}
