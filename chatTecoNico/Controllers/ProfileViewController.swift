//
//  ProfileViewController.swift
//  chatTecoNico
//
//  Created by Nicolas Dolinkue on 28/11/2022.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let data = ["Log out"]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    


}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // alert para avisar antes de salir
        
        let alert = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive,handler: { [weak self]_ in
            
            guard let strongSelf = self else {return}
            
            do {
               try FirebaseAuth.Auth.auth().signOut()
                
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: true)
                
            }
            catch {
                print("error logout")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel))
    
        present(alert, animated: true)
    }
    
}
