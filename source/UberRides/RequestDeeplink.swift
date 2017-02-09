//
//  RequestDeeplink.swift
//  UberRides
//
//  Copyright © 2015 Uber Technologies, Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import UIKit

// RequestDeeplink builds and executes a deeplink to the native Uber app.
open class RequestDeeplink: NSObject {
    fileprivate var parameters: QueryParameters
    fileprivate var clientID: String
    fileprivate var deeplinkURI: String?
    fileprivate var source: RequestDeeplink.SourceParameter
    
    public init(withClientID: String, fromSource: SourceParameter = .deeplink) {
        parameters = QueryParameters()
        clientID = withClientID
        source = fromSource
        parameters.setParameter(.clientID, parameterValue: clientID)
    }
    
    /**
     Build a deeplink URI.
     */
    open func build() -> String {
        if !pickupLocationSet() {
            setPickupLocationToCurrentLocation()
        }
        
        if !parameters.pendingChanges {
            return deeplinkURI!
        }
        
        var components = URLComponents()
        components.scheme = "uber"
        components.host = ""
        components.queryItems = parameters.getQueryItems()
        
        parameters.pendingChanges = false;
        
        deeplinkURI = components.string?.removingPercentEncoding
        return deeplinkURI!
    }
    
    /**
     Execute deeplink to launch the Uber app. Redirect to the app store if the app is not installed.
     */
    open func execute() {
        let deeplinkURL = createURL(deeplinkURI!)
        let appstoreURL = createURL("https://m.uber.com/sign-up?client_id=" + clientID)

        if UIApplication.shared.canOpenURL(deeplinkURL) {
            UIApplication.shared.openURL(deeplinkURL)
        } else {
            UIApplication.shared.openURL(appstoreURL)
        }
    }
    
    /**
     Set the user's current location as a default pickup location.
     */
    open func setPickupLocationToCurrentLocation() {
        parameters.setParameter(.action, parameterValue: "setPickup")
        parameters.setParameter(.pickupDefault, parameterValue: "my_location")
        parameters.deleteParameters([.pickupLatitude, .pickupLongitude, .pickupAddress, .pickupNickname])
    }
    
    /**
     Set deeplink pickup location information.
     
     - parameter latitude: The latitude coordinate for pickup.
     - parameter longitude: The longitude coordinate for pickup.
     - parameter nickname: A URL-encoded string of the pickup location name. (Optional)
     - parameter address:  A URL-encoded string of the pickup address. (Optional)
     */
    open func setPickupLocation(latitude: Double, longitude: Double, nickname: String? = nil, address: String? = nil) {
        parameters.deleteParameters([.pickupNickname, .pickupAddress])
        parameters.setParameter(.action, parameterValue: "setPickup")
        parameters.setParameter(.pickupLatitude, parameterValue: "\(latitude)")
        parameters.setParameter(.pickupLongitude, parameterValue: "\(longitude)")
        
        if nickname != nil {
            parameters.setParameter(.pickupNickname, parameterValue: nickname!)
        }
        if address != nil {
            parameters.setParameter(.pickupAddress, parameterValue: address!)
        }
        
        parameters.deleteParameters([.pickupDefault])
    }
    
    /**
     Set deeplink dropoff location information.
     
     - parameter latitude: The latitude coordinate for dropoff.
     - parameter longitude: The longitude coordinate for dropoff.
     - parameter nickname: A URL-encoded string of the dropoff location name. (Optional)
     - parameter address:  A URL-encoded string of the dropoff address. (Optional)
     */
    open func setDropoffLocation(latitude: Double, longitude: Double, nickname: String? = nil, address: String? = nil) {
        parameters.deleteParameters([.dropoffNickname, .dropoffAddress])
        parameters.setParameter(.dropoffLatitude, parameterValue: "\(latitude)")
        parameters.setParameter(.dropoffLongitude, parameterValue: "\(longitude)")
        
        if nickname != nil {
            parameters.setParameter(.dropoffNickname, parameterValue: nickname!)
        }
        if address != nil {
            parameters.setParameter(.dropoffAddress, parameterValue: address!)
        }
    }
    
