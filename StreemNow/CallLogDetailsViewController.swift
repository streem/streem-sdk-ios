// Copyright © 2019 Streem, Inc. All rights reserved.

import AVKit
import UIKit
import StreemKit

class CallLogDetailsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let noteSection = 0
    private let videoSection = 1
    private let streemshotsAndMeshSection = 2
    
    private var artifactManager: ArtifactManager?
    
    private enum ArtifactLoadingState {
        case loading
        case success
        case failure
    }
    
    private var noteCell: CallLogDetailsNoteCell?

    private var recordingThumbnail = [Int: UIImageView?]()
    private var recordingLoadingState = [Int: ArtifactLoadingState]()
    
    private var streemshotThumbnail = [Int: UIImageView?]()
    private var streemshotLoadingState = [Int: ArtifactLoadingState]()
    
    private var meshThumbnail: UIImageView?
    private var meshLoadingState = ArtifactLoadingState.loading {
        didSet {
            setMeshThumbnailImage()
        }
    }

    private var isFirstAppearance = true
    
    var callLogEntry: StreemCallLogEntry? {
        didSet {
            if let callLogEntry = callLogEntry {
                artifactManager = Streem.sharedInstance.artifactManager(for: callLogEntry) { [weak self] artifactType, artifactIndex, success in
                    guard let self = self else { return }
                    
                    switch artifactType {
                    case .callNote:
                        guard let artifactManager = self.artifactManager else { return }
                        self.noteCell?.isReadOnly = !artifactManager.canEditCallNote(for: callLogEntry)
                        artifactManager.callNote() {
                            self.noteCell?.note = $0
                        }
                    case .recording:
                        guard let index = artifactIndex else { break }
                        self.recordingLoadingState[index] = success ? .success : .failure
                        self.setRecordingThumbnailImage(index: index)
                    case .streemshot:
                        guard let index = artifactIndex else { break }
                        self.streemshotLoadingState[index] = success ? .success : .failure
                        self.setStreemshotThumbnailImage(index: index)
                    case .mesh:
                        self.meshLoadingState = success ? .success : .failure
                    default:
                        break
                    }
                }
            } else {
                artifactManager = nil
            }
        }
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstAppearance {
            isFirstAppearance = false
        } else {
            collectionView?.reloadData() // ensure that thumbnails update themselves
        }
    }
        
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let callLogEntry = callLogEntry else { return 0 }
        
        if section == noteSection {
            return 1
        } else if section == videoSection {
            return callLogEntry.artifactCount(type: .recording)
        } else {
            return callLogEntry.artifactCount(type: .streemshot) + (callLogEntry.artifactCount(type: .mesh) > 0 ? 1 : 0)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == noteSection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CallLogDetailsNoteCell", for: indexPath) as! CallLogDetailsNoteCell
            noteCell = cell

            cell.layout = collectionViewLayout
            
            if cell.note.isEmpty {
                cell.note = callLogEntry?.notes ?? ""
            }
            
            cell.isReadOnly = true
            
            cell.saveNote = { [weak self] note in
                self?.callLogEntry?.notes = note
                self?.artifactManager?.setCallNote(note)
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CallLogDetailsThumbnailCell", for: indexPath) as! CallLogDetailsThumbnailCell
            
            cell.artifactManager = artifactManager

            if let thumbnail = cell.thumbnail {
                if indexPath.section == videoSection {
                    recordingThumbnail[indexPath.row] = thumbnail
                    setRecordingThumbnailImage(index: indexPath.row)
                } else {
                    let index = streemshotIndex(for: indexPath)

                    if index < 0 {
                        meshThumbnail = thumbnail
                        setMeshThumbnailImage()
                    } else {
                        streemshotThumbnail[index] = thumbnail
                        setStreemshotThumbnailImage(index: index)
                    }
                }
            }
            
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if indexPath.section == noteSection {
            return true
        } else if indexPath.section == videoSection {
            return recordingLoadingState[indexPath.row] == .success
        } else {
            let index = streemshotIndex(for: indexPath)
            
            if index < 0 {
                return artifactManager?.canAccessMeshScene(at: 0) ?? false
            } else {
                return artifactManager?.canAccessStreemshot(at: index) ?? false
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == noteSection {
            noteCell?.noteTextView.becomeFirstResponder()
        } else if indexPath.section == videoSection {
            playRecording(index: indexPath.row)
        } else {
            let index = streemshotIndex(for: indexPath)
            
            if index < 0 {
                artifactManager?.accessMeshScene(at: 0)
            } else {
                artifactManager?.accessStreemshot(at: index)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }

        if indexPath.section == noteSection {
            let width = collectionView.bounds.width - (flowLayout.sectionInset.left + flowLayout.sectionInset.right) - (collectionView.layoutMargins.left + collectionView.layoutMargins.right)
            let height = noteCell?.desiredHeight ?? 0
            return CGSize(width: width, height: height)
        } else {
            return flowLayout.itemSize
        }
    }
    
    private func streemshotIndex(for indexPath: IndexPath) -> Int {
        guard indexPath.section == streemshotsAndMeshSection else { return indexPath.item }
        
        var streemshotIndex = indexPath.item
        
        if let entry = callLogEntry, entry.artifactCount(type: .mesh) > 0
        {
            streemshotIndex -= 1
        }
        
        return streemshotIndex
    }
    
    private func setMeshThumbnailImage() {
         guard let meshThumbnail = self.meshThumbnail else { return }
        
         var image: UIImage?
         switch meshLoadingState {
         case .loading:
             image = nil
         case .success:
             image = UIImage(named: "MeshLoadedSuccessfully")
         case .failure:
             image = UIImage(named: "MeshLoadFailed")
         }
         
         DispatchQueue.main.async {
             meshThumbnail.image = image
         }
    }
    
    private func setStreemshotThumbnailImage(index: Int) {
         guard let streemshotThumbnail = self.streemshotThumbnail[index] else { return }
        
        let loadingState = streemshotLoadingState[index] ?? .loading
        
         var image: UIImage?
         switch loadingState {
         case .loading:
             image = nil
         case .success:
             image = artifactManager?.streemshotImage(at: index)
         case .failure:
             image = UIImage(named: "StreemshotLoadFailed")
         }
         
         DispatchQueue.main.async {
             streemshotThumbnail?.image = image
         }
    }

    private func setRecordingThumbnailImage(index: Int) {
         guard let recordingThumbnail = self.recordingThumbnail[index] else { return }
        
        let loadingState = recordingLoadingState[index] ?? .loading
        
         var image: UIImage?
         switch loadingState {
         case .loading:
             image = nil
         case .success:
             image = UIImage(named: "RecordingLoadedSuccessfully")
         case .failure:
             image = UIImage(named: "RecordingLoadFailed")
         }
         
         DispatchQueue.main.async {
             recordingThumbnail?.image = image
         }
    }
    
    private func playRecording(index: Int) {
        guard let artifactManager = artifactManager,
              let recordingUrl = artifactManager.recordingUrl(at: index)
        else { return }
        
        let vc = AVPlayerViewController()
        vc.player = AVPlayer(url: recordingUrl)

        present(vc, animated: true) {
            vc.player?.play()
        }
    }

}

class CallLogDetailsNoteCell: UICollectionViewCell, UITextViewDelegate {
    
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    weak var layout: UICollectionViewLayout?
    
    var saveNote: ((String) -> ())?
    
    var isReadOnly: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.saveButton.isHidden = self.isReadOnly
            }
        }
    }

    var note = String() {
        didSet {
            DispatchQueue.main.async {
                self.noteTextView.text = self.note
                self.layout?.invalidateLayout()
            }
        }
    }
    
    var desiredHeight: CGFloat {
        let noteHeight = noteTextView.sizeThatFits(CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
        return noteTextView.frame.minY + noteHeight
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return !isReadOnly
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let deltaLength = text.count - range.length
        return textView.text.count + deltaLength <= StreemCallLogEntry.maximumNotesCharacters
    }
    
    func textViewDidChange(_ textView: UITextView) {
        note = textView.text
    }
    
    @IBAction func save() {
        saveNote?(note)
        noteTextView.resignFirstResponder()
    }
    
}

class CallLogDetailsThumbnailCell: UICollectionViewCell {
    
    @IBOutlet weak var loadingLabel: UILabel?
    @IBOutlet weak var thumbnail: UIImageView?
    weak var artifactManager: ArtifactManager?
    
    private var _isLoading: Bool = false
    
    fileprivate var isLoading: Bool {
        get {
            return _isLoading
        }
        set {
            guard newValue != _isLoading else { return }
            
            _isLoading = newValue
            
            if _isLoading {
                self.contentView.layer.borderColor = UIColor.lightGray.cgColor
                self.contentView.layer.borderWidth = 0.5
                self.loadingLabel?.alpha = 1.0
                self.thumbnail?.alpha = 0.0
            } else {
                self.contentView.layer.borderWidth = 0
                self.loadingLabel?.alpha = 0.0
                self.thumbnail?.alpha = 1.0
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isLoading = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isLoading = true
    }
    
}

class CallLogDetailsThumbnailCellImageView: UIImageView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.alpha = 0.0
    }
    
    override var image: UIImage? {
        didSet {
            guard let contentView = self.superview, let cell = contentView.superview as? CallLogDetailsThumbnailCell else { return }
            
            if image == nil {
                cell.isLoading = true
            } else {
                UIView.animate(withDuration: 0.3) {
                    cell.isLoading = false
                }
            }
        }
    }
    
}
