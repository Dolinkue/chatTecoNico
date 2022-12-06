//
//  StorageManager.swift
//  chatTecoNico
//
//  Created by Nicolas Dolinkue on 30/11/2022.
//

import Foundation
import FirebaseStorage


final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    // Uploads piture to firebase storage y devuelve el url en string
    public func uploadProfilePicture(with data: Data, filename: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(filename)").putData(data) { metadata , error in
            guard error == nil else {
                completion(.failure(StorageError.failedToUpLoad))
                return
            }
            self.storage.child("images/\(filename)").downloadURL { url, error in
                guard let url = url else {
                    print("error cargar")
                    return
                }
                let urlString = url.absoluteString
                print("\(urlString)")
                completion(.success(urlString))
                
            }
        }
    }
    
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
         storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
             guard error == nil else {
                 // failed
                 print("failed to upload data to firebase for picture")
                 completion(.failure(StorageError.failedToUpload))
                 return
             }

             self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                 guard let url = url else {
                     print("Failed to get download url")
                     completion(.failure(StorageError.failedToGetDownloadUrl))
                     return
                 }

                 let urlString = url.absoluteString
                 print("download url returned: \(urlString)")
                 completion(.success(urlString))
             })
         })
     }
    
    public enum StorageError: Error {
        case failedToUpLoad
        case failedtoGetDownLoad
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadURL(for path: String, completion: @escaping(Result<URL,Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else{
                completion(.failure(StorageError.failedtoGetDownLoad))
                return
            }
            
            completion(.success(url))
        }
    }
    
}
