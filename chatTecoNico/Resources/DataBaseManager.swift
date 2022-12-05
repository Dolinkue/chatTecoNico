//
//  DataBaseManager.swift
//  chatTecoNico
//
//  Created by Nicolas Dolinkue on 29/11/2022.
//

import Foundation
import FirebaseDatabase
import CoreLocation
import MessageKit
import UIKit



final class DataBaseManager {
    
    static let shared = DataBaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }

}

extension DataBaseManager {
    public func getDataFor(path:String, completion: @escaping (Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DataBaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
        
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


//MARK: - Sending Messages/ Conversation

extension DataBaseManager {
    /// Creates a new conversation with target user emamil and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
            
            guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
                  let currentName = UserDefaults.standard.value(forKey: "name") as? String
                 else {
                    return
            }

            let safeEmail = DataBaseManager.safeEmail(emailAddress: currentEmail)
            

            let ref = database.child("\(safeEmail)")

            ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
                guard var userNode = snapshot.value as? [String: Any] else {
                    completion(false)
                    print("user not found")
                    return
                }

                let messageDate = firstMessage.sentDate
                let dateString = ChatViewController.dateFormatter.string(from: messageDate)

                var message = ""

                switch firstMessage.kind {
                case .text(let messageText):
                    message = messageText
                case .attributedText(_):
                    break
                case .photo(_):
                    break
                case .video(_):
                    break
                case .location(_):
                    break
                case .emoji(_):
                    break
                case .audio(_):
                    break
                case .contact(_):
                    break
                case .custom(_), .linkPreview(_):
                    break
                }

                let conversationId = "conversation_\(firstMessage.messageId)"

                let newConversationData: [String: Any] = [
                    "id": conversationId,
                    "other_user_email": otherUserEmail,
                    "name": name,
                    "latest_message": [
                        "date": dateString,
                        "message": message,
                        "is_read": false
                    ]
                ]

                let recipient_newConversationData: [String: Any] = [
                    "id": conversationId,
                    "other_user_email": safeEmail,
                    "name": currentName,
                    "latest_message": [
                        "date": dateString,
                        "message": message,
                       "is_read": false
                    ]
                ]
                // Update recipient conversaiton entry
                self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                    if var conversatoins = snapshot.value as? [[String: Any]] {
                        // append
                        conversatoins.append(recipient_newConversationData)
                        self?.database.child("\(otherUserEmail)/conversations").setValue(conversatoins)
                    }
                    else {
                        // create
                        self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                    }
                })

                // Update current user conversation entry
                if var conversations = userNode["conversations"] as? [[String: Any]] {
                    // conversation array exists for current user
                    // you should append
                    conversations.append(newConversationData)
                    userNode["conversations"] = conversations
                    ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }

                        self?.finishCreatingConversation(name: name,
                                                         conversationID: conversationId,
                                                         firstMessage: firstMessage,
                                                         completion: completion)
                    })
                }
                else {
                    // conversation array does NOT exist
                    // create it
                    userNode["conversations"] = [
                        newConversationData
                    ]

                    ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }

                        self?.finishCreatingConversation(name: name,
                                                         conversationID: conversationId,
                                                         firstMessage: firstMessage,
                                                         completion: completion)
                    })
                }
            })
        }

    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
    //        {
    //            "id": String,
    //            "type": text, photo, video,
    //            "content": String,
    //            "date": Date(),
    //            "sender_email": String,
    //            "isRead": true/false,
    //        }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)

            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_), .photo(_), .video(_), .location(_), .emoji(_), .audio(_), .contact(_),.custom(_), .linkPreview(_):
                break
            }

            guard let myEmmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }

            let currentUserEmail = DataBaseManager.safeEmail(emailAddress: myEmmail)

            let collectionMessage: [String: Any] = [
                "id": firstMessage.messageId,
                "type": firstMessage.kind.messageKingString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]

            let value: [String: Any] = [
                "messages": [
                    collectionMessage
                ]
            ]

            print("adding convo: \(conversationID)")

            database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                completion(true)
            })
        }
    
