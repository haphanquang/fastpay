
//  HomeView.swift
//  FastPay
//
//  Created by Phan, Quang Ha | Kawa | RP on 2021/09/04.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    
    var body: some View {
        VStack(spacing: 12) {
            if viewModel.currentUser == nil {
                HStack {
                    TextField("enter username", text: $viewModel.username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button {
                        viewModel.connectSocket()
                    } label: {
                        Text("Connect")
                    }
                }.padding()
                
                Picker("Host?", selection: $viewModel.hostType) {
                    Text("Local").tag(0)
                    Text("Remote").tag(1)
                }
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
            } else {
                HStack {
                    Text("\(viewModel.username)" )
                        .font(.largeTitle)
                }.padding()
                
                HStack {
                    if let barcode = viewModel.barcodeString {
                        VStack {
                            BarcodeView(barcode: barcode)
                                .frame(width: 220, height: 80)
                                .layoutPriority(1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.green)
                                )
                            Text(barcode.inserting(separator: " ", every: 4))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .bold()
                        }
                        
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(white: 0.9))
                            .frame(width: 220, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.green)
                            )
                    }

                    
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            self.viewModel.refresh()
                        }, label: {
                            Image(systemName: "arrow.clockwise")
                        })
                        Text(viewModel.countdown)
                            .multilineTextAlignment(.leading)
                            .frame(width: 50)
                        Spacer().frame(height: 24)
                    }
                }
                if viewModel.hostType == 1 {
                    if let barcode = viewModel.barcodeString {
                        VStack(spacing: 8) {
                            Rectangle().fill(Color.gray).frame(height: 1)
                            
                            Text("Claim with your camera").font(.title2).padding()
                            
                            QRCodeView(qrcode: viewModel.createPaymentQR(code: barcode))
                                .frame(width: 120, height: 120)
                            
                            HStack {
                                Text("Store ID").bold()
                                TextField("", text: $viewModel.storeId)
                            }.padding(.top, 12)
                            
                            HStack {
                                Text("Amount").bold()
                                Text("¥")
                                TextField("", text: $viewModel.amount)
                            }
                            
                            Text(viewModel.createPaymentQR(code: barcode))
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }.padding()
                    }
                }
                
                Spacer()
            }
            
            Spacer()
            
            if viewModel.apiVersion.count > 0 {
                HStack {
                    Text("Version : \(viewModel.apiVersion)")
                    Spacer()
                }.padding()
            }
            
        }.sheet(isPresented: $viewModel.showPayment, content: {
            PaymentView(payment: viewModel.payment!)
        })
        .onAppear(perform: {
            viewModel.transform()
        })
    }
}
