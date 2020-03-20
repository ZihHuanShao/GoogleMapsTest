//
//  ViewController.swift
//  googleMapsTest
//
//  Created by maxkitmac on 2020/3/17.
//  Copyright © 2020年 fredshao. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import GooglePlaces

struct Location {
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
}

enum DragType: Int {
    case dragWithFinishDrawing   = 0
    case dragWithKeepDrawing     = 1
    case dragNotFinishDrawingYet = 2
}

class ViewController: UIViewController {
    
    // MAEK: - Properties
    
    // 測試軌跡
    var testTracks = [
        Location(latitude: 24.165335, longitude: 120.661776), // 公司
        Location(latitude: 24.164990, longitude: 120.661452),
        Location(latitude: 24.164589, longitude: 120.660695),
        Location(latitude: 24.164552, longitude: 120.659171),
        Location(latitude: 24.164954, longitude: 120.657680),
        Location(latitude: 24.166520, longitude: 120.652608),
        Location(latitude: 24.165967, longitude: 120.652050),
        Location(latitude: 24.166755, longitude: 120.650382),
        Location(latitude: 24.167166, longitude: 120.650452),
        Location(latitude: 24.168761, longitude: 120.648773)
    ]
    
    var myLocationMgr: CLLocationManager!
    
    var path: GMSMutablePath!
    
    var preButtonPressed = UIButton()
    
    var testPointFlag = false
    
    var currentCooridinate: CLLocationCoordinate2D?
    
    var isDrag: DragType!
    
    var showTrackFlag = false
    
    let googleMgr = GoogleMapsManager.shareInstance
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var mapView: GMSMapView!

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        /*
        // 調整 camera 讓 polyline 的能見度完整顯示在 MapView 上
        var bounds: GMSCoordinateBounds = GMSCoordinateBounds()
        for index in 0 ..< path.count() {
            bounds = bounds.includingCoordinate(path.coordinate(at: index))
        }
        self.mapView.animate(with: GMSCameraUpdate.fit(bounds))
        */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        myLocationMgr.stopUpdatingLocation()
    }
    
    // MARK: - IBActions
    
    @IBAction func selectNumOfPolygonButtonPressed(_ sender: UIButton) {
        
        resetDrawingButtonPressed(UIButton())
        
        switch sender.tag {
        case 3:
            googleMgr.setNumOfPolygon(num: 3)
            
        case 4:
            googleMgr.setNumOfPolygon(num: 4)
            
        case 5:
            googleMgr.setNumOfPolygon(num: 5)
            
        case 6:
            googleMgr.setNumOfPolygon(num: 6)
            
        default:
            break
        }
        
        sender.backgroundColor = .red
        preButtonPressed = sender
    }
    
    @IBAction func newTestPoint(_ sender: UIButton) {
        googleMgr.removeTestPointMark()
        testPointFlag = true
    }
    
    @IBAction func resetDrawingButtonPressed(_ sender: Any) {
        googleMgr.resetMap(mapView: mapView)
        preButtonPressed.backgroundColor = .orange
        testPointFlag = false
    }
    
    @IBAction func showTrackButtonPressed(_ sender: UIButton) {
        if !showTrackFlag {
            let locations = testTracks.map {
                (location: Location) -> CLLocationCoordinate2D in
                return CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
            }
            googleMgr.newPoints(coordinates: locations, forTrack: mapView)
            showTrackFlag = true
        } else {
            googleMgr.resetDrawingTrack()
            googleMgr.removeTrackMarks()
            googleMgr.removeTrack()
            showTrackFlag = false
        }
    }
}

// MARK: - Private Functions

extension ViewController {
    private func updateDataSource() {
        myLocationMgr = CLLocationManager()
        myLocationMgr.delegate = self
        myLocationMgr.distanceFilter = kCLLocationAccuracyBestForNavigation
        myLocationMgr.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        mapView.delegate = self
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "是否有在區域內？", message: message, preferredStyle: .alert)
   
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(UIAlertAction) -> Void in
            self.testPointFlag = false
        })
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func testPoint(cooridinate: CLLocationCoordinate2D) {
        googleMgr.newTestPoint(coordinate: cooridinate, mapView: mapView)
        testPointFlag = false
        
        // 若測試點與頂點為同一點, 則算在多邊形內
        // 檢查該點是否又在多邊形內
        if googleMgr.checkIsInPolygon(coordinate: cooridinate) {
            showAlert(message: "是")
        } else {
            showAlert(message: "否")
        }
    }
}

