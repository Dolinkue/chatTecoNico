//
//  DataBaseManager.swift
//  chatTecoNico
//
//  Created by Nicolas Dolinkue on 29/11/2022.
//

import Foundation
import FirebaseDatabase


final class DataBaseManager {
    
    static let shared = DataBaseManager()
    
    private let database = Database.database().reference()

}


// MARK: - Account Manager

extension DataBaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool)-> Void)) {
        // buscamos si el usuario existe
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: ".", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
                
            }
        }
        completion(true)
        
    }
    
    
    /// insert new user to database
    public func insertUser(with user: ChatAppUser) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
    }
}



struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    // una compute property para modificar el valor de el email para poder subir a la base de datos
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: ".", with: "-")
        return safeEmail
    }
    
    // let profilePictureUrl: String
}
