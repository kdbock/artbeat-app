import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    private var mapView: GMSMapView!
    private var initialLatitude: Double = 0.0
    private var initialLongitude: Double = 0.0
    
    init(latitude: Double = 0.0, longitude: Double = 0.0) {
        self.initialLatitude = latitude
        self.initialLongitude = longitude
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the initial camera position
        let camera = GMSCameraPosition.camera(
            withLatitude: initialLatitude,
            longitude: initialLongitude,
            zoom: 15.0
        )
        
        // Create and configure the map view
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        
        // Add initial marker
        addMarker(latitude: initialLatitude, longitude: initialLongitude)
        
        // Add close button
        setupCloseButton()
    }
    
    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 8
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func addMarker(latitude: Double, longitude: Double) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        marker.map = mapView
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