// MARK: - GMSMapViewDelegate

extension ViewController: GMSMapViewDelegate {
    
    // 長按
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        let newCoordinate = coordinate
        currentCooridinate = newCoordinate
        
        print("[didLongPressAt]: \(coordinate)")
        
        if testPointFlag {
            print("[Test Point] lat: \(newCoordinate.latitude), lng: \(newCoordinate.longitude)")
            testPoint(cooridinate: newCoordinate)
        }
        
        // 多邊形已畫完
        if googleMgr.checkFinishDrawing() {
            currentCooridinate = nil
            isDrag = .dragWithFinishDrawing
        }
        // 多邊形未畫完
        else {
            // 拖曳
            if isDrag == .dragNotFinishDrawingYet {
                isDrag = .dragWithKeepDrawing
            }
            // 非拖曳(建立新點)
            else {
                print("[New Point] lat: \(newCoordinate.latitude), lng: \(newCoordinate.longitude)")
                googleMgr.newPoint(coordinate: newCoordinate, forPolygon: mapView)
            }
        }
    }
    
    // NOTE: 偵測「拖曳」與「長按」的function call有不同的順序, 因此另外使用DragType來判斷拖曳點的狀態
    // 1. didBeginDragging -> didLongPressAt -> didDrag -> didEndDragging
    // 2. didBeginDragging -> didDrag -> didEndDragging
    
    // 開始拖曳
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        print("[didBeginDragging]: \(marker.position)")
        
        // 多邊形已畫完
        if googleMgr.checkFinishDrawing() {
            
        }
        // 多邊形未畫完, currentCooridinate一定有值, 再來判斷現在是拖曳哪個頂點, 然後在didDrag更新現在移動的位置
        else {
            if let _currentCooridinate = currentCooridinate {
                if (_currentCooridinate.latitude == marker.position.latitude &&
                    _currentCooridinate.longitude == marker.position.longitude) {
                    isDrag = .dragNotFinishDrawingYet
                }
            }
        }
    }
    
    // 拖曳中
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        //print("[didDrag]: \(marker.position)")
        
        // 多邊形已畫完
        if googleMgr.checkFinishDrawing() {
            googleMgr.modifyPoint(newMarker: marker, mapView: mapView)
        }
        // 多邊形未畫完
        else {
            if isDrag == .dragNotFinishDrawingYet || isDrag == .dragWithKeepDrawing {
                googleMgr.modifyPoint(newMarker: marker, whenNotFinishDrawingYet: mapView)
            }
        }
    }
    
    // 結束拖曳
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        print("[didEndDragging]: \(marker.position)")
        
        if googleMgr.checkFinishDrawing() {
            isDrag = .dragWithFinishDrawing
        } else {
            isDrag = .dragNotFinishDrawingYet
        }
        //mapView.reloadInputViews()
    }
}

// MARK: - CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       
        switch status {
        // 第一次啟用APP
        case .notDetermined:
            myLocationMgr.requestWhenInUseAuthorization()
            
        case .denied:
            let alertController = UIAlertController(title: "定位權限已關閉", message:"如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default, handler:nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        
        case .authorizedWhenInUse:
            myLocationMgr.startUpdatingLocation()
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
            
        default:
            break
        }
    }
    
    // 所在位置只要有更動就會觸發
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 印出目前所在位置座標
        let currentLocation: CLLocation = locations[0] as CLLocation
        print("[Current Location]: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
        
        if let location = locations.first {
            let lat = location.coordinate.latitude
            let lng = location.coordinate.longitude
            let myPos = GMSCameraPosition.camera(withLatitude: lat, longitude: lng, zoom: 15)
            mapView.animate(to: myPos)
            
//            let newLat = lat + 0.5
//            let marker = GMSMarker()
//            
//            marker.position = CLLocationCoordinate2D(latitude: newLat, longitude: lng)
//            marker.isDraggable = true
//            marker.title = "TEST"
//            marker.snippet = ""
//            marker.map = mapView

            // 避免自己位置一有變動, 畫面就強制移到定位點
            myLocationMgr.stopUpdatingLocation()
        }
    }
}
