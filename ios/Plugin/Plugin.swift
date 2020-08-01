import Foundation
import Capacitor
import GoogleMaps


@objc(CapacitorGoogleMaps)
public class CapacitorGoogleMaps: CAPPlugin, GMSMapViewDelegate, GMSPanoramaViewDelegate {

    var GOOGLE_MAPS_KEY: String = "";
    var mapViewController: GMViewController!;
    var streetViewController: GMStreetViewController!;
    var DEFAULT_ZOOM: Double = 12.0;
    var scrollMapView: ScrollMapView!;

    @objc func initialize(_ call: CAPPluginCall) {

        self.GOOGLE_MAPS_KEY = call.getString("key", "")!

        if self.GOOGLE_MAPS_KEY.isEmpty {
            call.error("GOOGLE MAPS API key missing!")
            return
        }
        GMSServices.provideAPIKey(self.GOOGLE_MAPS_KEY)
        call.success([
            "initialized": true
        ])
    }

    @objc func create(_ call: CAPPluginCall) {

        DispatchQueue.main.async {
            self.mapViewController = GMViewController();
            self.mapViewController.mapViewBounds = [
                "width": call.getDouble("width") ?? 500,
                "height": call.getDouble("height") ?? 500,
                "x": call.getDouble("x") ?? 0,
                "y": call.getDouble("y") ?? 0,
            ]
            self.mapViewController.cameraPosition = [
                "latitude": call.getDouble("latitude") ?? 0.0,
                "longitude": call.getDouble("longitude") ?? 0.0,
                "zoom": call.getDouble("zoom") ?? (self.DEFAULT_ZOOM)
            ]

            let screenSize = UIScreen.main.bounds

            self.scrollMapView = ScrollMapView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))

