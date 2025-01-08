//
//  API+GraphQl.swift
//  justclean
//
//  Created by Fahed Al-Ahmad on 04/06/2024.
//  Copyright © 2024 Justclean. All rights reserved.
//

import Foundation
import Apollo
import ApolloWebSocket

final class APIGraphQl: Sendable {
    
    private let apiUrl: URL
    private let apiKey: String
    private let userToken: String
   
    init(apiUrl: URL, apiKey: String, userToken: String) {
        self.apiUrl = apiUrl
        self.apiKey = apiKey
        self.userToken = userToken
    }
    
    func apolloClient() -> ApolloClient? {
        let store = ApolloStore()
        
        let webSocketClient = WebSocket(url: apiUrl, protocol: .graphql_ws)
        let webSocketTransport = WebSocketTransport(
            websocket: webSocketClient,
            config: .init(
                connectingPayload: [
                    HTTPHeaderField.apikey.rawValue: apiKey,
                    HTTPHeaderField.authentication.rawValue: "Bearer \(userToken)"
                ]
            )
        )
        
        /// An HTTP transport to use for queries and mutations
        let httpTransport: RequestChainNetworkTransport = RequestChainNetworkTransport(
            interceptorProvider: DefaultInterceptorProvider(store: store),
            endpointURL: apiUrl
        )
        
        /// A split network transport to allow the use of both of the above
        /// transports through a single `NetworkTransport` instance.
        let splitNetworkTransport = SplitNetworkTransport(
            uploadingNetworkTransport: httpTransport,
            webSocketNetworkTransport: webSocketTransport
        )
        
        /// Create a client using the `SplitNetworkTransport`.
        return ApolloClient(networkTransport: splitNetworkTransport, store: store)
    }
}
