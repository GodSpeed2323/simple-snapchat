//
//  NewMessageTableViewController.swift
//  simple-snapchat
//
//  Created by Helen on 27/09/2016.
//  Copyright © 2016 University of Melbourne. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate ,UICollectionViewDelegateFlowLayout{

    let cellID = "cellID"
    var messages = [Message]()
    
    // This uid is the partner id
    var partnerId: String?{
        didSet{
            
            let ref = FIRDatabase.database().reference().child("users").child(partnerId!)
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject]{
                 let user = User()
                    user.setValuesForKeys(dictionary)
                    user.id = self.partnerId
                    self.navigationItem.title = user.name
                }
                }, withCancel: nil)

        }
    }
    
    func observeMessages(){
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let pid = partnerId else {
            return
        }
        let userMsgRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(pid)
        userMsgRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messageRef = FIRDatabase.database().reference().child("messages").child(messageId)
            
            messageRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: AnyObject] else{return}
                let message = Message()
                message.setValuesForKeys(dictionary)
                self.messages.append(message)
   
                DispatchQueue.global().async {
                    
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                    }
                }
                }, withCancel: nil)
            
            }, withCancel: nil)
        
    
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    let sendButton:UIButton = {
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(UIColor(red: 102, green: 178, blue: 255), for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        return sendButton
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Add top padding for collections
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(MessageCell.self, forCellWithReuseIdentifier: cellID)
        collectionView?.backgroundColor = UIColor.white
        collectionView?.keyboardDismissMode = .interactive
        observeMessages()

        //setupKeyboardObservers()
        
    }
    
    /*
        Add the animation for intext container and keyboard
     */
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    lazy var inputContainerView: UIView = {
    
        let containerView = UIView()
        containerView.frame = CGRect(x:0, y:0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        //-----------------------------------Add send button-----------------------------------
        self.sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(self.sendButton)
        //x,y,w,h constraint anchors for send button
        self.sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        self.sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.sendButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        self.sendButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        //-----------------------------------Add input textfield--------------------------------
        containerView.addSubview(self.inputTextField)
        //x,y,w,h constraint anchors for input textfield
        self.inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: self.sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        //-------------------Add a line separating input container and messages view --------------
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(red:220, green: 220, blue: 255)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        //x,y,w,h constraint anchors for separatorLine
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        //-----------------------------------Add upload image icon--------------------------------
        l
        return containerView
    }()
    
    override var inputAccessoryView: UIView?{
        get{
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
    
        get{
            return true
        }
    }

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupKeyboardObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
    }
    
    func handleKeyboardWillShow(notification: Notification){
        //get keyboard height
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let height = keyboardFrame.cgRectValue.height
        
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let duration = keyboardDuration.doubleValue
        
        containerViewBottomAnchor?.constant = -height
        
        UIView.animate(withDuration: duration) { 
            self.view.layoutIfNeeded()
        }
    }
    
    func handleKeyboardWillHide(notification: Notification){
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let duration = keyboardDuration.doubleValue
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! MessageCell
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        // Modify the bubbleView's width
        cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: message.text!).width + 32
        
        return cell
    }
    
    private func setupCell(cell: MessageCell, message: Message){
        
        // Incoming and outgoing messages
        if message.fromID == FIRAuth.auth()?.currentUser?.uid {
            // outgoing blue bubble
            cell.bubbleView.backgroundColor = MessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        }else{
            // incoming gray bubble
            cell.bubbleView.backgroundColor = MessageCell.grayColor
            cell.textView.textColor = UIColor.black
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //Change the cell height according to the text length
        var height: CGFloat = 80
        
        if let text = messages[indexPath.item].text{
            height = estimateFrameForText(text: text).height + 20
        }
        return CGSize(width: view.frame.width, height: height)
    }
    
    // Get the rec size for input text
    private func estimateFrameForText(text: String) -> CGRect{
        // This width is equal to the width of bubble view
        let size = CGSize(width:200, height:1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
        
    }
    
    // Send button tapped function
    func handleSend(){
        self.inputTextField.endEditing(true)
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let fromID = FIRAuth.auth()!.currentUser!.uid
        let toID = partnerId!
        let timestamp = Int(NSDate().timeIntervalSince1970)
        let values = ["text": inputTextField.text!, "toID": toID, "fromID": fromID, "timestamp": timestamp] as [String : Any]
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil{
                print(error)
                return
            }
            //Update user-messages for both sender and receiver
            let senderMsgRef = FIRDatabase.database().reference().child("user-messages").child(fromID).child(toID)
            senderMsgRef.updateChildValues([childRef.key : 1])
            let receiverMsgRef = FIRDatabase.database().reference().child("user-messages").child(toID).child(fromID)
            receiverMsgRef.updateChildValues([childRef.key : 1])
    }
        
        self.inputTextField.text = nil
    }


    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }


}




