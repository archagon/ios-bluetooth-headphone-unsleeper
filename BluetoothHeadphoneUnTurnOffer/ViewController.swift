//
//  ViewController.swift
//  BluetoothHeadphoneUnTurnOffer
//
//  Created by Alexei Baboulevitch on 2017-5-17.
//  Copyright © 2017 Alexei Baboulevitch. All rights reserved.
//

import UIKit
import AVFoundation

//ffmpeg -ar 44100 -t 1 -f s16le -acodec pcm_s16le -ac 1 -i /dev/null -acodec libmp3lame -aq 4 silence.mp3
//ffmpeg -ar 44100 -t 1 -f s16le -acodec pcm_s16le -ac 1 -i /dev/random -acodec libmp3lame -aq 4 static.mp3
//ffmpeg -f lavfi -i "sine=frequency=10:duration=1" inaudible.mp3

class ViewController: UIViewController {

    // views
    @IBOutlet var toggle: UISwitch!
    @IBOutlet var button: UIButton!
    
    // model
    var soundIsOn: Bool = false { didSet { soundIsOnDidSet() } }
    func soundIsOnDidSet() { sound(on: soundIsOn) }
    
    // audio
    var player: AVAudioPlayer!
    var recorder: AVAudioRecorder?
    
    // file management
    var tempFileCleanupTimer: Timer?
    
    // constants
    let tempFilepath = NSURL.fileURL(withPath: NSTemporaryDirectory() + "temp")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudio: do {
            let resource = Bundle.main.url(forResource: "inaudible", withExtension: "mp3")!
            
            player = try AVAudioPlayer(contentsOf: resource)
            player.numberOfLoops = -1
            player.volume = 0.01
        }
        catch {
            print("error! could not create audio player")
        }
        
        soundIsOnDidSet()
    }
    
    @IBAction func toggled(toggle: UISwitch) {
        self.soundIsOn = toggle.isOn
    }
    
    @IBAction func buttoned(button: UIButton) {
        self.soundIsOn = !self.soundIsOn
    }
    
    func sound(on: Bool) {
        if on {
            toggle.setOn(true, animated: true)
            button.setTitle("Enabled", for: .normal)
            
            audio: do {
                print("audio on")
                
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, mode: AVAudioSessionModeDefault, options: [.mixWithOthers, .allowBluetoothA2DP, .allowAirPlay])
                try AVAudioSession.sharedInstance().setActive(true)
                
                AVAudioSession.sharedInstance().requestRecordPermission({ (allowed: Bool) in
                    print("recording allowed: \(allowed)")
                    
                    setupRecorder: do {
                        if !allowed {
                            self.recorder = nil
                        }
                        else {
                            let defaultSettings: [String:Any] = [
                                AVFormatIDKey: kAudioFormatLinearPCM,
                                AVLinearPCMBitDepthKey: 1,
                                AVLinearPCMIsBigEndianKey: false,
                                AVLinearPCMIsFloatKey: false,
                                AVLinearPCMIsNonInterleaved: false,
                                AVNumberOfChannelsKey: 1,
                                AVSampleRateKey: 1
                            ]
                            
                            //let null = NSURL.fileURL(withPath: "/dev/null") //doesn't show red bar :(
                            
                            self.recorder = try AVAudioRecorder(url: self.tempFilepath, settings: defaultSettings)
                        }
                    }
                    catch {
                        print("error! could not create audio recorder")
                    }
                })
                
                let playing = player.play()
                let recording = recorder?.record()
                
                tempFileCleanupTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                    cleanup: do {
                        try FileManager.default.removeItem(at: self.tempFilepath)
                    }
                    catch {
                        // AB: it seems that after deleting the file, recorder does not recreate
                        //print("warning! no file to delete")
                    }
                })
                
                print("playing: \(playing)")
                if let recording = recording {
                    print("recording: \(recording)")
                }
                else {
                    print("recording: null")
                }
            }
            catch {
                print("error! could not enable audio session")
            }
        }
        else {
            toggle.setOn(false, animated: true)
            button.setTitle("Disabled", for: .normal)
            
            audio: do {
                print("audio off")
                
                player.stop()
                recorder?.stop()
                
                try FileManager.default.removeItem(at: tempFilepath)
                self.tempFileCleanupTimer?.invalidate()
                self.tempFileCleanupTimer = nil
            }
            catch {
                //print("warning! no file to delete")
            }
        }
    }
}

