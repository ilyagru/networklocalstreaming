//
//  Client.swift
//  NetworkLocalStreaming
//
//  Created by Ilya Gruzhevski on 10/11/2018.
//  Copyright © 2018 Ilya Gruzhevski. All rights reserved.
//

import Foundation
import Network

class Client {
	
	var connection: NWConnection
	var queue: DispatchQueue
	weak var controller: ViewController?
	
	init(serverName: String) {
		queue = DispatchQueue(label: "Client Queue")
		// Create connection
		connection = NWConnection(to: .service(name: serverName, type: Constants.serviceType, domain: "local", interface: nil), using: .udp)
		// To increase the size of a UDP packet ?
		if let ipOptions = connection.parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
			ipOptions.version = .v6
			ipOptions.useMinimumMTU = false
		}
		// Set the state update handler
		connection.stateUpdateHandler = { [weak self] newState in
			switch newState {
			case .ready:
				print("Client ready")
				// Send the initial frame
				self?.sendInitialFrame()
			case .setup:
				print("Client setup")
			case .preparing:
				print("Client preparing")
			case .waiting(let error):
				print("Client waiting error ", error)
			case .cancelled:
				print("Client cancelled")
			case .failed(let error):
				print("Client failed error ", error)
			}
		}
		// Start the connection
		connection.start(queue: queue)
	}
	
	// Send the initial "hello" frame
	private func sendInitialFrame() {
		let helloMessage = "hello".data(using: .utf8)
		
		connection.send(content: helloMessage, completion: .contentProcessed({ error in
			if let error = error {
				print("Client send initial frame error ", error)
			}
		}))
		
		connection.receiveMessage { (content, context, isComplete, error) in
			if let _ = content {
				print("Got connected!")
				self.controller?.clientDidConnect()
			}
		}
	}
	
	// Send frames from the camera to the other device
	func send(frames: [Data]) {
		// Better to have such context ?
		let ipMetadata = NWProtocolIP.Metadata()
		ipMetadata.serviceClass = .interactiveVideo
		let context = NWConnection.ContentContext(identifier: "InteractiveVideo", metadata: [ ipMetadata ])
		
		connection.batch {
			for frame in frames {
				connection.send(content: frame, contentContext: context, completion: .contentProcessed({ (error) in
					if let error = error {
						print("Client send frames error ", error)
					}
				}))
			}
		}
	}
	
}
