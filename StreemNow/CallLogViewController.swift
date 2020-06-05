// Copyright © 2019 Streem, Inc. All rights reserved.

import Foundation
import StreemKit

class CallLogViewController: UITableViewController {
    
    var callLogEntries: [StreemCallLogEntry]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView() // hide separators for non-existent cells
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return callLogEntries?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CallLogTableViewCell") as! CallLogTableViewCell
        if let callLogEntries = callLogEntries, callLogEntries.count > indexPath.row {
            let entry = callLogEntries[indexPath.row]
            
            var participantName: String?
            if entry.participants.count == 1 {
                participantName = entry.participants[0].name
            } else if let currentUser = StreemInitializer.shared.currentUser {
                participantName = entry.participants.first { $0.id != currentUser.id }?.name
            }
            cell.participantNameLabel.text = participantName
            
            cell.startDateLabel.text = DateFormatter.localizedString(from: entry.startDate, dateStyle: .short, timeStyle: .short)
            
            if entry.streemshotsCount == 0 {
                cell.streemshotsLabel.isHidden = true
                cell.accessoryType = .none
                cell.selectionStyle = .none
            } else {
                cell.streemshotsLabel.isHidden = false
                cell.streemshotsLabel.text = entry.streemshotsCount == 1 ? "1 Streemshot" : "\(entry.streemshotsCount) Streemshots"
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let entry = callLogEntries?[indexPath.row], entry.streemshotsCount == 0 {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let callLogDetailsViewController = segue.destination as? CallLogDetailsViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            callLogDetailsViewController.callLogEntry = callLogEntries?[indexPath.row]
        }
    }
}

class CallLogTableViewCell: UITableViewCell {
    
    @IBOutlet weak var participantNameLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var streemshotsLabel: UILabel!

}
