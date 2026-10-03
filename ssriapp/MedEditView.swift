//
//  MedEditView.swift
//  ssriapp
//
//  Created by Finlay Carson Moretti on 03/10/2026.
//

import SwiftUI

struct MedEditView: View {
    var body: some View {
        Form{
            Text("This is the edit page")
            TextField(/*@START_MENU_TOKEN@*/"Placeholder"/*@END_MENU_TOKEN@*/, text: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Value@*/.constant("")/*@END_MENU_TOKEN@*/)
        }
    }
}

#Preview {
    MedEditView()
}
