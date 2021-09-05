
//  HomeViewModel.swift
//  FastPay
//
//  Created by Phan, Quang Ha | Kawa | RP on 2021/09/04.
//

import Foundation
import SocketIO
import SwiftUI
import UIKit
import Combine

private let remote = ""
private let localhost = "http://localhost"

class HomeViewModel: ObservableObject {
    @Published var barcodeString: String?
    @Published var countdown: String = "00:00"
    @Published var expiresDate: Date?
    @Published var showPayment: Bool = false
    @Published var username = "username 1"
    @Published var currentUser: User?
    @Published var hostType: Int = 0
    @Published var storeId: String = "1"
    @Published var amount: String = "1200"
    
    var payment: Payment?
    
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private let decoder = HomeViewModel.createDecoder()
    
    private var domain: String {
        hostType == 0 ? localhost : remote
    }
    private var manager: SocketManager!
    
    init() {}
    func transform() {}
    
    func refresh() {
        timerCancellable = nil
        countdown = "05:00"
        fetchBarcode()
    }
    
    func connectSocket() {
        manager = SocketManager(socketURL: URL(string: domain)!, config: [.log(true), .compress])
        let socket = manager.defaultSocket
        socket.disconnect()
        
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            guard let self = self else { return }
            print("socket connected")
            socket.emit("join", self.username)
        }
        
        socket.on("payment") { [weak self] data, ack in
            print("receive payment \(data)")
            ack.with("Got your currentAmount", "dude")
            
            guard let json = (data.first as? [String: Any]) else { return }
            guard let self = self else { return }
            do {
                let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                self.payment = try self.decoder.decode(Payment.self, from: data)
                self.showPayment = true
                self.refresh()
            } catch {
                print(error.localizedDescription)
            }
        }
        
        socket.on("joined") { [weak self] data, ack in
            print("Joined")
            guard let json = (data.first as? [String: Any]) else { return }
            guard let self = self else { return }
            do {
                let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                self.currentUser = try self.decoder.decode(User.self, from: data)
                self.fetchBarcode()
            } catch {
                print(error.localizedDescription)
            }
        }
        
        socket.connect()
    }
    
    func fetchBarcode() {
        guard let userId = self.currentUser?._id else { return }
        let url = URL(string: domain + "/create_code?user_id=\(userId)")!
        
        let response = URLSession.shared
            .dataTaskPublisher(for: url)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return element.data
            }
            .decode(type: CreateBarcodeResponse.self, decoder: self.decoder)
            .catch { error -> Just<CreateBarcodeResponse> in
                return Just(CreateBarcodeResponse.init(code: nil, expiresDate: nil, userId: nil))
            }.share()
        
        response.map { $0.code }
            .assertNoFailure()
            .receive(on: RunLoop.main)
            .assign(to: \.barcodeString, on: self)
            .store(in: &cancellables)
        
        response.map { $0.expiresDate }
            .assertNoFailure()
            .receive(on: RunLoop.main)
            .assign(to: \.expiresDate, on: self)
            .store(in: &cancellables)
        
        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .map { [weak self] lastUpdated -> String in
                guard let expireDate = self?.expiresDate,
                      expireDate > lastUpdated
                else { return "--:--" }
                
                let diff = abs(Int(lastUpdated.timeIntervalSince(expireDate)))
                let minute = diff / 60
                let second = diff % 60
                return String(format: "%02d:%02d", minute, second)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.countdown, on: self)
    }
    
    
    func createPaymentQR(code: String) -> String {
        return remote + "/make_payment?store_id=\(storeId)&amount=\(amount)&code=\(code)"
    }
    
    private static func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

struct CreateBarcodeResponse: Codable {
    let code: String?
    let expiresDate: Date?
    let userId: String?
}

struct Payment: Codable {
    let _id: String?
    let code: String?
    let storeId: String?
    let amount: String?
    let userId: String?
    let date: Date?
}

struct User: Codable {
    let _id: String?
    let username: String?
}