//        /// Fetches and returns all conversations for the user with passed in email
        public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
            database.child("\(email)/conversations").observe(.value, with: { snapshot in
                guard let value = snapshot.value as? [[String: Any]] else{
                    completion(.failure(DataBaseError.failedToFetch))
                    return
                }

                let conversations: [Conversation] = value.compactMap({ dictionary in
                    guard let conversationId = dictionary["id"] as? String,
                        let name = dictionary["name"] as? String,
                        let otherUserEmail = dictionary["other_user_email"] as? String,
                        let latestMessage = dictionary["latest_message"] as? [String: Any],
                        let date = latestMessage["date"] as? String,
                        let message = latestMessage["message"] as? String,
                        let isRead = latestMessage["is_read"] as? Bool else {
                            return nil
                    }

                    let latestMmessageObject = LatestMessage(date: date,
                                                             text: message,
                                                             isRead: isRead)
                    return Conversation(id: conversationId,
                                        name: name,
                                        otherUserEmail: otherUserEmail,
                                        latestMessage: latestMmessageObject)
                })

                completion(.success(conversations))
            })
    }

        /// Gets all mmessages for a given conversatino
        public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
            database.child("\(id)/messages").observe(.value, with: { snapshot in
                guard let value = snapshot.value as? [[String: Any]] else{
                    completion(.failure(DataBaseError.failedToFetch))
                    return
                }

                let messages: [Message] = value.compactMap({ dictionary in
                    guard let name = dictionary["name"] as? String,
                        let isRead = dictionary["is_read"] as? Bool,
                        let messageID = dictionary["id"] as? String,
                        let content = dictionary["content"] as? String,
                        let senderEmail = dictionary["sender_email"] as? String,
                        let type = dictionary["type"] as? String,
                        let dateString = dictionary["date"] as? String,
                        let date = ChatViewController.dateFormatter.date(from: dateString)else {
                            return nil
                    }
                  //  var kind: MessageKind?
//                    if type == "photo" {
//                        // photo
//                        guard let imageUrl = URL(string: content),
//                        let placeHolder = UIImage(systemName: "plus") else {
//                            return nil
//                        }
//                        let media = Media(url: imageUrl,
//                                          image: nil,
//                                          placeholderImage: placeHolder,
//                                          size: CGSize(width: 300, height: 300))
//                        kind = .photo(media)
//                    }
//                    else if type == "video" {
//                        // photo
//                        guard let videoUrl = URL(string: content),
//                            let placeHolder = UIImage(named: "video_placeholder") else {
//                                return nil
//                        }
//
//                        let media = Media(url: videoUrl,
//                                          image: nil,
//                                          placeholderImage: placeHolder,
//                                          size: CGSize(width: 300, height: 300))
//                        kind = .video(media)
//                    }
//                    else if type == "location" {
//                        let locationComponents = content.components(separatedBy: ",")
//                        guard let longitude = Double(locationComponents[0]),
//                            let latitude = Double(locationComponents[1]) else {
//                            return nil
//                        }
//                        print("Rendering location; long=\(longitude) | lat=\(latitude)")
//                        let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
//                                                size: CGSize(width: 300, height: 300))
//                        kind = .location(location)
//                    }
//                    else {
//                        kind = .text(content)
//                    }
                    
                    
//                    guard let finalKind = kind else {
//                        return nil
//                    }

                    let sender = Sender(photoUrl: "",
                                        senderId: senderEmail,
                                        displayName: name)

                    return Message(sender: sender,
                                   messageId: messageID,
                                   sentDate: date,
                                   kind: .text(content))
                })

                completion(.success(messages))
            })
        }

        /// Sends a message with target conversation and message
        public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
            // add new message to messages
            // update sender latest message
            // update recipient latest message
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }

            let currentEmail = DataBaseManager.safeEmail(emailAddress: myEmail)

            database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                guard let strongSelf = self else {
                    return
                }

                guard var currentMessages = snapshot.value as? [[String: Any]] else {
                    completion(false)
                    return
                }

                let messageDate = newMessage.sentDate
                let dateString = ChatViewController.dateFormatter.string(from: messageDate)

                var message = ""
                switch newMessage.kind {
                case .text(let messageText):
                    message = messageText
                case .attributedText(_):
                    break
                case .photo(let mediaItem):
                    if let targetUrlString = mediaItem.url?.absoluteString {
                        message = targetUrlString
                    }
                    break
                case .video(let mediaItem):
                    if let targetUrlString = mediaItem.url?.absoluteString {
                        message = targetUrlString
                    }
                    break
                case .location(let locationData):
                    let location = locationData.location
                    message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                    break
                case .emoji(_):
                    break
                case .audio(_):
                    break
                case .contact(_):
                    break
                case .custom(_), .linkPreview(_):
                    break
                }

                guard let myEmmail = UserDefaults.standard.value(forKey: "email") as? String else {
                    completion(false)
                    return
                }

                let currentUserEmail = DataBaseManager.safeEmail(emailAddress: myEmmail)

                let newMessageEntry: [String: Any] = [
                    "id": newMessage.messageId,
                    "type": newMessage.kind.messageKingString,
                    "content": message,
                    "date": dateString,
                    "sender_email": currentUserEmail,
                    "is_read": false,
                    "name": name
                ]

                currentMessages.append(newMessageEntry)

                strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }

                    strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                        var databaseEntryConversations = [[String: Any]]()
                        let updatedValue: [String: Any] = [
                            "date": dateString,
                            "is_read": false,
                            "message": message
                        ]

                        if var currentUserConversations = snapshot.value as? [[String: Any]] {
                            var targetConversation: [String: Any]?
                            var position = 0

                            for conversationDictionary in currentUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }

                            if var targetConversation = targetConversation {
                                targetConversation["latest_message"] = updatedValue
                                currentUserConversations[position] = targetConversation
                                databaseEntryConversations = currentUserConversations
                            }
                            else {
                                let newConversationData: [String: Any] = [
                                    "id": conversation,
                                    "other_user_email": DataBaseManager.safeEmail(emailAddress: otherUserEmail),
                                    "name": name,
                                    "latest_message": updatedValue
                                ]
                                currentUserConversations.append(newConversationData)
                                databaseEntryConversations = currentUserConversations
                            }
                        }
                        else {
                            let newConversationData: [String: Any] = [
                                "id": conversation,
                                "other_user_email": DataBaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            databaseEntryConversations = [
                                newConversationData
                            ]
                        }

                        strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }


                            // Update latest message for recipient user
                            strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                                let updatedValue: [String: Any] = [
                                    "date": dateString,
                                    "is_read": false,
                                    "message": message
                                ]
                                var databaseEntryConversations = [[String: Any]]()

                                guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                    return
                                }

                                if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                    var targetConversation: [String: Any]?
                                    var position = 0

                                    for conversationDictionary in otherUserConversations {
                                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                            targetConversation = conversationDictionary
                                            break
                                        }
                                        position += 1
                                    }

                                    if var targetConversation = targetConversation {
                                        targetConversation["latest_message"] = updatedValue
                                        otherUserConversations[position] = targetConversation
                                        databaseEntryConversations = otherUserConversations
                                    }
                                    else {
                                        // failed to find in current colleciton
                                        let newConversationData: [String: Any] = [
                                            "id": conversation,
                                            "other_user_email": DataBaseManager.safeEmail(emailAddress: currentEmail),
                                            "name": currentName,
                                            "latest_message": updatedValue
                                        ]
                                        otherUserConversations.append(newConversationData)
                                        databaseEntryConversations = otherUserConversations
                                    }
                                }
                                else {
                                    // current collection does not exist
                                    let newConversationData: [String: Any] = [
                                        "id": conversation,
                                        "other_user_email": DataBaseManager.safeEmail(emailAddress: currentEmail),
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    databaseEntryConversations = [
                                        newConversationData
                                    ]
                                }

                                strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                                    guard error == nil else {
                                        completion(false)
                                        return
                                    }

                                    completion(true)
                                })
                            })
                        })
                    })
                }
            })
        }

        public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
