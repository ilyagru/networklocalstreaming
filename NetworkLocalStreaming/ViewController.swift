//
//  ViewController.swift
//  NetworkLocalStreaming
//
//  Created by Ilya Gruzhevski on 10/11/2018.
//  Copyright © 2018 Ilya Gruzhevski. All rights reserved.
//

import UIKit
import Network
import AVFoundation

class ViewController: UIViewController {
	
	@IBOutlet weak var previewView: UIView!
	@IBOutlet weak var outputImageView: UIImageView!
	
	// Custom camera tutorial
	// https://medium.com/@rizwanm/https-medium-com-rizwanm-swift-camera-part-1-c38b8b773b2
	// https://medium.com/@rizwanm/swift-camera-part-2-c6de440a9404
	private var captureSession: AVCaptureSession?
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
	private var captureVideoOutput: AVCaptureVideoDataOutput?
	
	private var client: Client?
	private var server: Server?
	
	func clientDidConnect() {
		print("Controller: client connected!")
	}
	
	func serverDidConnect() {
		print("Controller: server connected!")
	}
	
	func serverDidAdvertise() {
		print("Controller: server listening!")
	}
	
	func serverDidReceive(frame: Data) {
		guard let image = UIImage(data: frame) else { return }
		
		DispatchQueue.main.async {
			self.outputImageView.image = image
		}
	}
	
	// Init the client, setup the camera
	@IBAction func startClient(_ sender: UIButton) {
		// Insert the name of the server (the name of the device started the server)
		client = Client(serverName: Constants.serverName)
		client?.controller = self
		
		setupCamera()
		setupCameraOutput()
	}
	
	// Init the server
	@IBAction func startServer(_ sender: UIButton) {
		server = Server()
		server?.controller = self
	}
	
	private func setupCamera() {
		// https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/
		let captureDevice = AVCaptureDevice.default(for: .video)!
		
		do {
			let input = try AVCaptureDeviceInput(device: captureDevice)
			captureSession = AVCaptureSession()
			captureSession?.sessionPreset = AVCaptureSession.Preset.low // Low quality for now
			captureSession?.addInput(input)
		} catch {
			print(error)
		}
		
		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
		videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
		videoPreviewLayer?.frame = previewView.layer.bounds
		previewView.layer.addSublayer(videoPreviewLayer!)
		
		captureSession?.startRunning()
	}
	
	private func setupCameraOutput() {
		// https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput
		captureVideoOutput = AVCaptureVideoDataOutput()
		let connection = captureVideoOutput?.connection(with: .video)
		connection?.videoOrientation = .portrait
		connection?.isVideoMirrored = true
		captureSession?.addOutput(captureVideoOutput!)
		
		captureVideoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Sample buffer queue"))
	}
	
	
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
	
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		// Captured frame!
		guard let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return
		}
		let ciImage = CIImage(cvPixelBuffer: imageBuffer)
		
		if let frame = ciImage.compressed(by: 0.1) {
			client?.send(frames: [frame])
		}
	}
	
}
