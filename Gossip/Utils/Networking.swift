//
//  Networking.swift
//  Gossip
//
//

import Foundation

enum NetworkingError: Error {
    case encodingFailed(innerError: EncodingError)
    case decodingFailed(innerError: DecodingError)
    case invalidStatusCode(statusCode: Int)
    case requestFailed(innerError: URLError)
    case jsendError(statusCode: Int, message: String)
    case otherError(innerError: Error)
    case emptyResponseButContentExpected
}

struct NoContent: Encodable, Decodable {}

enum Networking {
    static func get<T: Decodable, F: Decodable & Sendable>(
        _ url: URL,
        failType: F.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await perform(request, failType: failType)
    }
    
    static func post<T: Decodable, B: Encodable, F: Decodable & Sendable>(
        _ url: URL,
        body: B,
        failType: F.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch let error as EncodingError {
            throw NetworkingError.encodingFailed(innerError: error)
        } catch {
            throw NetworkingError.otherError(innerError: error)
        }

        return try await perform(request, failType: failType)
    }
    
    static func patch<T: Decodable, B: Encodable, F: Decodable & Sendable>(
        _ url: URL,
        body: B,
        failType: F.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch let error as EncodingError {
            throw NetworkingError.encodingFailed(innerError: error)
        } catch {
            throw NetworkingError.otherError(innerError: error)
        }
        return try await perform(request, failType: failType)
    }
    
    static func put<T: Decodable, B: Encodable, F: Decodable & Sendable>(
        _ url: URL,
        body: B,
        failType: F.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        if !(body is NoContent) {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch let error as EncodingError {
                throw NetworkingError.encodingFailed(innerError: error)
            } catch {
                throw NetworkingError.otherError(innerError: error)
            }
        }

        return try await perform(request, failType: failType)
    }
    
    static func delete<T: Decodable, F: Decodable & Sendable>(
        _ url: URL,
        failType: F.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        return try await perform(request, failType: failType)
    }

    static func upload<T: Decodable, F: Decodable & Sendable>(
        _ url: URL,
        body: Data,
        contentType: String,
        failType: F.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return try await perform(request, failType: failType)
    }
    
    private static func perform<T: Decodable, F: Decodable & Sendable>(
        _ request: URLRequest,
        failType: F.Type
    ) async throws -> T {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkingError.invalidStatusCode(statusCode: -1)
            }

            let statusCode = httpResponse.statusCode
            
            switch statusCode {
            case 200...299:
                if statusCode == 204 {
                    if T.self == NoContent.self {
                        return NoContent() as! T
                    } else {
                        throw NetworkingError.emptyResponseButContentExpected
                    }
                }

                if T.self == NoContent.self {
                    return NoContent() as! T
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
                    
                    let response = try decoder.decode(JSendResponse<T>.self, from: data)
                    return response.data
                } catch let decodingError as DecodingError {
                    throw NetworkingError.decodingFailed(innerError: decodingError)
                } catch {
                    throw NetworkingError.otherError(innerError: error)
                }
                
            case 400...499:
                let failResponse: JSendResponse<F>
                do {
                    failResponse = try JSONDecoder().decode(JSendResponse<F>.self, from: data)
                } catch let decodingError as DecodingError {
                    throw NetworkingError.decodingFailed(innerError: decodingError)
                } catch {
                    throw NetworkingError.otherError(innerError: error)
                }

                throw JSendFailError(statusCode: statusCode, data: failResponse.data)

            case 500...599:
                do {
                    let errorResponse = try JSONDecoder().decode(JSendError.self, from: data)
                    throw NetworkingError.jsendError(statusCode: statusCode, message: errorResponse.message)
                } catch let decodingError as DecodingError {
                    throw NetworkingError.decodingFailed(innerError: decodingError)
                } catch {
                    throw NetworkingError.otherError(innerError: error)
                }

            default:
                throw NetworkingError.invalidStatusCode(statusCode: statusCode)
            }
    }
}
