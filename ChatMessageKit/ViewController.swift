//
//  ViewController.swift
//  ChatMessageKit
//
//  Created by Hamilton Chapman on 30/11/2018.
//  Copyright © 2018 Hamilton Chapman. All rights reserved.
//

import UIKit
import PusherChatkit
import MessageKit
import MessageInputBar

class ViewController: MessagesViewController {

    var chatManager: ChatManager!
    var currentUser: PCCurrentUser!

    var messages: [MessageType] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self

        chatManager = ChatManager(
            instanceLocator: "v1:us1:276f579b-eafc-4024-b408-f0905fb9cd3e",
            tokenProvider: PCTokenProvider(url: "https://us1.pusherplatform.io/services/chatkit_token_provider/v1/276f579b-eafc-4024-b408-f0905fb9cd3e/token"),
            userID: "luis"
        )

        chatManager.connect(delegate: self) { cU, err in
            guard err == nil else {
                return
            }
            self.currentUser = cU

            self.currentUser.subscribeToRoom(
                id: self.currentUser.rooms.first!.id,
                roomDelegate: self
            ) { err in
                guard err == nil else {
                    return
                }
                print("Subscribed to room")
            }
        }
    }
}

extension ViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: currentUser.id, displayName: currentUser.name ?? currentUser.id)
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
}

extension ViewController: MessagesLayoutDelegate {

}

extension ViewController: MessagesDisplayDelegate {

}

extension ViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        print("Text view input bar changed to: \(text)")
        self.currentUser.typing(in: self.currentUser.rooms.first!) { err in
            guard err == nil else {
                return
            }
            print("Is typing")
        }
    }

    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        self.currentUser.sendMessage(
            roomID: self.currentUser.rooms.first!.id,
            text: text
        ) { msgID, err in
            guard err == nil else {
                return
            }
            DispatchQueue.main.async {
                self.messageInputBar.inputTextView.text = ""
            }
            print("Message sent with ID: \(msgID!)")
        }
    }
}

extension ViewController: PCChatManagerDelegate {}

extension ViewController: PCRoomDelegate {
    func onPresenceChanged(stateChange: PCPresenceStateChange, user: PCUser) {
        print("Presence changed")
    }

    func onMessage(_ message: PCMessage) {
        messages.append(message)
        DispatchQueue.main.async {
            self.messagesCollectionView.reloadData()
        }
    }
}

extension PCMessage: MessageType {
    public var sender: Sender {
        return Sender(id: "luis", displayName: "Luis")
    }

    public var messageId: String {
        return "\(self.id)"
    }

    public var sentDate: Date {
        return self.createdAtDate
    }

    public var kind: MessageKind {
        return .text(self.text)
    }
}
