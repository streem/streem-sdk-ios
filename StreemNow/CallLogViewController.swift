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
            
            let streemshotsCount = entry.artifactCount(type: .streemshot)
            let hasMesh = entry.artifactCount(type: .mesh) > 0
            let recordingsCount = entry.artifactCount(type: .recording)

            if streemshotsCount == 0, !hasMesh, recordingsCount == 0 {
                cell.artifactsLabel.isHidden = true
                cell.accessoryType = .none
                cell.selectionStyle = .none
            } else {
                var text = ""
                let nonBreakingSpace = " "
                if streemshotsCount > 0 {
                    text = streemshotsCount == 1 ? "1\(nonBreakingSpace)Streemshot" : "\(streemshotsCount)\(nonBreakingSpace)Streemshots"
                }
                if hasMesh {
                    if !text.isEmpty {
                        text += "\r"
                    }
                    
                    text += "Mesh"
                }
                if recordingsCount > 0 {
                    if !text.isEmpty {
                        text += "\r"
                    }
                    
                    text += recordingsCount == 1 ? "1\(nonBreakingSpace)Recording" : "\(recordingsCount)\(nonBreakingSpace)Recordings"
                }

                cell.artifactsLabel.isHidden = false
                cell.artifactsLabel.text = text
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let entry = callLogEntries?[indexPath.row], entry.artifactCount(type: .streemshot) == 0, entry.artifactCount(type: .mesh) == 0, entry.artifactCount(type: .recording) == 0 {
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
    @IBOutlet weak var artifactsLabel: UILabel!

}
