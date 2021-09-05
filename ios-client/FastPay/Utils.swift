
//  Utils.swift
//  FastPay
//
//  Created by Phan, Quang Ha | Kawa | RP on 2021/09/04.
//

import Foundation
import UIKit
import SwiftUI

struct BarcodeView: UIViewRepresentable {
    let barcode: String
    
    func makeUIView(context: Context) -> UIImageView {
        UIImageView()
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = UIImage(barcode: barcode)
    }
}

struct QRCodeView: UIViewRepresentable {
    let qrcode: String
    
    func makeUIView(context: Context) -> UIImageView {
        UIImageView()
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = UIImage(qrcode: qrcode)
    }
}

extension UIImage {
    convenience init?(barcode: String) {
        let data = barcode.data(using: .ascii)
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        guard let ciImage = filter.outputImage else {
            return nil
        }
        self.init(ciImage: ciImage)
    }
    
    convenience init?(qrcode: String) {
        let data = qrcode.data(using: String.Encoding.ascii)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 3, y: 3)
        guard let ciImage = filter.outputImage?.transformed(by: transform) else {
            return nil
        }
        self.init(ciImage: ciImage)
    }
}

extension Collection {
    func unfoldSubSequences(limitedTo maxLength: Int) -> UnfoldSequence<SubSequence,Index> {
        sequence(state: startIndex) { start in
            guard start < self.endIndex else { return nil }
            let end = self.index(start, offsetBy: maxLength, limitedBy: self.endIndex) ?? self.endIndex
            defer { start = end }
            return self[start..<end]
        }
    }
    
    func every(n: Int) -> UnfoldSequence<Element,Index> {
        sequence(state: startIndex) { index in
            guard index < endIndex else { return nil }
            defer { index = self.index(index, offsetBy: n, limitedBy: endIndex) ?? endIndex }
            return self[index]
        }
    }
    
    var pairs: [SubSequence] { .init(unfoldSubSequences(limitedTo: 2)) }
}

extension String {
    mutating func insert<S: StringProtocol>(separator: S, every n: Int) {
        for index in indices.every(n: n).dropFirst().reversed() {
            insert(contentsOf: separator, at: index)
        }
    }
    func inserting<S: StringProtocol>(separator: S, every n: Int) -> Self {
        .init(unfoldSubSequences(limitedTo: n).joined(separator: separator))
    }
    
    var isLocalHost: Bool {
        return self.hasPrefix("http://localhost")
    }
}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        return formatter
    }()
}
