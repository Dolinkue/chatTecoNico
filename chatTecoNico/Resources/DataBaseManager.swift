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
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }

}


// MARK: - Account Manager

extension DataBaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool)-> Void)) {
        // corregir error del database por el .
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        // buscamos si el usuario existe
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
                
            }
        }
        completion(true)
        
    }
    
    public func getAllUsers(completion: @escaping(Result<[[String:String]], Error>) -> Void) {
        database.child("user").observeSingleEvent(of: .value) { snapshot,_   in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DataBaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DataBaseError: Error {
        case failedToFetch
    }
    
    
    /// insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { error , _ in
            guard error == nil else {
                print("error to write database")
                completion(false)
                return
            }
            
        }
            
            self.database.child("user").observeSingleEvent(of: .value) { snapshot in
                if var userCollection = snapshot.value as? [[String:String]] {
                    // append to user dictionary
                    
                    let newElement =  [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.emailAddress
                    ]
                    userCollection.append(newElement)
                    
                    self.database.child("user").setValue(userCollection) {error , _ in
                        guard error == nil else {
                            completion(false)
                            print("error to write database")
                            return
                    }
                        completion(true)
                }
                } else {
                    // create that dictionary
                    let newCollection: [[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.emailAddress
                        ]
                    ]
                    
                    self.database.child("user").setValue(newCollection) {error , _ in
                        guard error == nil else {
                            completion(false)
                            print("error to write database")
                            return
                    }
                        completion(true)
                }
            }
        }
    }
}



struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    // una compute property para modificar el valor de el email para poder subir a la base de datos
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
    
}
