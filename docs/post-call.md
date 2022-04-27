&nbsp; &nbsp; &nbsp; &nbsp;
[< Starting a Local Streem](local.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Known Issues >](known_issues.md)

## The Post-Call Experience

StreemKit provides a number of methods and objects for constructing a post-call experience, where an Expert user can review their calls, add notes, edit streemshots, and interact with meshes. To retrieve and manipulate these post-call `artifacts` you obtain and use an `ArtifactManager`.

### Fetching the Call Log

You can fetch a list of the logged-in user's previous streems:

```swift
    Streem.sharedInstance.fetchCallLog { callLogEntries in
        // display a Table of the calls, etc.
    }
```

The returned array contains objects of type `StreemCallLogEntry`, which have these properties and method:

```swift
    id: String                                         // A unique id for the call log
    startDate: Date                                    // Session start time
    endDate: Date?                                     // Session end time
    participants: [StreemUser]                         // Session participants. One for an Onsite Streem call, two for a two-way Streem caall.
    hasMesh: Bool                                      // Whether the Streem call has a mesh with it or not
    isOnsite: Bool                                     // Whether the Streem call was an Onsite Streem call or not
    latestDetectedAddress: String                      // The latest detected address for the Streem call
    latestDetectedCoordinates: CLLocationCoordinate2D  // The latest GPS coordinates for the Streem call
    notes: String                                      // The notes for the Streem call
    maximumNotesCharacters: Int                        // Maximum allowable length of Call Notes -- expressed in characters, not bytes
    referenceId: String                                // The reference ID of the Streem call
    shareUrl: String                                   // The URL for sharing the call details
    isMissed: Bool                                     // Whether the Streem call call was missed or not

    // The number of available artifacts of the specified type.
    func artifactCount(type: StreemArtifactType) -> Int
```

### Displaying and Editing Artifacts

Once you have fetched the call log, you may display or edit the artifacts associated with any of the calls.

First, obtain an `ArtifactManager` for the call. The call to `artifactManager` takes a callback which will provide, for each artifact associated with the call, the type and index of the artifact, as well as whether that artifact was retrieved successfully:
```swift
    let artifactManager = Streem.sharedInstance.artifactManager(forCallLogEntry: entry) { [weak self] artifactType, artifactIndex, success in
        switch artifactType {
        case .callNote:
            handleCallNoteLoading(success)
        case .streemshot:
            handleStreemshotLoading(artifactIndex, success)
        case .recording:
            handleRecordingLoading(artifactIndex, success)
        case .mesh:
            handleMeshLoading(artifactIndex, success)
        }
    }
```

As soon as the `ArtifactManager` is created, it will begin to download the call's `artifact`s.

Your `handleArtifactLoading` methods from above should check for success and then retrieve the note, image, recording, or provide a representation of the mesh.

```swift
    func handleCallNoteLoading(success: Bool) {
        self.noteCell?.isReadOnly = !artifactManager.canEditCallNote(for: callLogEntry)
        artifactManager.callNote() { noteText in
            // Do something with the note text
        }
    }

    func handleStreemshotLoading(index: Int, success: Bool) {
        if success {
            let image = artifactManager.streemshotImage(at: index)
            // Do something with the image
        } else {
            // handle failure
        }
    }

    func handleRecordingLoading(index: Int, success: Bool) {
        if success {
            // The recording artifact will be a downloaded, playable movie file which can be retrieved via its URL
            let url = artifactManager.recordingUrl(at: index)
            let asset = AVURLAsset(url: url, options: nil)
            // Do something with the AV Asset

            // Or if you simply want to play the video
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: url)
            // Present vc
        } else {
            // handle failure
        }
    }

    func handleMeshLoading(index: Int, success: Bool) {
       if success {
           // Do something to display mesh
       } else {
           // handle failure
       }
    }
```

When presenting Streemshots you may want to display whether a Streemshot has a note:

```swift
    if artifactManager.streemshotHasNote(at: index) {
        // Display that Streemshot has a note
    }
```

To present the UI for presenting and editing a Streemshot, first confirm that the Streemshot has been fully downloaded:

```swift
    artifactManager.canAccessStreemshot(atIndex: theIndex)
```
Once that method returns `true`, you can launch a Streemshot-editing session:

```swift
    artifactManager.accessStreemshot(atIndex: theIndex)
```

The `ArtifactManager` will present the Streemshot-editing view controller, loaded with the indicated Streemshot. That view controller also allows the user to scroll through the other Streemshots associated with the call.

To enter into the mesh editor you follow a similar set of steps. First check to see that the mesh is ready and presentable:

```swift
    artifactManager.canAccessMeshScene()
```

If that returns `true`, you can launch the mesh scene-editing session:

```swift
    artifactManager.accessMeshScene()
```

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp;
[< Starting a Local Streem](local.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Home](../README.md)
&nbsp; &nbsp; &nbsp; &nbsp;
[Known Issues >](known_issues.md)
