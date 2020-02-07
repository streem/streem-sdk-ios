// Copyright © 2019 Streem, Inc. All rights reserved.

import UIKit
import Streem

class CallLogDetailsViewController: UICollectionViewController {
    
    var streemshotManager: StreemshotManager?
    
    var callLogEntry: StreemCallLogEntry? {
        didSet {
            if let callLogEntry = callLogEntry {
                streemshotManager = Streem.sharedInstance.streemshotManager(forCallLogEntry: callLogEntry)
            } else {
                streemshotManager = nil
            }
        }
    }
    
    private var isFirstAppearance = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstAppearance {
            isFirstAppearance = false
        } else {
            collectionView?.reloadData() // ensure that streemshotThumbnails to update themselves
        }
    }
        
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return callLogEntry?.streemshotsCount ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CallLogDetailsCollectionViewCell", for: indexPath) as! CallLogDetailsCollectionViewCell
        
        cell.streemshotManager = streemshotManager
        
        if let streemshotThumbnail = cell.streemshotThumbnail {
            streemshotManager?.register(imageView: streemshotThumbnail, forStreemshotIndex: indexPath.item)
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return streemshotManager?.canEditStreemshot(atIndex: indexPath.item) ?? false
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        streemshotManager?.editStreemshot(atIndex: indexPath.item)
    }

}

class CallLogDetailsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var loadingLabel: UILabel?
    @IBOutlet weak var streemshotThumbnail: UIImageView?
    weak var streemshotManager: StreemshotManager?
    
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
                self.streemshotThumbnail?.alpha = 0.0
            } else {
                self.contentView.layer.borderWidth = 0
                self.loadingLabel?.alpha = 0.0
                self.streemshotThumbnail?.alpha = 1.0
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
        
        if let streemshotThumbnail = streemshotThumbnail {
            streemshotManager?.unregister(imageView: streemshotThumbnail)
        }
    }
    
}

class CallLogDetailsCollectionViewCellImageView: UIImageView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.alpha = 0.0
    }
    
    override var image: UIImage? {
        didSet {
            guard let contentView = self.superview, let cell = contentView.superview as? CallLogDetailsCollectionViewCell else { return }
            UIView.animate(withDuration: 0.3) {
                cell.isLoading = false
            }
        }
    }
    
}
