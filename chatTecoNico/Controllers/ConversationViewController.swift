//
//  ViewController.swift
//  chatTecoNico
//
//  Created by Nicolas Dolinkue on 28/11/2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}


class ConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private var chat = ""
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTabComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        setupTable()
        fetchConversations()
        startListeningForConversations()
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return}
        let safeEmail = DataBaseManager.safeEmail(emailAddress: email)
        DataBaseManager.shared.getAllConversations(for: safeEmail) { [weak self]result in
            switch result {
            case .success(let conversation):
                guard !conversation.isEmpty else {
                    return
                }
                self?.conversations = conversation
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("error\(error)")
            }
        }
    }
    
    @objc private func didTabComposeButton() {
        
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            self?.creatNewConversation(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func creatNewConversation(result: [String:String]) {
        guard let name = result["name"], let email = result["email"] else {
            return
        }
        
        // mandamos a la sala de chat
        let vc = ChatViewController(with: email, id: "0")
        vc.isNewConversation = true
        self.chat = email
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // agrega la tabla los layouts para que se vea
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }

    private func validateAuth() {
        
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
           

    }
    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    private func fetchConversations() {
        // traer los dialogos
        tableView.isHidden = false
    }
    
}

extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        
        let vc = ChatViewController(with: model.otherUserEmail,id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
