//
//  SettingScreen.swift
//  chatapp
//
//  Created by Kholod Sultan on 26/03/1443 AH.
//

import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

class SettingsScreen: UIViewController {
    let db = Firestore.firestore()
    let imagePicker = UIImagePickerController()
    let storage = Storage.storage()
    
    let profileImage: UIImageView = {
        let pI = UIImageView()
        pI.contentMode = .scaleAspectFit
        pI.clipsToBounds = true
        pI.layer.cornerRadius = 20
        return pI
    }()
    
    let userNameLabel: UILabel = {
        let name = UILabel()
        name.font = UIFont.systemFont(ofSize: 39, weight: .bold)
        name.textColor = .black
        name.textAlignment = .center
        return name
    }()
    
    let userNameStatus: UILabel = {
        let isOnline = UILabel()
        isOnline.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        isOnline.textAlignment = .center
        return isOnline
    }()
    let signOutButton: UIButton = {
        let signOutButton = UIButton(type: .system)
        signOutButton.setTitle("sign out", for: .normal)
        signOutButton.setTitleColor(.white, for: .normal)
        signOutButton.backgroundColor = .systemGray
        signOutButton.layer.cornerRadius = 18
        signOutButton.layer.masksToBounds = true
        return signOutButton
      }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGray6
        readImageFromFirestore()
        setUpImage()
        setUpLabels()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchCurrentUsers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profileImage.frame = CGRect(x: (view.frame.width - 150) / 2, y: 150, width: 150, height: 150)
    }
    
    func setUpImage() {
        profileImage.tintColor  = .systemBlue
        profileImage.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        profileImage.addGestureRecognizer(tapRecognizer)
        
        view.addSubview(profileImage)
    }

    func setUpLabels() {
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userNameLabel)
        userNameLabel.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 20).isActive = true
        userNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        userNameStatus.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userNameStatus)
        userNameStatus.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        userNameStatus.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 3).isActive = true
        
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(signOutButton)
            signOutButton.topAnchor.constraint(equalTo: userNameStatus.bottomAnchor, constant: 16).isActive = true
        signOutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -20).isActive = true
            signOutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 20).isActive = true
            signOutButton.heightAnchor.constraint(equalToConstant:45).isActive = true
            signOutButton.addTarget(self, action: #selector( signOutButtonTapped),for:.touchUpInside)
       
    }
    @objc func signOutButtonTapped(){
        do {
         try Auth.auth().signOut()
        } catch let signOutError as NSError {
         print("Error signing out: %@", signOutError)
        }
        self.navigationController?.popViewController(animated: true)
      }
    
    func setupImagePicker() {
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    @objc func imageTapped() {
        print("Image tapped")
        setupImagePicker()
    }
    
    func saveImageToFirestore(url: String, userFullName: String) {
       
        db.collection("Users").document(userFullName).setData([
            "userImageURL": url,
        ], merge: true) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    
    func readImageFromFirestore(){
        guard let currentUser = Auth.auth().currentUser else {return}
        
        db.collection("Users").whereField("full name", isEqualTo: currentUser.displayName!)
            .addSnapshotListener { (querySnapshot, error) in
                if let e = error {
                    print("There was an issue retrieving data from Firestore. \(e)")
                } else {
                    
                    if let snapshotDocuments = querySnapshot?.documents {
                        for doc in snapshotDocuments {
                            let data = doc.data()
                            
                            if let imageURL = data["userImageURL"] as? String
                            {
                                
                                let httpsReference = self.storage.reference(forURL: imageURL)

                           
                                httpsReference.getData(maxSize: 1 * 1024 * 1024) { data, error in
                                  if let error = error {
                                    // Uh-oh, an error occurred!
                                      print("ERROR GETTING DATA \(error.localizedDescription)")
                                  } else {
                                    // Data for "images/island.jpg" is returned
                                      self.profileImage.image = UIImage(data: data!)
                                  }
                                }
                                
                            } else {
                                print("error converting data")
                                self.profileImage.image = UIImage(systemName: "person.fill.badge.plus")
                                return
                                
                            }
                            
                           
                        }
                    }
                }
            }
    }
    
    
#warning("ADDED NEW ISONLINE AT LINE 105")
    private func fetchCurrentUsers() {
        guard let currentUserName = FirebaseAuth.Auth.auth().currentUser?.displayName else {return}
        db.collection("Users").whereField("full name", isEqualTo: currentUserName)
            .addSnapshotListener { (querySnapshot, error) in
                
                if let e = error {
                    print("There was an issue retrieving data from Firestore. \(e)")
                } else {
                    if let snapshotDocuments = querySnapshot?.documents {
                        for doc in snapshotDocuments {
                            let data = doc.data()
                            if let userName = data["full name"] as? String,
                               let userIsOnline = data["isOnline"] as? String
                            {
                                
                                    
                                    DispatchQueue.main.async {
                                        self.userNameLabel.text = userName
                                        if userIsOnline == "yes" {
                                            self.userNameStatus.text =  "Online"
                                            self.userNameStatus.textColor = .systemGreen
                                        }else{
                                            self.userNameStatus.text =  "Not Online"
                                            self.userNameStatus.textColor = .systemRed
                                        }
                                    }
                             
                                
                            }
                        }
                    }
                }

            }
    }
#warning("END")
}



extension SettingsScreen: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //
        
        guard let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {return}
        guard let d: Data = userPickedImage.jpegData(compressionQuality: 0.5) else { return }
        guard let currentUser = Auth.auth().currentUser else {return}

        
        
         let metadata = StorageMetadata()
         metadata.contentType = "image/png"

        let ref = storage.reference().child("UserProfileImages/\(currentUser.displayName!)/\(currentUser.uid).jpg")
        
         ref.putData(d, metadata: metadata) { (metadata, error) in
             if error == nil {
                 ref.downloadURL(completion: { (url, error) in
                     print("Done, url is \( url )")
                     
                     self.saveImageToFirestore(url: "\(url!)", userFullName: currentUser.displayName!)
                     
                    
                     
                 })
             }else{
                 print("error \(String(describing: error))")
             }
         }

            picker.dismiss(animated: true, completion: nil)
    }
    

    
}
