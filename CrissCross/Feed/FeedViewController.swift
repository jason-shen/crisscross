//
//  FeedViewController.swift
//  CrissCross
//
//  Created by Kyle Lee on 9/3/20.
//  Copyright © 2020 Kilo Loco. All rights reserved.
//

import Amplify
import AVFoundation
import Combine
import UIKit

final class FeedViewController: UIViewController {

    private var getClipsToken: AnyCancellable?
    private var observeNewClipsToken: AnyCancellable?
    private var willDisplayCellToken: AnyCancellable?
    private var cellDisappearedToken: AnyCancellable?
    private var cellTokens = [IndexPath: AnyCancellable]()
    private var currentCell: ClipCell? {
        didSet {
            oldValue?.togglePlay(on: false)
            currentCell?.togglePlay(on: true)
        }
    }
    
    private let feedManager = FeedCollectionViewManager()
    private let ui = FeedView()
    
    override func loadView() {
        view = ui
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        getClips()
        observeNewClips()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        currentCell?.togglePlay(on: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        currentCell?.togglePlay(on: false)
    }
    
    private func configure() {
        ui.register(ClipCell.self)
        feedManager.cellForRow = {collectionView, indexPath, clip in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ClipCell.reuseIdentifier,
                for: indexPath
            )
            
            let clipCell = cell as? ClipCell
            clipCell?.populate(with: clip)
            
            return cell
        }
        
        willDisplayCellToken = feedManager.willDisplayCellPublisher
            .filter { $0.cell.frame != .zero }
            .compactMap { event -> (cell: ClipCell, indexPath: IndexPath)? in
                guard let clipCell = event.cell as? ClipCell else { return nil }
                return (clipCell, event.indexPath)
            }
            .sink { [weak self] event in
                self?.currentCell = event.cell
                event.cell.togglePlay(on: true)
                self?.cellTokens[event.indexPath] = event.cell.actionPublisher
                    .sink { self?.handle($0) }
            }
        
        cellDisappearedToken = feedManager.cellDisappearedPublisher
            .filter { $0.cell.frame != .zero }
            .compactMap { event -> (cell: ClipCell, indexPath: IndexPath)? in
                guard let clipCell = event.cell as? ClipCell else { return nil }
                return (clipCell, event.indexPath)
            }
            .sink { [weak self] in
//                $0.cell.togglePlay(on: false)
                self?.cellTokens[$0.indexPath] = nil
            }
        
        ui.bind(to: feedManager)
    }
    
    private func getClips() {
        getClipsToken = Amplify.DataStore.query(Clip.self)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { print($0) },
                receiveValue: { [weak self] in self?.feedManager.set($0) }
            )
        
//        let date = Temporal.DateTime(Date())
//        let clips = Array(0 ..< 20).map { Clip(id: String($0), username: UUID().uuidString, caption: "", creationDate: date) }
//        feedManager.set(clips)
    }
    
    private func observeNewClips() {
        observeNewClipsToken = Amplify.DataStore.publisher(for: Clip.self)
            .compactMap { event -> Clip? in
                let mutationType = MutationEvent.MutationType(rawValue: event.mutationType)
                guard mutationType == .create else { return nil }
                return try? event.decodeModel(as: Clip.self)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: {
                    print($0)
            },
                receiveValue: { [weak self] clip in
                    print(clip)
                    self?.feedManager.append(clip)
                }
            )
    }
    
    
    
    private func handle(_ action: ClipCell.Action) {
        switch action {
        case .comment:
            print("comment")
            
        case .like:
            print("like")
            
        case .profile:
            print("profile")
            
        case .share:
            print("share")
            
        case .sound:
            print("sound")
        }
    }
}
