//
//  RequestButton.swift
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


import UIKit

// RequestButton implements a button on the touch screen to request a ride.
open class RequestButton: UIButton {
    var deeplink: RequestDeeplink?
    var contentWidth: CGFloat = 0
    var contentHeight: CGFloat = 0
    let padding: CGFloat = 8
    let imageSize: CGFloat = 28
    var buttonStyle: RequestButtonColorStyle
    
    let uberImageView: UIImageView!
    let uberTitleLabel: UILabel!
    
    // initializer to use in storyboard
    required public init?(coder aDecoder: NSCoder) {
        uberImageView = UIImageView()
        uberTitleLabel = UILabel()
        buttonStyle = .black
        super.init(coder: aDecoder)
        setUp(.black)
    }
    
    public convenience init() {
        self.init(colorStyle: .black)
    }
    
    // swift-style initializer
    public init(colorStyle: RequestButtonColorStyle) {
        uberImageView = UIImageView()
        uberTitleLabel = UILabel()
        buttonStyle = colorStyle
        super.init(frame: CGRect.zero)
        setUp(colorStyle)
    }
    
    fileprivate func setUp(_ colorStyle: RequestButtonColorStyle) {
        do {
            try setDeeplink()
            addTarget(self, action: #selector(RequestButton.uberButtonTapped(_:)), for: .touchUpInside)
        } catch RequestButtonError.nullClientID {
            print("No Client ID attached to the deeplink.")
        } catch let error {
            print(error)
        }
        
        setContent()
        setConstraints()
        setColorStyle(colorStyle)
    }
    
    // build and attach a deeplink to the button
    fileprivate func setDeeplink() throws {
        guard RidesClient.sharedInstance.hasClientID() else {
            throw RequestButtonError.nullClientID
        }
        
        let clientID = RidesClient.sharedInstance.clientID
        deeplink = RequestDeeplink(withClientID: clientID!, fromSource: .button)
    }
    
    /**
     Set the user's current location as a default pickup location.
     */
    open func setPickupLocationToCurrentLocation() {
        if RidesClient.sharedInstance.hasClientID() {
            deeplink!.setPickupLocationToCurrentLocation()
        }
    }
    
    /**
     Set deeplink pickup location information.
     
     - parameter latitude:  The latitude coordinate for pickup
     - parameter longitude: The longitude coordinate for pickup
     - parameter nickname:  Optional pickup location name
     - parameter address:   Optional pickup location address
     */
    open func setPickupLocation(latitude: Double, longitude: Double, nickname: String? = nil, address: String? = nil) {
        if RidesClient.sharedInstance.hasClientID() {
            deeplink!.setPickupLocation(latitude: latitude, longitude: longitude, nickname: nickname, address: address)
        }
    }
    
    /**
     Set deeplink dropoff location information.
     
     - parameter latitude:  The latitude coordinate for dropoff
     - parameter longitude: The longitude coordinate for dropoff
     - parameter nickname:  Optional dropoff location name
     - parameter address:   Optional dropoff location address
     */
    open func setDropoffLocation(latitude: Double, longitude: Double, nickname: String? = nil, address: String? = nil) {
        if RidesClient.sharedInstance.hasClientID() {
            deeplink!.setDropoffLocation(latitude: latitude, longitude: longitude, nickname: nickname, address: address)
        }
    }
    
    /**
     Add a specific product ID to the deeplink. You can see product ID's for a given
     location with the Rides API `GET /v1/products` endpoint.
     
     - parameter productID: Unique identifier of the product to populate in pickup
     */
    open func setProductID(_ productID: String) {
        if RidesClient.sharedInstance.hasClientID() {
            deeplink!.setProductID(productID)
        }
    }
    
    // add title, image, and sizing configuration
    fileprivate func setContent() {
        // add title label
        let bundle = Bundle(for: RequestButton.self)
        uberTitleLabel.text = NSLocalizedString("RequestButton.TitleText", bundle: bundle, comment: "Request button description")
        uberTitleLabel.font = UIFont.systemFont(ofSize: 17)
        uberTitleLabel.numberOfLines = 1;
        
        // add image
        let badge = getImage("Badge")
        uberImageView.image = badge
        
        // update content sizes
        let titleSize = uberTitleLabel!.intrinsicContentSize
        contentWidth += titleSize.width + badge.size.width
        contentHeight = max(titleSize.height, badge.size.height)
        
        // rounded corners
        clipsToBounds = true
        layer.cornerRadius = 5
        
        // set to false for constraint-based layouts
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    // get image from media directory
    fileprivate func getImage(_ name: String) -> UIImage {
        let bundle = Bundle(for: RequestButton.self)
        let image = UIImage(named: name, in: bundle, compatibleWith: nil)
        return image!
    }
    
    fileprivate func setConstraints() {
        addSubview(uberImageView)
        addSubview(uberTitleLabel)
        
        // store constraints and metrics in dictionaries
        let views = ["image": uberImageView!, "label": uberTitleLabel!]
        let metrics = ["padding": padding, "imageSize": imageSize]
        
        // set to false for constraint-based layouts
        uberImageView?.translatesAutoresizingMaskIntoConstraints = false
        uberTitleLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        // prioritize constraints
        uberTitleLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        
        // create layout constraints
        let horizontalConstraint: NSArray = NSLayoutConstraint.constraints(withVisualFormat: "H:|-padding-[image(24)]-padding-[label]-padding-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views) as NSArray
        let imageVerticalViewConstraint: NSArray = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[image(24)]-|", options: NSLayoutFormatOptions.alignAllLeading, metrics: nil, views: views) as NSArray
        let labelVerticalViewConstraint: NSArray = NSLayoutConstraint.constraints(withVisualFormat: "V:|-padding-[label]-padding-|", options: NSLayoutFormatOptions.alignAllLeading, metrics: metrics, views: views) as NSArray
        
        // add layout constraints
        addConstraints(horizontalConstraint as! [NSLayoutConstraint])
        addConstraints(imageVerticalViewConstraint as! [NSLayoutConstraint])
        addConstraints(labelVerticalViewConstraint as! [NSLayoutConstraint])
    }
    
    // set color scheme, default is black background with white font
    fileprivate func setColorStyle(_ style: RequestButtonColorStyle) {
        buttonStyle = style
        
        switch style {
        case .black:
            uberTitleLabel.textColor = uberUIColor(.uberWhite)
            backgroundColor = uberUIColor(.uberBlack)
        case .white :
            uberTitleLabel.textColor = uberUIColor(.uberBlack)
            backgroundColor = uberUIColor(.uberWhite)
        }
    }
    
    // override to maintain fit-to-content size
    open override var intrinsicContentSize : CGSize {
        let width = (3 * padding) + contentWidth
        let height = (2 * padding) + contentHeight
        return CGSize(width: width, height: height)
    }
    
    // override to change colors when button is tapped
    override open var isHighlighted: Bool {
        didSet {
            if buttonStyle == .black {
                if isHighlighted {
                    backgroundColor = uberUIColor(.blackHighlighted)
                } else {
                    backgroundColor = uberUIColor(.uberBlack)
                }
            } else if buttonStyle == .white {
                if isHighlighted {
                    backgroundColor = uberUIColor(.whiteHighlighted)
                } else {
                    backgroundColor = uberUIColor(.uberWhite)
                }
            }
        }
    }
    
    // initiate deeplink when button is tapped
    open func uberButtonTapped(_ sender: UIButton) {
        if RidesClient.sharedInstance.hasClientID() {
            deeplink!.build()
            deeplink!.execute()
        }
    }
}

@objc public enum RequestButtonColorStyle: Int {
    case black
    case white
}

private enum RequestButtonError: Error {
    case nullClientID
}
