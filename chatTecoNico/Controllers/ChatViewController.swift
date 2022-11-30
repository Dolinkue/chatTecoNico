//
//  ChatViewController.swift
//  chatTecoNico
//
//  Created by Nicolas Dolinkue on 30/11/2022.
//

import UIKit
import MessageKit


struct Message: MessageType {
    
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}


struct Sender: SenderType {
    
    var photoUrl: String
    var senderId: String
    var displayName: String
}



class ChatViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    

    
    private var messages = [Message]()
    private var selfSender = Sender(photoUrl: "", senderId: "1", displayName: "carmela")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hola mundo msj")))
        
        view.backgroundColor = .red
        print(selfSender)
        print(messages)
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.reloadData()
        
    }
    
    var currentSender: MessageKit.SenderType {
        selfSender
    }
    

    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
}


