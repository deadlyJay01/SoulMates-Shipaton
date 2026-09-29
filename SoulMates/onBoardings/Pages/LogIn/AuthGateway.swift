//
//  AuthGateway.swift
//  SoulMates
//

import SwiftUI

/// A single screen that swaps between Login and SignUp *in place*,
/// instead of pushing/popping them on the navigation stack.
/// This makes switching between them behave the same way
/// no matter which stack (Greeting or Onboarding) pushed this screen.
struct AuthGateway: View {
    @State private var isLoginMode: Bool
    @State private var phoneToPrefill: String

    init(startInLogin: Bool = false, initialPhone: String = "") {
        _isLoginMode = State(initialValue: startInLogin)
        _phoneToPrefill = State(initialValue: initialPhone)
    }

    var body: some View {
        Group {
            if isLoginMode {
                Number_LogIn(
                    initialPhone: phoneToPrefill,
                    onSwitchToSignUp: {
                        isLoginMode = false
                    }
                )
            } else {
                Number_SignUp(
                    onSwitchToLogin: { phone in
                        phoneToPrefill = phone
                        isLoginMode = true
                    }
                )
            }
        }
    }
}
