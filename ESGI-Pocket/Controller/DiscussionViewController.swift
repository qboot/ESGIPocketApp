//
//  DiscussionViewController.swift
//  ESGI-Pocket
//
//  Created by pierre piron on 18/06/2018.
//  Copyright © 2018 pierre piron. All rights reserved.
//

import UIKit
import SwiftyJSON

class DiscussionViewController: UIViewController {

    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    var defaultBottomConstraint: CGFloat = 0
    var idDiscussion = ""
    var nameDiscussion = ""
    var messages: [Message] = []

    @IBOutlet weak var discussionNameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.discussionNameLabel.text = nameDiscussion
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))

        defaultBottomConstraint = bottomConstraint.constant

        NotificationCenter.default.addObserver(self, selector: #selector(DiscussionViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DiscussionViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        self.messageTextField.delegate = self
        //self.containerView.layer.cornerRadius = self.containerView.frame.width / 2
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UINib(nibName: "MessageViewCell", bundle: nil), forCellReuseIdentifier: "messageCell")
        self.tableView.separatorStyle = .none
        self.tableView?.rowHeight = 105.0
        self.tableView.allowsSelection = false
        loadMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    func loadMessages() {
        let messageProvider = MessageProvider()
        messageProvider.getThreadMessages(threadId: self.idDiscussion, callback: { response in
            if response.count == 0 {
                return
            }
            self.messages = response
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.scrollToBottom()
                self.tableView.isHidden = false
                let indexPath = IndexPath(row: self.messages.count-1, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        })
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double {
            if bottomConstraint.constant == defaultBottomConstraint {
                if #available(iOS 11.0, *) {
                    bottomConstraint.constant = keyboardSize.height + defaultBottomConstraint - view.safeAreaInsets.bottom
                } else {
                    bottomConstraint.constant = keyboardSize.height + defaultBottomConstraint
                }

                UIView.animate(withDuration: duration) {
                    self.view.layoutIfNeeded()
                }

                self.scrollToBottom()
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil,
            let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double {
            if bottomConstraint.constant != defaultBottomConstraint {
                bottomConstraint.constant = defaultBottomConstraint
                UIView.animate(withDuration: duration) {
                    self.view.layoutIfNeeded()
                }

                self.scrollToBottom()
            }
        }
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func sendMessageButtonPressed(_ sender: Any) {
        sendMessage()
    }

    func sendMessage() {
        messageTextField.resignFirstResponder()

        guard let message = self.messageTextField.text else {
            return
        }

        if message.count == 0 {
            return
        }

        let messageModel = MessageProvider()
        messageModel.sendThreadMessage(message: message, idDiscussion: self.idDiscussion) { (result) in
            if (result) {
                self.messageTextField.text? = ""
                self.loadMessages()
            }
        }
    }

    func scrollToBottom() {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.messages.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
}

extension DiscussionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
         if let listCell = cell as? MessageViewCell {
            listCell.messageLabel.text = messages[indexPath.row].message
            listCell.timestampLabel.text = messages[indexPath.row].createdAt
            listCell.usernameLabel.text =  messages[indexPath.row].user.firstname + " " + messages[indexPath.row].user.lastname
            listCell.roundedView.backgroundColor = messages[indexPath.row].user.id == CurrentUser.currentUser.id ? UIColor.blue : UIColor.lightGray
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 105
    }
}

extension DiscussionViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        if CurrentUser.currentUser.role == 2 {
            return []
        }

        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let messageProvider = MessageProvider()
            messageProvider.deleteMessage(messageId: self.messages[indexPath.row].id, callback: { response in
                if response {
                    self.loadMessages()
                }
            })
        }
        return [delete]
    }
}

extension DiscussionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
