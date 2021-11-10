//
//  SecondScreenViewController.swift
//  WojtekProject
//
//  Created by Wojciech Kudrynski on 09/11/2021.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

protocol SecondScreenViewControllerDelegate: AnyObject {
    var savedUser: User? { get set }
}

class SecondScreenViewController: UIViewController {
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: SecondScreenViewControllerDelegate?
    private let locationManager = CLLocationManager()
    private var currentPlacemark: CLPlacemark?
    private var boundingRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
    var spinner = UIActivityIndicatorView(style: .large)
    
    private var places: [MKMapItem]? {
        didSet {
            reloadAnnotations()
        }
    }
    
    private var localSearch: MKLocalSearch? {
        willSet {
            places = nil
            localSearch?.cancel()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        searchBar.delegate = self
        
        if let name = delegate?.savedUser?.name,
           let surname = delegate?.savedUser?.surname,
           let phoneNumber = delegate?.savedUser?.phoneNumber {
            detailsLabel.text = "\(name), \(surname), \(phoneNumber)"
        } else {
            detailsLabel.text = "No details provided"
        }
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipe(_:)))
        swipeGesture.direction = .right
        self.view.addGestureRecognizer(swipeGesture)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestLocation()
    }
    
    @objc private func swipe(_ sender: UISwipeGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func reloadAnnotations() {
        let annotations = places?.map { (mapItem) -> MKAnnotation? in
            guard let coordinate = mapItem.placemark.location?.coordinate else { return nil }
            
            let annotation = Annotation(coordinate: coordinate)
            annotation.title = mapItem.name
            
            return annotation
        }
        if let annotations = annotations {
            mapView.addAnnotations(annotations.compactMap{ $0 })
        }
        tableView.reloadData()
    }
    
    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }
    
    private func search(using searchRequest: MKLocalSearch.Request) {
        // Confine the map search area to an area around the user's current location.
        
        self.view.addSubview(spinner)
        spinner.centerXAnchor.constraint(equalTo: mapView.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: mapView.centerYAnchor).isActive = true
        
        searchRequest.region = boundingRegion
        searchRequest.resultTypes = .pointOfInterest
        
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { [unowned self] (response, error) in
            guard error == nil else {
                self.displaySearchError(error)
                return
            }
            
            self.places = response?.mapItems
            
            // Used when setting the map's region in `prepareForSegue`.
            if let updatedRegion = response?.boundingRegion {
                self.boundingRegion = updatedRegion
                mapView.region = updatedRegion
            }
            spinner.removeFromSuperview()
        }
    }
    
    private func displaySearchError(_ error: Error?) {
        if let error = error as NSError?, let errorString = error.userInfo[NSLocalizedDescriptionKey] as? String {
            let alertController = UIAlertController(title: "Could not find any places.", message: errorString, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension SecondScreenViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemark, error) in
            guard error == nil else { return }
            
            self.boundingRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 12_000, longitudinalMeters: 12_000)
            self.mapView.region = self.boundingRegion
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }
}

extension SecondScreenViewController {
    private func requestLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}

extension SecondScreenViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        search(for: searchBar.text)
    }
}

extension SecondScreenViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        places?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath)
        cell.textLabel?.text = places?[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let suggestion = places?[indexPath.row] {
            searchBar.text = suggestion.name
            search(for: suggestion.name)
        }
    }
}
