//
//  OrderViewController.swift
//  dash-and-dine-mobile
//
//  Created by Matt Gordon on 3/3/17.
//  Copyright © 2017 Matt Gordon. All rights reserved.
//

import UIKit
import SwiftyJSON
import MapKit

class OrderViewController: UIViewController {
    
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    @IBOutlet weak var tbvMeals: UITableView!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var lbStatus: UILabel!
    
    let activityIndicator = UIActivityIndicatorView()
    
    var tray = [JSON]()
    
    var destination: MKPlacemark?
    var source: MKPlacemark?
    
    var driverPin: MKPointAnnotation!
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuBarButton.target = self.revealViewController()
            menuBarButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        getLatestOrder()
        
    }
    
    func getLatestOrder() {
        
        Helpers.showActivityIndicator(activityIndicator, self.view)
        
        APIManager.shared.getLatestOrder { (json) in
            
            print(json)
            
            let order = json["order"]
            
            if order["status"] != nil {
            
                if let orderDetails = order["order_details"].array {
                    self.lbStatus.text = order["status"].string!.uppercased()
                    self.tray = orderDetails
                    self.tbvMeals.reloadData()
                }
                
                let from = order["restaurant"]["address"].string!
                let to = order["address"].string!
                
                self.getLocation(from, "RESTAURANT", { (src) in
                    self.source = src
                    
                    self.getLocation(to, "CUSTOMER", { (dest) in
                        self.destination = dest
                        self.getDirections()
                    })
                })
                
                if order["status"] != "Delivered" {
                    self.setTimer()
                }
            } else {
            
                self.map.isHidden = true
                self.lbStatus.isHidden = true
                self.tbvMeals.isHidden = true
                
                // Show message here
                
                let lbMessage = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 40))
                lbMessage.center = self.view.center
                lbMessage.textAlignment = NSTextAlignment.center
                lbMessage.text = "You don't have any orders."
                
                self.view.addSubview(lbMessage)
                Helpers.hideActivityIndicator(self.activityIndicator)
            }// else display label showing that user doesn't have any order, hide UI controlsq
        }
    }
    
    func setTimer() {
    
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(getDriverLocation(_:)),
            userInfo: nil,
            repeats: true)
    }
    
    func getDriverLocation(_ sender: AnyObject) {
        APIManager.shared.getDriverLocation { (json) in
            
//            print(json)
            if let location = json["location"].string {
            
                self.lbStatus.text = "ON THE WAY"
                
                let split = location.components(separatedBy: ",")
                let lat = split[0]
                let lng = split[1]
                
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat)!, longitude: CLLocationDegrees(lng)!)
                
                // Create pin annotaion for driver
                if self.driverPin != nil {
                    self.driverPin.coordinate = coordinate
                } else {
                    self.driverPin = MKPointAnnotation()
                    self.driverPin.coordinate = coordinate
                    self.driverPin.title = "DRIVER"
                    self.map.addAnnotation(self.driverPin)
                }
                
                // Reset zoom Rect to cover all 3 locations
                self.autoZoom()
                
            } else {
            
                self.timer.invalidate()
            }
        }
    }
    
    func autoZoom() {
    
        var zoomRect = MKMapRectNull
        for annotation in self.map.annotations {
            let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
            let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1)
            zoomRect = MKMapRectUnion(zoomRect, pointRect)
        }
        
        let insetWidth = -zoomRect.size.width * 0.2
        let insetHeight = -zoomRect.size.height * 0.2
        let insetRect = MKMapRectInset(zoomRect, insetWidth, insetHeight)
        
        self.map.setVisibleMapRect(insetRect, animated: true)
    }
}

extension OrderViewController: MKMapViewDelegate {
    
    // #1 - Delegate method of MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        
        return renderer
    }
    
    // #2 - Convert an address string to a location on the map
    func getLocation(_ address: String,_ title: String,_ completionHandler: @escaping (MKPlacemark) -> Void) {
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            
            if (error != nil) {
                print("Error: ", error!)
            }
            
            if let placemark = placemarks?.first {
                
                let coordinates: CLLocationCoordinate2D = placemark.location!.coordinate
                
                // Create a pin
                let dropPin = MKPointAnnotation()
                dropPin.coordinate = coordinates
                dropPin.title = title
                
                self.map.addAnnotation(dropPin)
                completionHandler(MKPlacemark.init(placemark: placemark))
            }
        }
    }
    
    // #3 - Get direction and zoom to address
    func getDirections() {
        
        let request = MKDirectionsRequest()
        request.source = MKMapItem.init(placemark: source!)
        request.destination = MKMapItem.init(placemark: destination!)
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            
            if error != nil {
                print("Error: ", error!)
            } else {
                // Show route
                self.showRoute(response: response!)
            }
        }
    }
    
    // #4 - Show route between locations and make a visible zoom
    func showRoute(response: MKDirectionsResponse) {
        
        for route in response.routes {
            self.map.add(route.polyline, level: MKOverlayLevel.aboveRoads)
        }
    }
    
    // #5 - Customize pin point with image
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let annotationIdentifier = "MyPin"
        
        var annotationView: MKAnnotationView?
        if let dequeueAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
        
            annotationView = dequeueAnnotationView
            annotationView?.annotation = annotation
        } else {
        
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        }
        
        if let annotationView = annotationView, let name = annotation.title! {
            switch name {
            case "DRIVER":
                annotationView.canShowCallout = true
                annotationView.image = UIImage(named: "driver_pin")
            case "RESTAURANT":
                annotationView.canShowCallout = true
                annotationView.image = UIImage(named: "food_pin")
            case "CUSTOMER":
                annotationView.canShowCallout = true
                annotationView.image = UIImage(named: "customer_pin")
            default:
                annotationView.canShowCallout = true
                annotationView.image = UIImage(named: "driver_pin")
            }
        }
        
        return annotationView
    }
}

extension OrderViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderItemCell", for: indexPath) as! OrderViewCell
        
        let item = tray[indexPath.row]
        cell.lbQty.text = String(item["quantity"].int!)
        cell.lbMealName.text = item["meal"]["name"].string
        cell.lbSubTotal.text = "$\(String(item["sub_total"].float!))"
        
        return cell
    }
}
