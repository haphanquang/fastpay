
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
        VStack {
            
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
            } else {
                HStack {
                    Text("\(viewModel.username)" )
                        .font(.largeTitle)
                }.padding()
                Spacer()
                
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
                
            }

            Spacer()
        }.sheet(isPresented: $viewModel.showPayment, content: {
            PaymentView(payment: viewModel.payment!)
        })
        .onAppear(perform: {
            viewModel.transform()
        })
    }
}
