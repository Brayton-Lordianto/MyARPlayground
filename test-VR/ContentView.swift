//
//  ContentView.swift
//  test-VR
//
//  Created by Brayton Lordianto on 8/2/22.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    var body: some View {
        return GreenSpace()
            .ignoresSafeArea()
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
