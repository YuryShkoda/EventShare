//
//  MessagesViewController.swift
//  TimeShare MessagesExtension
//
//  Created by Yury on 9/27/18.
//  Copyright © 2018 Yury Shkoda. All rights reserved.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    @IBAction func createNewEvent(_ sender: Any) {
        requestPresentationStyle(.expanded)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func displayEventViewController(conversation: MSConversation?, identifier: String) {
        // check if conversation exists
        guard let conversation = conversation else { return }
        
        // create child view controller
        guard let vc = storyboard?.instantiateViewController(withIdentifier: identifier) as? EventViewController else { return }
        
        vc.delegate = self
        vc.load(from: conversation.selectedMessage)
        
        // add child to the parent so that event are forwarded
        addChild(vc)
        
        // make child vc fill the view
        vc.view.frame = view.bounds
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vc.view)
        
        // add Auto Layout constraints so the child view continue to fill the full view
        vc.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive     = true
        vc.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive   = true
        vc.view.topAnchor.constraint(equalTo: view.topAnchor).isActive       = true
        vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // move the child to a new parent view controller
        vc.didMove(toParent: self)
    }
    
    func createMessage(with dates: [Date], votes: [Int]) {
        // return the extension to compact mode
        requestPresentationStyle(.compact)
        
        // Make sure the conversation is active
        guard let conversation = activeConversation else { return }
        
        // Convert dates and votes into URLQueryItem objects
        var components = URLComponents()
        var items = [URLQueryItem]()
        
        for (index, date) in dates.enumerated() {
            let dateItem = URLQueryItem(name: "date-\(index)", value: string(from: date))
            items.append(dateItem)
            
            let voteItem = URLQueryItem(name: "vote-\(index)", value: String(votes[index]))
            items.append(voteItem)
        }
        
        components.queryItems = items
        
        // Use existing session or create a new one
        let session = conversation.selectedMessage?.session ?? MSSession()
        
        // Create a new message from the session and assign it the URL created from dates and votes
        let message = MSMessage(session: session)
        message.url = components.url
        
        // Create a blank, default message layout
        let layout = MSMessageTemplateLayout()
        layout.image = render(dates: dates)
        layout.caption = "I voted"
        message.layout = layout
        
        // Insert it into the conversation
        conversation.insert(message) { error in
            if let error = error {
                print(error)
            }
        }
    }
    
    func string(from date: Date) -> String {
        let dateFormater = DateFormatter()
        dateFormater.timeZone = TimeZone(abbreviation: "UTC")
        dateFormater.dateFormat = "yyyy-MM-dd-HH-mm"
        
        return dateFormater.string(from: date)
    }
    
    func render(dates: [Date]) -> UIImage {
        // Define 20-point padding
        let inset: CGFloat = 20
        
        // Create the attributes for drawing using Dynamic Type
        let attributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body), NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        
        // Make a single string out of all dates
        var stringTorender = ""
        
        dates.forEach {
            stringTorender += DateFormatter.localizedString(from: $0, dateStyle: .long, timeStyle: .short) + "\n"
        }
        
        // Trim the last line break, then create an attributed string by merging the date string and the attributes
        let trimmed = stringTorender.trimmingCharacters(in: .whitespacesAndNewlines)
        let attributedString = NSAttributedString(string: trimmed, attributes: attributes)
        
        // Calculate the size required to draw the attributed string, then add the inset to all edges
        var imageSize = attributedString.size()
        imageSize.width  += inset * 2
        imageSize.height += inset * 2
        
        // Create an image format that uses @3x scale on an opaque background
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale  = 3
        
        // Create a renderer at the correct size using the above format
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        
        // Render a series of instructions to image
        let image = renderer.image { ctx in
            // Draw a solid white background
            UIColor.white.set()
            
            ctx.fill(CGRect(origin: CGPoint.zero, size: imageSize))
            
            // Render text on top, using the insets
            attributedString.draw(at: CGPoint(x: inset, y: inset))
        }
        
        return image
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        if presentationStyle == .expanded {
            displayEventViewController(conversation: conversation, identifier: "SelectDates")
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        if presentationStyle == .expanded {
            displayEventViewController(conversation: activeConversation, identifier: "CreateEvent")
        }
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }

}
