//
//  ViewController.swift
//  AccessibilityKONE
//
//  Created by Korman Chen on 9/30/17.
//  Copyright © 2017 Korman Chen. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioSessionDelegate, AVAudioRecorderDelegate, FileManagerDelegate, NSURLConnectionDelegate {

    
    //MARK: Properties
    var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var recorder: AVAudioRecorder!
    var responseLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do
        {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else
                    {
                        fatalError("Failed to record")
                    }
                }
            }
        } catch {
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadRecordingUI() {
        recordButton = UIButton(frame: CGRect(x: 64, y: 64, width: 200, height: 64))
        recordButton.setTitle("Record", for: .normal)
        recordButton.setTitleColor(UIColor.red, for: .normal);
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        view.addSubview(recordButton)
    }
    
    //MARK: Recording Methods
    func startRecording()
    {
        do {
            let audioFilename = getDirectory().appendingPathComponent("recording.wav")
            
            let settings = [AVFormatIDKey: Int(kAudioFormatLinearPCM),
                            AVSampleRateKey: 48000,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue]
            recorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            recorder.record()
        }
        catch {
            print ("failed")
        }
    }
    
    func getDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func finishRecording(success: Bool) {
        recorder.stop()
        recorder = nil
        
        if success {
            recordButton.setTitle("Tap to Re-record", for: .normal)
            // create the request
            sendAudioToConvert()
            
        } else {
            recordButton.setTitle("Record", for: .normal)
        }
    }
    
    func sendAudioToConvert() {
        let audioFilename = getDirectory().appendingPathComponent("recording.wav")
        let audioFile = FileManager.default.contents(atPath: audioFilename.path)
        
        let username = "9d146bba-26eb-4404-aa7a-1065befc097e"
        let password = "xQLLWfPp7gQo"
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        let url = URL(string: "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.setValue("chunked", forHTTPHeaderField: "Transfer-Encoding")
        
        //let dataString =  String(data:request, encoding: String.Encoding.utf8)
        print("\(request.allHTTPHeaderFields)")
        print("\(audioFilename.path)")
        
        let audioFileData = audioFile?
            .base64EncodedString(options: [])
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            .data(using: String.Encoding.utf8)!
        print("error=\(audioFileData)")
        request.httpBody = audioFile
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                // use the json data from here to call KONE API.
                let headers = [
                    "x-ibm-client-id": "027d2327-4703-4799-bf0f-d1ee0cf0ba4c",
                    "x-ibm-client-secret": " vT2kE0rM7cQ7uX3tJ7nK8rC8xD0iP2qH6kW0hY6nJ0lE5tK7sS",
                    "accept": "application/vnd.api+json"
                ]
                
                let koneAPIurl = URL(string: "https://api.kone.com/api/building/9990000508") //Request building id
                var koneRequest = URLRequest(url: koneAPIurl!)
                koneRequest.httpMethod = "GET"
                koneRequest.allHTTPHeaderFields = headers
                //print("\(koneRequest.allHTTPHeaderFields)")
                
                let session = URLSession.shared
                let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                    if (error != nil) {
                        print(error)
                    } else {
                        let httpResponse = response as? HTTPURLResponse
                        print(httpResponse)
                    }
                })
                
                var koneAreaRequest = URLRequest(url: URL(string: "https://api.kone.com/api/building/9990000508/area")!)
                koneAreaRequest.httpMethod = "GET" //Request building area
                koneAreaRequest.allHTTPHeaderFields = headers
                
                let areaSession = URLSession.shared
                let areaDataTask = areaSession.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                    if (error != nil) {
                        print(error)
                    } else {
                        let httpResponse = response as? HTTPURLResponse
                        print(httpResponse)
                    }
                })
                
                dataTask.resume()
            }
            catch {
                print ("EXception")
            }
        }
        task.resume()
    }
    
    @objc func recordTapped() {
        if recorder == nil {
            startRecording()
            recordButton.setTitle("Recording...", for: .normal)
        } else {
            finishRecording(success: true)
            recordButton.setTitle("Record", for: .normal)
            self.responseLabel =  UILabel(frame: CGRect(x: 120, y: 200, width: 200, height: 21))
            self.responseLabel.text = "fetching result"
            view.addSubview(responseLabel)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    
}
