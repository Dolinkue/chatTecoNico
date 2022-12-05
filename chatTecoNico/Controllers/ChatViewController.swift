//
//  ChatViewController.swift
//  chatTecoNico
//
//  Created by Nicolas Dolinkue on 30/11/2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView


struct Message: MessageType {
    
   public var sender: SenderType
   public var messageId: String
   public var sentDate: Date
   public var kind: MessageKind
}

extension MessageKind {
    var messageKingString: String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}


struct Sender: SenderType {
    
   public var photoUrl: String
   public var senderId: String
   public var displayName: String
}



class ChatViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    public let otherUserEmail: String
    private let conversationId: String?
    private var messages = [Message]()
    
    private var selfSender: Sender?  {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return nil}
        let safeEmail = DataBaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoUrl: "",
                      senderId: safeEmail,
                      displayName: "me")
    }
    

    
    init(with email: String, id: String) {
        let safeEmail = DataBaseManager.safeEmail(emailAddress: email)
        self.otherUserEmail = safeEmail
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
        print(messages)
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.reloadData()
        print(messages)
        
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DataBaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                print("success in getting messages: \(messages)")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self?.messages = messages

                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()

                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    var currentSender: MessageKit.SenderType {
        selfSender ?? Sender(photoUrl: "", senderId: "", displayName: "error")
    }
    

    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
//        guard text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageId = createMessageId() else {
//            return
//        }
        let selfSender = self.selfSender
        let messageId = createMessageId()
        
        print(text)
        let message = Message(sender: selfSender!, messageId: messageId!, sentDate: Date(), kind: .text(text))
        // send msj
        if isNewConversation {
            // create convo in databse
            
            DataBaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self]success in
                if success {
                    print("msj send")
                    self?.isNewConversation = false
                }else {
                    print("erro to send")
                }
            }
            
        } else {
            // appen on existing
            guard let conversationId = conversationId, let name = self.title  else {
                return
            }
            DataBaseManager.shared.sendMessage(to: conversationId, otherUserEmail: "", name: name, newMessage: message) { succes in
                if succes {
                    print("msj send")
                } else {
                    print("faild to send")
                }
                
            }
        }
    }
    
    private func createMessageId() ->  String? {
        // data, otherUserEmail, senderemail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrenteEmail = DataBaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrenteEmail)_\(dateString)"
        
        return newIdentifier
    }
}
