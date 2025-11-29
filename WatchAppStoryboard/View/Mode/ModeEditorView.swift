//
//  ModeEditorView.swift
//  WatchAppStoryboard

import SwiftUI

struct ModeEditorView: View {
    @EnvironmentObject var modeVM: ModeViewModel
    
    // param passé depuis la liste (optionnel : nil = nouvelle création)
    let modeToEdit: Mode?
    
    // états locaux liés à l'UI
    @State private var name: String = ""
    @State private var temperature: Double = 20
    @State private var brightness: Double = 0.5
    @State private var createdAt: Date?
    
    // init pour initialiser les @State si on édite un mode existant
    init(modeToEdit: Mode? = nil) {
        self.modeToEdit = modeToEdit
        // Ne pas toucher aux @State ici (on ne peut pas), on initialise dans onAppear.
        // Si tu veux initialiser _name directement, il faut utiliser State(initialValue:)
        // Exemple :
        // _name = State(initialValue: modeToEdit?.name ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Nom") {
                    TextField("Nom du mode", text: $name)
                }
                
                Section("Température") {
                    Slider(value: $temperature, in: 10...30, step: 0.5)
                    Text("\(String(format: "%.1f", temperature))°")
                }
                
                Section("Luminosité") {
                    Slider(value: $brightness, in: 0...1)
                    Text("\(Int(brightness * 100)) %")
                }
                
                Button("Sauvegarder") {
                    save()
                }
            }
            .navigationTitle(modeToEdit == nil ? "Nouveau mode" : "Éditer le mode")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        // on laisse la sheet se fermer depuis la vue parent
                        // il faut utiliser un Binding dans la feuille pour fermer depuis ici,
                        // ou utiliser presentationMode:
#if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
                    }
                }
            }
            .onAppear {
                // Ici on initialise les @State à partir du mode à éditer
                if let mode = modeToEdit {
                    name = mode.name
                    temperature = mode.temperature
                    brightness = mode.brightness ?? brightness
                }
            }
        }
    }
    
    private func save() {
        if let existing = modeToEdit {
            let updated = Mode(id: existing.id,
                               name: name,
                               temperature: temperature,
                               brightness: brightness,
                               createdAt: createdAt!)
            modeVM.updateModes(updated)
        } else {
            let newMode = Mode(name: name,
                               temperature: temperature,
                               brightness: brightness,
                               createdAt: createdAt!)
            modeVM.addModes(newMode)
        }
        // La fermeture du sheet se fait côté appelant (ModeListView) via isPresented
        // tu peux ajouter un callback ou utiliser un Binding si tu veux fermer depuis ici.
    }
}