            self.scrollMapView.addSubview(self.mapViewController.view)
            self.bridge.viewController.view.addSubview(self.scrollMapView)
            self.mapViewController.GMapView.delegate = self
            call.success([
                   "created": true
            ])
        }
    }

    @objc func addMarker(_ call: CAPPluginCall) {

        let latitude = call.getDouble("latitude") ?? 0
        let longitude = call.getDouble("longitude") ?? 0
        let opacity = call.getFloat("opacity") ?? 1
        let title = call.getString("title") ?? ""
        let snippet = call.getString("snippet") ?? ""
        let isFlat = call.getBool("isFlat") ?? false
        let url = URL(string: call.getString("iconUrl", "")!)
        var imageData: Data?

        DispatchQueue.global().async {

            if url != nil {
                /* https://stackoverflow.com/a/27517280/5056792 */
                imageData = try? Data(contentsOf: url!)
            }

            DispatchQueue.main.async {
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                marker.title = title
                marker.snippet = snippet
                marker.isFlat = isFlat
                marker.opacity = opacity

                if imageData != nil {
                    marker.icon = UIImage(data: imageData!)
                }

                marker.map = self.mapViewController.GMapView

            }
        }

        call.success([
            "markerAdded": true
        ])
    }

    @objc func setMapType(_ call: CAPPluginCall) {

        let specifiedMapType = call.getString("type") ?? "normal"
        var mapType: GMSMapViewType;

        switch specifiedMapType {
            case "normal" :
                mapType = GMSMapViewType.normal

            case "hybrid" :
                mapType = GMSMapViewType.hybrid

            case "satellite" :
                mapType = GMSMapViewType.satellite

            case "terrain" :
                mapType = GMSMapViewType.terrain

            case "none" :
                mapType = GMSMapViewType.none

            default:
                mapType = GMSMapViewType.normal
        }

        DispatchQueue.main.async {
            self.mapViewController.GMapView.mapType = mapType
        }

        call.success([
            "mapTypeSet": specifiedMapType
        ])
    }

    @objc func setIndoorEnabled(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.mapViewController.GMapView.isIndoorEnabled = call.getBool("enabled", false)!
        }
    }

    @objc func accessibilityElementsHidden(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.mapViewController.GMapView.accessibilityElementsHidden = call.getBool("hidden", false)!
        }
    }

    @objc func enableCurrentLocation(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.mapViewController.GMapView.isMyLocationEnabled = call.getBool("enabled", false)!
        }
    }

    @objc func setTrafficEnabled(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.mapViewController.GMapView.isTrafficEnabled = call.getBool("enabled", false)!
        }
    }

    @objc func myLocation(_ call: CAPPluginCall) {
        let location = self.mapViewController.GMapView.myLocation;
        call.success([
            "latitude": (location?.coordinate.latitude)! as Double,
            "longitude": (location?.coordinate.longitude)! as Double
        ])
    }

    @objc func padding(_ call: CAPPluginCall) {
        let top = CGFloat(call.getFloat("top") ?? 0.0)
        let left = CGFloat(call.getFloat("left") ?? 0.0)
        let bottom = CGFloat(call.getFloat("bottom") ?? 0.0)
        let right = CGFloat(call.getFloat("right") ?? 0.0)
        let mapInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)

        DispatchQueue.main.async {
            self.mapViewController.GMapView.padding = mapInsets
        }

        call.success([
            "padding" : true
        ])
    }

    @objc func clear(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.mapViewController.GMapView.clear()
        }

        call.success([
            "mapViewCleared" : true
        ])
    }

    @objc func close(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if self.mapViewController != nil {
                self.mapViewController.view = nil
            }
        }

        call.success([
            "mapViewClosed" : true
        ])
    }

    @objc func show(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
           if self.mapViewController != nil {
                self.mapViewController.view.isHidden = false

                call.resolve([
                    "mapViewHidden" : false
                ])
           }
        }
    }

    @objc func hide(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
           if self.mapViewController != nil {
                self.mapViewController.view.isHidden = true

                call.resolve([
                    "mapViewHidden" : true
                ])
           }
        }
    }

    @objc func reverseGeocodeCoordinate(_ call: CAPPluginCall) {

        let latitude = call.getDouble("latitude") ?? 0
        let longitude = call.getDouble("longitude") ?? 0

        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        DispatchQueue.main.async {

            GMSGeocoder().reverseGeocodeCoordinate(coordinates) { (response, error) in
                var addressList: Array<Any> = []
                for address in response?.results() ?? [] {
                    let addr = [
                        "administrativeArea": address.administrativeArea ?? "",
                        "lines": address.lines!,
                        "country": address.country ?? "",
                        "locality": address.locality ?? "",
                        "postalCode": address.postalCode ?? "",
                        "subLocality": address.subLocality ?? "",
                        "thoroughFare": address.thoroughfare ?? ""
                    ] as [String : Any]
                    addressList.append(addr)
                }

                call.resolve([
                    "addresses": addressList
                ])
            }
        }
    }

    @objc func settings(_ call: CAPPluginCall) {

        let allowScrollGesturesDuringRotateOrZoom = call.getBool("allowScrollGesturesDuringRotateOrZoom") ?? true
        let compassButton = call.getBool("compassButton") ?? false
        let consumesGesturesInView = call.getBool("consumesGesturesInView") ?? true
        let indoorPicker = call.getBool("indoorPicker") ?? false
        let myLocationButton = call.getBool("myLocationButton") ?? false
        let rotateGestures = call.getBool("rotateGestures") ?? true
        let scrollGestures = call.getBool("scrollGestures") ?? true
        let tiltGestures = call.getBool("tiltGestures") ?? true
        let zoomGestures = call.getBool("zoomGestures") ?? true


        DispatchQueue.main.async {
            self.mapViewController.GMapView.settings.allowScrollGesturesDuringRotateOrZoom = allowScrollGesturesDuringRotateOrZoom
            self.mapViewController.GMapView.settings.compassButton = compassButton
            self.mapViewController.GMapView.settings.consumesGesturesInView = consumesGesturesInView
            self.mapViewController.GMapView.settings.indoorPicker = indoorPicker
            self.mapViewController.GMapView.settings.myLocationButton = myLocationButton
            self.mapViewController.GMapView.settings.rotateGestures = rotateGestures
            self.mapViewController.GMapView.settings.scrollGestures = scrollGestures
            self.mapViewController.GMapView.settings.tiltGestures = tiltGestures
            self.mapViewController.GMapView.settings.zoomGestures = zoomGestures

            call.resolve([
                "settingsApplied": true
            ])
        }
    }

    @objc func setCamera(_ call: CAPPluginCall) {

        let viewingAngle = call.getDouble("viewingAngle") ?? 45
        let bearing = call.getDouble("bearing") ?? 270
        let zoom = call.getFloat("zoom") ?? 1
        let latitude = call.getDouble("latitude") ?? 0
        let longitude = call.getDouble("longitude") ?? 0

        let animate = call.getBool("animate") ?? false
        let animationDuration = call.getDouble("animationDuration") ?? 1000

        DispatchQueue.main.async {
            let camera = GMSCameraPosition(latitude: latitude, longitude: longitude, zoom: zoom, bearing: bearing, viewingAngle: viewingAngle)

            if animationDuration != 0 && animate {
                /* FIXME: Use animation duration */
                self.mapViewController.GMapView.animate(to: camera)
            } else {
                self.mapViewController.GMapView.camera = camera
            }
        }

        call.success([
            "cameraSet": true
        ])
    }

    @objc func setMapStyle(_ call: CAPPluginCall) {
        let styleJsonString = call.getString("jsonString") ?? ""

        DispatchQueue.main.async {
            do {
                self.mapViewController.GMapView.mapStyle = try GMSMapStyle(jsonString: styleJsonString)
                call.success([
                    "stylesApplied": true
                ])
            } catch {
                call.error("One or more of the map styles failed to load. \(error)")
            }

        }
    }

    @objc func addPolyline(_ call: CAPPluginCall) {

        let points = call.getArray("points", AnyObject.self)

        DispatchQueue.main.async {

            let path = GMSMutablePath()

            for point in points ?? [] {
                let coords = CLLocationCoordinate2D(latitude: point["latitude"] as! CLLocationDegrees, longitude: point["longitude"] as! CLLocationDegrees)
                path.add(coords)
            }

            let polyline = GMSPolyline(path: path)

            polyline.map = self.mapViewController.GMapView
            call.resolve([
                "created": true
    }

    @objc func addPolygon(_ call: CAPPluginCall) {

        let points = call.getArray("points", AnyObject.self)

        DispatchQueue.main.async {

            let path = GMSMutablePath()

            for point in points ?? [] {
                let coords = CLLocationCoordinate2D(latitude: point["latitude"] as! CLLocationDegrees, longitude: point["longitude"] as! CLLocationDegrees)
                path.add(coords)
            }

            let polygon = GMSPolygon(path: path)
            polygon.map = self.mapViewController.GMapView

            call.resolve([
                "created": true
            ])
        }
    }

    @objc func addCircle(_ call: CAPPluginCall) {

        let radius = call.getDouble("radius") ?? 0.0

        let center = call.getObject("center")

        let coordinates = CLLocationCoordinate2D(latitude: center?["latitude"] as! CLLocationDegrees, longitude: center?["longitude"] as! CLLocationDegrees)

        DispatchQueue.main.async {

            let circleCenter = coordinates
            let circle = GMSCircle(position: circleCenter, radius: radius)
            circle.map = self.mapViewController.GMapView

            call.resolve([
                "created": true
            ])
        }
    }

    @objc func scrollTo(_ call: CAPPluginCall) {
        let x = call.getDouble("x") ?? 0
        let y = call.getDouble("y") ?? 0
        DispatchQueue.main.async {
            /*
             FIXME: crashes
             self.scrollMapView.scrollView.contentOffset = CGRect(x, y)
            */

            call.success([
                "scroll": true
            ])
        }
    }

    public func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
        self.notifyListeners("didTapPOIWithPlaceID", data: [
            "results": [
                "name": name,
                "placeID": placeID,
                "location": [
                    "latitude": location.latitude,
                    "longitude": location.longitude
                ]
            ]
        ])
    }


    public func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        self.notifyListeners("didLongPressAt", data: ["result": [
            "coordinates": [
                "latitude": coordinate.latitude,
                "longitude": coordinate.longitude
            ]
        ]])
    }

    public func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        self.notifyListeners("didTapInfoWindowOf", data: ["result": [
            "coordinates": [
                "latitude": marker.position.latitude,
                "longitude": marker.position.longitude
            ]
        ]])
    }

    public func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
        self.notifyListeners("didLongPressInfoWindowOf", data: ["result": [
            "coordinates": [
                "latitude": marker.position.latitude,
                "longitude": marker.position.longitude
            ]
        ]])
    }

    public func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
        self.notifyListeners("didCloseInfoWindowOf", data: ["result": [
            "coordinates": [
                "latitude": marker.position.latitude,
                "longitude": marker.position.longitude
            ]
        ]])
    }

    public func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        self.notifyListeners("didTap", data: ["result": [
            "coordinates": [
                "latitude": marker.position.latitude,
                "longitude": marker.position.longitude
            ]
        ]])
        return false
    }

    public func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        self.notifyListeners("didBeginDragging", data: ["result": [
            "coordinates": [
                "latitude": marker.position.latitude,
                "longitude": marker.position.longitude
            ]
        ]])
    }

    public func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        self.notifyListeners("didEndDragging", data: ["result": [
            "coordinates": [
                "latitude": marker.position.latitude,
                "longitude": marker.position.longitude
            ]
        ]])
    }

    public func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        self.notifyListeners("idleAt", data: ["result": [
            "position": [
                "latitude": position.target.latitude,
                "longitude": position.target.longitude
            ],
            "zoom": position.zoom,
        ]])
    }


    public func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        self.notifyListeners("didTapMyLocationButton", data: ["value": true])
        /*
            TODO: Add animation to user's current location
        */
        return false
    }

    public func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.notifyListeners("didTapAt", data: ["result": [
                "coordinates": [
                    "latitude": coordinate.latitude,
                    "longitude": coordinate.longitude
                ]
            ]])
    }

    public func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        self.notifyListeners("didChange", data: ["result": [
                "position": [
                    "latitude": position.target.latitude,
                    "longitude": position.target.longitude
                ],
                "zoom": position.zoom,
            ]])
    }

    public func mapViewSnapshotReady(_ mapView: GMSMapView) {
        self.notifyListeners("onMapReady", data: nil)
    }

    // Street View
    @objc func createStreetView(_ call: CAPPluginCall) {

        DispatchQueue.main.async {
            self.streetViewController = GMStreetViewController();
            self.streetViewController.mapViewBounds = [
                "width": call.getDouble("width") ?? 0,
                "height": call.getDouble("height") ?? 0,
                "x": call.getDouble("x") ?? 0,
                "y": call.getDouble("y") ?? 0,
            ]
            self.mapViewController.cameraPosition = [
                "heading": call.getDouble("heading") ?? 180,
                "pitch": call.getDouble("pitch") ?? -10,
                "zoom": call.getDouble("zoom") ?? Double(self.DEFAULT_ZOOM)
            ]
            self.bridge.viewController.view.addSubview(self.streetViewController.view)
            self.streetViewController.GMapStreetView.delegate = self
        }
        call.success([
            "created": true
        ])
    }

    @objc func moveNearCoordinate(_ call: CAPPluginCall) {
        let latitude = call.getDouble("latitude") ?? 0
        let longitude = call.getDouble("longitude") ?? 0

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        let radius = UInt(call.getInt("radius") ?? 0)

        DispatchQueue.main.async {
            self.streetViewController.GMapStreetView.moveNearCoordinate(coordinate, radius: (radius))
        }

        call.success([
            "movedNearCoordinates": true
        ])
    }

    @objc func setStreetViewCamera(_ call: CAPPluginCall) {
        let heading = call.getDouble("heading") ?? 180
        let pitch = call.getDouble("pitch") ?? -10
        let zoom = call.getFloat("zoom") ?? 1

        let animationDuration = call.getDouble("animationDuration") ?? 0

        let camera = GMSPanoramaCamera(heading: heading, pitch: pitch, zoom: zoom)

        DispatchQueue.main.async {
            if animationDuration != 0 {
                self.streetViewController.GMapStreetView.animate(to: camera, animationDuration: animationDuration)
            } else {
                self.streetViewController.GMapStreetView.camera = camera
            }
        }

        call.success([
            "cameraSet": true
        ])
    }

    @objc func addStreetViewMarker(_ call: CAPPluginCall) {
        let latitude = call.getDouble("latitude") ?? 0
        let longitude = call.getDouble("longitude") ?? 0

        DispatchQueue.main.async {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            marker.title = call.getString("markerTitle") ?? ""
            marker.snippet = call.getString("markerSnippet") ?? ""
            marker.panoramaView = self.streetViewController.GMapStreetView
        }

        call.success([
            "markerAdded": true
        ])
    }

}

