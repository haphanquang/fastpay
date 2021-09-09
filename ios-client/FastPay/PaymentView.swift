
//  PaymentView.swift
//  FastPay
//
//  Created by Phan, Quang Ha | Kawa | RP on 2021/09/04.
//

import Foundation
import SwiftUI

struct PaymentView: View {
    @Environment(\.presentationMode) var presentationMode
    let payment: Payment
    
    var body: some View {
        VStack(spacing: 10) {
            Text("TADA!")
                .font(.title)
                .padding()
            
            HStack {
                Text("Payment").bold()
                Spacer()
                Text(payment._id ?? "-")
            }
            
            HStack {
                Text("Store id").bold()
                Spacer()
                Text(payment.storeId ?? "-")
            }
            
            HStack {
                Text("Amount").bold()
                Spacer()
                Text(payment.amount ?? "-")
            }
            
            HStack {
                Text("Bar code").bold()
                Spacer()
                Text(payment.code ?? "-")
            }
            
            HStack {
                Text("Date").bold()
                Spacer()
                Text((payment.date ?? Date()), style: .time)
            }
            
            Spacer()
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
            }

        }.padding(20)
    }
}
