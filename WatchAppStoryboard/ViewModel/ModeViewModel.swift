//
//  ModelViewModel.swift
//  WatchAppStoryboard
//
//  Created by Hugo Arnaudeau on 27/11/2025.
//

import Foundation
import Combine


class ModeViewModel : ObservableObject{
    @Published var modes: [Mode] = []{
        didSet{
            savedModes()
        }
    }
    private let storageKey = "saved_modes"
    
    func addModes(_ mode: Mode){
        modes.append(mode)
    }
    
    func deleteMode(at indexSet: IndexSet) {
        modes.remove(atOffsets: indexSet)
        
    }
    
    func updateModes(_ mode: Mode){
        guard let index = modes.firstIndex(where: { $0.id == mode.id }) else { return }
        modes[index] = mode
    }
    
    func savedModes(){
        do{
            let data = try JSONEncoder().encode(modes)
            UserDefaults.standard.set(data, forKey: storageKey)
        }catch{
            print("Erreur lors de la sauvegarde des modes: ", error)
        }
    }
    
    private func loadModes(){
        do{
            if let savedData = UserDefaults.standard.data(forKey: storageKey){
                modes = try JSONDecoder().decode([Mode].self, from: savedData)
            }
        }catch{
            print("Erreur lors de la chargement des modes: ", error)
        }
    }
}
