//
//  EventViewController.swift
//  TimeShare MessagesExtension
//
//  Created by Yury on 9/27/18.
//  Copyright © 2018 Yury Shkoda. All rights reserved.
//

import UIKit
import Messages

class EventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var dates    = [Date]()
    var allVotes = [Int]()
    var ourVotes = [Int]()
    
    weak var delegate: MessagesViewController!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBAction func saveSelectedDates(_ sender: Any) {
        var finalVotes = [Int]()
        
        for (index, votes) in allVotes.enumerated() {
            finalVotes.append(votes + ourVotes[index])
        }
        
        delegate.createMessage(with: dates, votes: finalVotes)
    }
    
    @IBAction func addDate(_ sender: Any) {
        // Add to the arrays
        dates.append(datePicker.date)
        allVotes.append(0)
        ourVotes.append(1)
        
        // Insert a row in the table using animation
        let newIndexPath = IndexPath(row: dates.count - 1, section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        // Scroll the new row into view
        tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
        // Flash the scroll bars so the user knows something has changed
        tableView.flashScrollIndicators()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func load(from message: MSMessage?) {
        guard let message = message else { return }
        guard let messageURL = message.url else { return }
        guard let urlComponents = URLComponents(url: messageURL, resolvingAgainstBaseURL: false) else { return }
        guard let queryItems = urlComponents.queryItems else { return }
        
        for item in queryItems {
            if item.name.hasPrefix("date-") {
                dates.append(date(from: item.value ?? ""))
            } else if item.name.hasPrefix("vote-") {
                let voteCount = Int(item.value ?? "") ?? 0
                
                allVotes.append(voteCount)
                ourVotes.append(0)
            }
        }
    }
    
    func date(from string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        
        return dateFormatter.date(from: string) ?? Date()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Deque a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Date", for: indexPath)
        
        // Pull out the corresponding date and format it neatly
        let date = dates[indexPath.row]
        cell.textLabel?.text = DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .short)
        
        // Add a checkmark if we voted for this date
        if ourVotes[indexPath.row] == 1 {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        // Added a vote count if other people voted for this date
        if allVotes[indexPath.row] > 0 {
            cell.detailTextLabel?.text = "Votes: \(allVotes[indexPath.row])"
        } else {
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                
                ourVotes[indexPath.row] = 0
            } else {
                cell.accessoryType = .checkmark
                
                ourVotes[indexPath.row] = 1
            }
        }
    }
}
