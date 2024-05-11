/* ----------------------------------------------------------------
 * :: :  M  E  T  A  V  E  R  S  E  :                            ::
 * ----------------------------------------------------------------
 * This software is Licensed under the terms of the Apache License,
 * version 2.0 (the "Apache License") with the following additional
 * modification; you may not use this file except within compliance
 * of the Apache License and the following modification made to it.
 * Section 6. Trademarks. is deleted and replaced with:
 *
 * Trademarks. This License does not grant permission to use any of
 * its trade names, trademarks, service marks, or the product names
 * of this Licensor or its affiliates, except as required to comply
 * with Section 4(c.) of this License, and to reproduce the content
 * of the NOTICE file.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND without even an
 * implied warranty of MERCHANTABILITY, or FITNESS FOR A PARTICULAR
 * PURPOSE. See the Apache License for more details.
 *
 * You should have received a copy for this software license of the
 * Apache License along with this program; or, if not, please write
 * to the Free Software Foundation Inc., with the following address
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 *         Copyright (C) 2024 Wabi Foundation. All Rights Reserved.
 * ----------------------------------------------------------------
 *  . x x x . o o o . x x x . : : : .    o  x  o    . : : : .
 * ---------------------------------------------------------------- */

#if os(macOS)

  import Foundation
  import Network

  @available(OSX 10.14, *)
  @objc(TimeoutProxyServer)
  public class TimeoutProxyServer: NSObject, @unchecked Sendable
  {
    let port: NWEndpoint.Port
    let targetPort: NWEndpoint.Port

    let queue = DispatchQueue(label: "TimeoutProxyServer")
    var listener: NWListener!
    var connections = [NWConnection]()

    let serverEndpoint = NWEndpoint.Host("127.0.0.1")

    private var _delay: Double = 0
    @objc public var delay: Double
    {
      get
      {
        _delay
      }
      set
      {
        queue.sync
        {
          _delay = newValue
        }
      }
    }

    private var _dropConnections: Bool = false
    @objc public var dropConnections: Bool
    {
      get
      {
        _dropConnections
      }
      set
      {
        queue.sync
        {
          _dropConnections = newValue
        }
      }
    }

    @objc public init(port: UInt16, targetPort: UInt16)
    {
      self.port = NWEndpoint.Port(rawValue: port)!
      self.targetPort = NWEndpoint.Port(rawValue: targetPort)!
    }

    @objc public func start() throws
    {
      listener = try NWListener(using: NWParameters.tcp, on: port)
      listener.newConnectionHandler = { [weak self] incomingConnection in
        guard let self else { return }
        connections.append(incomingConnection)
        incomingConnection.start(queue: queue)

        let targetConnection = NWConnection(host: serverEndpoint, port: targetPort, using: .tcp)
        targetConnection.start(queue: queue)
        connections.append(targetConnection)

        if dropConnections
        {
          return
        }

        queue.asyncAfter(deadline: .now() + delay)
        {
          copyData(from: incomingConnection, to: targetConnection)
          copyData(from: targetConnection, to: incomingConnection)
        }
      }
      listener.start(queue: queue)
    }

    @objc public func stop()
    {
      listener.cancel()
      queue.sync
      {
        for connection in connections
        {
          connection.forceCancel()
        }
      }
    }
  }

  @available(macOS 10.14, *)
  private func copyData(from: NWConnection, to: NWConnection)
  {
    from.receive(minimumIncompleteLength: 1, maximumLength: 8192)
    { data, context, isComplete, error in
      if let error
      {
        switch error
        {
          case .posix(.ECANCELED), .posix(.ECONNRESET):
            return
          default:
            fatalError("\(error)")
        }
      }

      guard let data
      else
      {
        if !isComplete
        {
          copyData(from: from, to: to)
        }
        return
      }
      to.send(content: data, contentContext: context ?? .defaultMessage,
              isComplete: isComplete, completion: .contentProcessed
              { _ in
                if !isComplete
                {
                  copyData(from: from, to: to)
                }
              })
    }
  }

#endif // os(macOS)
