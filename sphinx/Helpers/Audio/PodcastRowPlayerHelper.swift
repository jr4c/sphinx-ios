//
//  PodcastRowPlayerHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AVKit

@objc protocol PodcastPlayerRowDelegate : class {
    func shouldUpdateLabels(duration: Int, currentTime: Int)
    func shouldToggleLoadingWheel(loading: Bool)
}

class PodcastRowPlayerHelper {
    
    weak var delegate: PodcastPlayerRowDelegate?
    
    var currentTime: Int = 0
    var playedSeconds: Int = 0
    var duration : Double? = nil
    var item: AVPlayerItem? = nil
    
    var playingTimer : Timer? = nil
    var playing = false
    
    var progressCallback: (Double, Double) -> Void = { (_, _) in }
    var endCallback: () -> Void = {}
    var pauseCallback: () -> Void = {}
    var playCallback: () -> Void = {}
    
    var messageId: Int? = nil
    var podcastComment: PodcastComment? = nil
    var podcast: PodcastFeed? = nil
    
    var podcastPaymentsHelper = PodcastPaymentsHelper()
    let customAudioPlayer = PodcastRowAudioPlayer.sharedInstance
    
    func createPlayerItemWith(podcastComment: PodcastComment,
                              podcast: PodcastFeed?,
                              delegate: PodcastPlayerRowDelegate,
                              for messageId: Int,
                              completion: @escaping (Int) -> ()) {
        
        self.podcastComment = podcastComment
        self.podcast = podcast
        self.delegate = delegate
        
        if let urlString = podcastComment.url, let url = URL(string: urlString) {
            
            if let _ = self.item {
                completion(messageId)
                return
            }
            
            let asset = AVAsset(url: url)
            
            loadAudioDurationFor(asset: asset, completion: {
                if self.item == nil {
                    self.item = AVPlayerItem(asset: asset)
                }
                DispatchQueue.main.async {
                    completion(messageId)
                }
            })
        }
    }
    
    func loadAudioDurationFor(
        asset: AVAsset,
        completion: @escaping () -> ()
    ) {
        let duration = getAudioDuration()
        
        if duration > 0 {
            completion()
        } else {
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                completion()
            })
        }
    }
    
    func setInitialTime(startTime: Double) {
        if currentTime == 0 {
            currentTime = Int(startTime)
        }
    }
    
    func getAudioDuration() -> Double {
        if let duration = duration {
            return duration
        }
        if let itemId = podcastComment?.itemId, let duration = podcast?.getEpisodeWith(id: itemId)?.duration {
            self.duration = Double(duration)
            return self.duration!
        }
        guard let item = item else {
            return 0
        }
        duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
        return duration!
    }
    
    func playAudioFrom(messageId: Int) -> Bool {
        guard let item = item else {
            return false
        }
        
        if playing {
            pausePlayingAudio()
            return false
        }
        
        self.messageId = messageId
        
        setAudioSession()
        customAudioPlayer.prepareAudioPlayer(item: item)
        shouldPlay()
        return true
    }
    
    func setAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {}
        
        let session = AVAudioSession.sharedInstance()
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: session)
    }
    
    @objc func handleInterruption(notification: NSNotification) {
        if notification.name != AVAudioSession.interruptionNotification || notification.userInfo == nil{
            return
        }
        let info = notification.userInfo!
        var intValue: UInt = 0
        
        (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
        if let interruptionType = AVAudioSession.InterruptionType(rawValue: intValue) {
            switch interruptionType {
            case .began:
                self.pausePlayingAudio()
            default:
                break
            }
        }
    }
    
    func shouldPlay() {
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateCurrentTime), userInfo: nil, repeats: true)
        
        playing = true
        
        setResumingTime()
        customAudioPlayer.play()
        playCallback()
    }
    
    func setCallbacks(progressCallback: @escaping (Double, Double) -> (), endCallback: @escaping () -> (), pauseCallback: @escaping () -> (), playCallback: @escaping () -> ()) {
        self.progressCallback = progressCallback
        self.endCallback = endCallback
        self.pauseCallback = pauseCallback
        self.playCallback = playCallback
    }
    
    func pausePlayingAudio() {
        stopPlaying()
        pauseCallback()
    }
    
    func stopPlaying() {
        customAudioPlayer.stop()
        playing = false
        playingTimer?.invalidate()
        playingTimer = nil
    }
    
    func setResumingTime(force: Bool = false) {
        if currentTime > 0 || force {
            customAudioPlayer.setCurrentTime(currentTime: currentTime)
        }
    }
    
    func seekTo(progress: Double, play: Bool) {
        if let item = item {
            let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
            currentTime = Int(duration * progress)
            setResumingTime(force: true)
        }
        
        if play { shouldPlay() }
    }
    
    
    func shouldUpdateTimeLabels(progress: Double) {
        guard let item = item else {
            return
        }
        let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
        let currentTime = (duration * progress)
        
        delegate?.shouldUpdateLabels(duration: Int(duration), currentTime: Int(currentTime))
    }
    
    @objc func updateCurrentTime() {
        if let audioPlayerDuration = customAudioPlayer.getDuration(), let audioPlayerCurrentTime = customAudioPlayer.getCurrentTime(), audioPlayerDuration > 0 {
            if audioPlayerCurrentTime > currentTime {
                if audioPlayerCurrentTime == currentTime + 1 {
                    updatePlayedTime()
                }
            }
            currentTime = audioPlayerCurrentTime
            
            if audioPlayerCurrentTime > 0 {
                progressCallback(audioPlayerDuration, Double(audioPlayerCurrentTime))
            }
        } else {
            audioDidFinishPlaying()
        }
    }
    
    func updatePlayedTime() {
        delegate?.shouldToggleLoadingWheel(loading: false)
        
        playedSeconds = playedSeconds + 1
        
        if playedSeconds > 0 && playedSeconds % kSecondsBeforePMT == 0 {
            DispatchQueue.global().async {
                self.processPayment()
            }
        }
    }
    
    func processPayment() {
        let itemId = self.podcastComment?.itemId ?? ""
        let clipSenderPK = self.podcastComment?.pubkey
        let uuid = self.podcastComment?.uuid
        
        self.podcastPaymentsHelper.processPaymentsFor(
            podcastFeed: self.podcast,
            itemId: itemId,
            currentTime: Int(self.currentTime),
            clipSenderPubKey: clipSenderPK,
            uuid: uuid
        )
    }
    
    func audioDidFinishPlaying() {
        resetCurrentAudio()
        endCallback()
    }
    
    func resetCurrentAudio() {
        playing = false
        currentTime = 0
        playingTimer?.invalidate()
        playingTimer = nil
    }
}
