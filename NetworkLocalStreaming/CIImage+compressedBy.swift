//
//  CIImage+compressedBy.swift
//  NetworkLocalStreaming
//
//  Created by Ilya Gruzhevski on 10/11/2018.
//  Copyright © 2018 Ilya Gruzhevski. All rights reserved.
//

import UIKit

extension CIImage {
	
	// Effective compression should be done, better solutions could be
	// https://developer.apple.com/documentation/compression
	// https://github.com/DroidsOnRoids/SwiftCompressor
	func compressed(by factor: CGFloat) -> Data? {
		let context = CIContext()
		let cgImage = context.createCGImage(self, from: self.extent)!
		return UIImage(cgImage: cgImage).jpegData(compressionQuality: factor)
	}
}