    /**
     Add a specific product ID to the deeplink. You can see product ID's for a given
     location with the Rides API `GET /v1/products` endpoint.
     */
    open func setProductID(_ productID: String) {
        parameters.setParameter(.productID, parameterValue: productID)
    }
    
    /**
     Return true if deeplink has set pickup latitude and longitude, false otherwise.
     */
    internal func pickupLocationSet() -> Bool {
        return (parameters.doesParameterExist(.pickupLatitude) && parameters.doesParameterExist(.pickupLongitude)) || parameters.doesParameterExist(.pickupDefault)
    }
    
    /**
     Possible sources for the deeplink.
     */
    @objc public enum SourceParameter: Int {
        case button
        case deeplink
    }
    
    /**
     Create an NSURL from a String. Add parameter for tracking and affiliation program.
     */
    private func createURL(_ url: String) -> URL {
        var url = url
        switch source {
        case .button:
            url += "&user-agent=rides-button-v0.1.0"
        case .deeplink:
            url += "user-agent=rides-deeplink-v0.1.0"
        }
        return URL(string: url)!
    }
}


// Store mapping of parameter names to values
private class QueryParameters: NSObject {
    fileprivate var params = [String: String]()
    fileprivate var pendingChanges: Bool
    
    fileprivate override init() {
        pendingChanges = false;
    }
    
    /**
     QueryParameterName is a set of query parameters than can be sent
     in a deeplink. `clientID` is a required query parameter.
     
     Optional query parameters can be used to automatically pass additional
     information, like a user's destination, over to the native Uber App.
     */
    fileprivate enum QueryParameterName: Int {
        case action
        case clientID
        case productID
        case pickupDefault
        case pickupLatitude
        case pickupLongitude
        case pickupNickname
        case pickupAddress
        case dropoffLatitude
        case dropoffLongitude
        case dropoffNickname
        case dropoffAddress
    }
    
    /**
     Adds a query parameter. If parameterName has already been assigned a value,
     its overwritten with parameterValue.
     */
    fileprivate func setParameter(_ parameterName: QueryParameterName, parameterValue: String) {
        params[stringFromParameterName(parameterName)] = stringFromParameterValue(parameterValue)
        pendingChanges = true
    }
    
    /**
     Removes key-value pair of all query parameters in array of parameter names.
    */
    fileprivate func deleteParameters(_ parameters: Array<QueryParameterName>) {
        for name in parameters {
            params.removeValue(forKey: stringFromParameterName(name))
        }
        pendingChanges = true
    }
    
    /**
     - returns: An array containing an NSURLQueryItem for every parameter
     */
    fileprivate func getQueryItems() -> Array<URLQueryItem> {
        var queryItems = [URLQueryItem]()
        
        for (parameterName, parameterValue) in params {
            let queryItem = URLQueryItem(name: parameterName, value: parameterValue)
            queryItems.append(queryItem)
        }
        
        return queryItems
    }
    
    /**
     - returns: true if given query parameter has been set; false otherwise.
     */
    fileprivate func doesParameterExist(_ parameterName: QueryParameterName) -> Bool {
        return params[stringFromParameterName(parameterName)] != nil
    }
    
    fileprivate func stringFromParameterName(_ name: QueryParameterName) -> String {
        switch name {
        case .action:
            return "action"
        case .clientID:
            return "client_id"
        case .productID:
            return "product_id"
        case .pickupDefault:
            return "pickup"
        case .pickupLatitude:
            return "pickup[latitude]"
        case .pickupLongitude:
            return "pickup[longitude]"
        case .pickupNickname:
            return "pickup[nickname]"
        case .pickupAddress:
            return "pickup[formatted_address]"
        case .dropoffLatitude:
            return "dropoff[latitude]"
        case .dropoffLongitude:
            return "dropoff[longitude]"
        case .dropoffNickname:
            return "dropoff[nickname]"
        case .dropoffAddress:
            return "dropoff[formatted_address]"
        }
    }
    
    fileprivate func stringFromParameterValue(_ value: String) -> String {
        let customAllowedChars =  CharacterSet(charactersIn: " =\"#%/<>?@\\^`{|}!$&'()*+,:;[]%").inverted
        return value.addingPercentEncoding(withAllowedCharacters: customAllowedChars)!
    }
}
