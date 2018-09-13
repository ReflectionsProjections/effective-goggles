//
//  ScanViewController.swift
//  Effective Goggles
//
//  Created by Yasha Mostofi on 9/13/18.
//  Copyright © 2018 Yasha Mostofi. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import Alamofire
import SwiftyJSON

let arnavUserID = "google115874673323414803423"

class ScannerViewController: BaseViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    let hapticGenerator = UINotificationFeedbackGenerator()
    
    var loadFailed = false
    var respondingToQRCodeFound = true
    
    var lookingUpUserAlertController: UIAlertController?
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBOutlet var eventButton: UIBarButtonItem!
    @IBAction func eventButtonAction(_ sender: Any) {
        eventAlert()
    }
    
    func eventAlert() {
        let alert = UIAlertController(title: "Event", message: "Please Choose Event", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Check In", style: .default, handler: { (action) in
            EventManager.sharedinstance.currentEvent = EventManager.sharedinstance.checkInEvent()
            self.eventButton.title = "Check In"
        }))
        for event in EventManager.sharedinstance.possibleEvents() {
            if event.isCheckin { continue }
            alert.addAction(UIAlertAction(title: event.name, style: .default, handler: { (action) in
                print(event.name)
                EventManager.sharedinstance.currentEvent = event
                self.eventButton.title = event.name
            }))
        }
        self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - UIViewController
extension ScannerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentEvent = EventManager.sharedinstance.currentEvent {
            eventButton.title = currentEvent.name
        } else {
            EventManager.sharedinstance.currentEvent = EventManager.sharedinstance.checkInEvent()
            eventButton.title = EventManager.sharedinstance.checkInEvent().name
        }
        setupCaptureSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if loadFailed {
            fatalError("load failed")
            //            presentErrorController(
            //                title: "Scanning not supported",
            //                message: "Your device does not support scanning a code from an item. Please use a device with a camera.",
            //                dismissParentOnCompletion: false
            //            )
        } else if captureSession?.isRunning == false {
            previewLayer?.frame = view.layer.bounds
            DispatchQueue.main.async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            DispatchQueue.main.async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: UINavigationControllerDelegate
extension ScannerViewController: UINavigationControllerDelegate {
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        return .portrait
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate
extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        let metadataOutput = AVCaptureMetadataOutput()
        
        guard
            let captureSession = captureSession,
            let videoCaptureDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
            captureSession.canAddInput(videoInput),
            captureSession.canAddOutput(metadataOutput)
            else {
                loadFailed = true
                return
        }
        
        captureSession.addInput(videoInput)
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard respondingToQRCodeFound else { return }
        if let code = (metadataObjects.first as? AVMetadataMachineReadableCodeObject)?.stringValue {
            found(code: code)
        }
    }
    
    func found(code: String) {
        print(code)
        AudioServicesPlaySystemSound(1004)
        hapticGenerator.notificationOccurred(.success)
        respondingToQRCodeFound = false
        guard let currentEvent = EventManager.sharedinstance.currentEvent else {
            self.eventAlert()
            return
        }
        
        // hackillinois://info?userid=USERID
        // parse stringValue to user ID
        guard let qrURL = URL(string: code),
            let userID = qrURL["userid"] else {
                let alert = UIAlertController(title: "Bad QR Code", message: "Invalid QR Code!", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default) { [weak self] (_) in
                    self?.respondingToQRCodeFound = true
                    return
                }
                alert.addAction(okayAction)
                DispatchQueue.main.async { [weak self] in
                    self?.present(alert, animated: true) {
                    }
                }
                return
        }
        print(userID)
        
        // Set up POST request
        let headers: HTTPHeaders = [
            "Authorization": jwt
        ]
        var parameters: Parameters = [
            "eventName": currentEvent.name,
            "userId":  userID
        ]
        var endpoint = "/event/track/"
        if currentEvent.isCheckin {
            endpoint = "/checkin/"
            parameters = [
                "id": userID,
                "override": true,
                "hasCheckedIn": true,
                "hasPickedUpSwag": true
            ]
        }
        print(parameters)
        print("https://api.reflectionsprojections.org\(endpoint)")
        Alamofire.request( "https://api.reflectionsprojections.org"+endpoint, method: .post,
                           parameters: parameters, encoding: JSONEncoding.default,
                           headers: headers).validate().responseJSON { response in
                            if let data = response.data {
                                do {
                                    let json = try JSON(data: data)
                                    print(json)
                                } catch {
                                    print("Error: \(data)")
                                }
                            }
                            var message:String = ""
                            var title:String = ""
                            switch response.result {
                            case .success:
                                message = "Attendee can participate"
                                title = "Success!"
                            case .failure:
                                message = "Attendee has already participated"
                                title = "ERROR!"
                            }
                            // Alert user of POST result
                            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                            let okayAction = UIAlertAction(title: "Okay", style: .default) { [weak self] (_) in
                                self?.respondingToQRCodeFound = true
                            }
                            alert.addAction(okayAction)
                            DispatchQueue.main.async { [weak self] in
                                self?.present(alert, animated: true)
                            }
        }
    }
}

extension URL {
    subscript(queryParam:String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParam })?.value
    }
}