//            guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
//                return
//            }
//            let safeEmail = DataBaseManager.safeEmail(emailAddress: email)
//
//            print("Deleting conversation with id: \(conversationId)")
//
//            // Get all conversations for current user
//            // delete conversation in collection with target id
//            // reset those conversations for the user in database
//            let ref = database.child("\(safeEmail)/conversations")
//            ref.observeSingleEvent(of: .value) { snapshot in
//                if var conversations = snapshot.value as? [[String: Any]] {
//                    var positionToRemove = 0
//                    for conversation in conversations {
//                        if let id = conversation["id"] as? String,
//                            id == conversationId {
//                            print("found conversation to delete")
//                            break
//                        }
//                        positionToRemove += 1
//                    }
//
//                    conversations.remove(at: positionToRemove)
//                    ref.setValue(conversations, withCompletionBlock: { error, _  in
//                        guard error == nil else {
//                            completion(false)
//                            print("faield to write new conversatino array")
//                            return
//                        }
//                        print("deleted conversaiton")
//                        completion(true)
//                    })
//                }
//            }
        }

        public func conversationExists(iwth targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
//            let safeRecipientEmail = DataBaseManager.safeEmail(emailAddress: targetRecipientEmail)
//            guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
//                return
//            }
//            let safeSenderEmail = DataBaseManager.safeEmail(emailAddress: senderEmail)
//
//            database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
//                guard let collection = snapshot.value as? [[String: Any]] else {
//                    completion(.failure(DataBaseError.failedToFetch))
//                    return
//                }
//
//                // iterate and find conversation with target sender
//                if let conversation = collection.first(where: {
//                    guard let targetSenderEmail = $0["other_user_email"] as? String else {
//                        return false
//                    }
//                    return safeSenderEmail == targetSenderEmail
//                }) {
//                    // get id
//                    guard let id = conversation["id"] as? String else {
//                        completion(.failure(DataBaseError.failedToFetch))
//                        return
//                    }
//                    completion(.success(id))
//                    return
//                }
//
//                completion(.failure(DataBaseError.failedToFetch))
//                return
//            })
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