class ScrollMapView: UIScrollView {
    // Source https://stackoverflow.com/a/4010809/5056792
    // Thanks to the author: https://stackoverflow.com/users/479543/john-stephen
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}

class GMViewController: UIViewController {

    var mapViewBounds: [String : Double]!
    var GMapView: GMSMapView!
    var cameraPosition: [String: Double]!

    var DEFAULT_ZOOM: Float = 12

    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.camera(withLatitude: cameraPosition["latitude"] ?? 0, longitude: cameraPosition["longitude"] ?? 0, zoom: Float(cameraPosition["zoom"] ?? Double(DEFAULT_ZOOM)))
        let frame = CGRect(x: mapViewBounds["x"] ?? 0, y: mapViewBounds["y"]!, width: mapViewBounds["width"] ?? 0, height: mapViewBounds["height"] ?? 0)
        self.GMapView = GMSMapView.map(withFrame: frame, camera: camera)
        self.view = GMapView
    }
}

class GMStreetViewController: UIViewController {

    var mapViewBounds: [String : Double]!
    var GMapStreetView: GMSPanoramaView!
    var cameraPosition: [String: Double]!

    var DEFAULT_HEADING: Double = 180
    var DEFAULT_PITCH: Double = -10
    var DEFAULT_ZOOM: Double = 12

    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSPanoramaCamera(
            heading: cameraPosition["heading"] ?? (DEFAULT_HEADING),
            pitch: cameraPosition["pitch"] ?? (DEFAULT_PITCH),
            zoom: Float(cameraPosition["zoom"] ?? (DEFAULT_ZOOM)))
        let frame = CGRect(x: mapViewBounds["x"] ?? 0, y: mapViewBounds["y"]!, width: mapViewBounds["width"] ?? 0, height: mapViewBounds["height"] ?? 0)
        self.GMapStreetView = GMSPanoramaView(frame: frame)
        self.GMapStreetView.camera = camera
        self.view = self.GMapStreetView
    }
}
