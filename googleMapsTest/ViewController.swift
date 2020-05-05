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
    case dragWithFinishDrawing       = 0 // 移動頂點 && 多邊形還已繪製完
    case dragWithoutFinishingDrawing = 1 // 移動頂點 && 多邊形還沒繪製完
    case dragWithKeepDrawing         = 2 // 建立新頂點
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
    
    // 向使用者取得定位權限
    var myLocationMgr: CLLocationManager!
    
    var path: GMSMutablePath!
    
    var preButtonPressed = UIButton()
    
    // 測試某點是否位於多邊形內
    var testPointFlag = false
    
    // 判斷是拖曳或是建立頂點
    var isDrag: DragType!
    
    // 是否完成此次繪製
    var isDone = false
    
    // 顯示既定軌跡
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

    
    @IBAction func drawButtonPressed(_ sender: UIButton) {
        resetDrawingButtonPressed(UIButton())
        
        googleMgr.startAddingVertex()
        
        sender.backgroundColor = .red
        preButtonPressed = sender
    }
    
    @IBAction func drawBackButtonPressed(_ sender: UIButton) {
        if !isDone {
            googleMgr.deletePreviousPonint(mapView: mapView)
        }
    }
    
    @IBAction func finishDrawingButtonPressed(_ sender: UIButton) {
        // 至少要畫三個點才能按完成, 若沒有則跳警告
        if !isDone {
            if googleMgr.finishAddingVertex(mapView: mapView) {
                preButtonPressed.backgroundColor = .orange
                isDone = true
            } else {
                showAlert(title: "請至少繪製三個點", message: "")
            }
        }
    }
    
    @IBAction func newTestPoint(_ sender: UIButton) {
        googleMgr.removeTestPointMark()
        testPointFlag = true
    }
    
    @IBAction func resetDrawingButtonPressed(_ sender: Any) {
        googleMgr.resetMap(mapView: mapView)
        preButtonPressed.backgroundColor = .orange
        testPointFlag = false
        showTrackFlag = false
        isDone = false
    }
    
    @IBAction func showTrackButtonPressed(_ sender: UIButton) {
        if !showTrackFlag {
            googleMgr.resetDrawingTrack()
            let locations = testTracks.map {
                (location: Location) -> CLLocationCoordinate2D in
                return CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
            }
            googleMgr.newPoints(coordinates: locations, forTrack: mapView)
            showTrackFlag = true
        } else {
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
        
        // 使用者移動多少距離後會更新座標點(單位為米)
        myLocationMgr.distanceFilter = kCLLocationAccuracyBestForNavigation
        
        // 定位的精確度
        myLocationMgr.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        /*
        // Ref: https://reurl.cc/qdVQzg
        // CLLocationDistance Type
        kCLLocationAccuracyBestForNavigation: 精確度最高，適用於導航的定位
        kCLLocationAccuracyBest: 精確度高
        kCLLocationAccuracyNearestTenMeters: 精確度 10 公尺以內
        kCLLocationAccuracyHundredMeters: 精確度 100 公尺以內
        kCLLocationAccuracyKilometer: 精確度 1 公里以內
        kCLLocationAccuracyThreeKilometers: 精確度 3 公里以內
        */
        
        mapView.delegate = self
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
   
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
            showAlert(title: "是否有在區域內？", message: "是")
        } else {
            showAlert(title: "是否有在區域內？", message: "否")
        }
    }
}

// MARK: - GMSMapViewDelegate

extension ViewController: GMSMapViewDelegate {
    
    // 長按
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        let newCoordinate = coordinate
        print("[didLongPressAt]: \(coordinate)")
        
        if testPointFlag {
            print("[Test Point] lat: \(newCoordinate.latitude), lng: \(newCoordinate.longitude)")
            testPoint(cooridinate: newCoordinate)
        }
        
        // 多邊形已畫完
        if googleMgr.checkFinishDrawing() {
            isDrag = .dragWithFinishDrawing
        }
        // 多邊形未畫完
        else {
            // 拖曳
            if isDrag == .dragWithoutFinishingDrawing {
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
        
        // 多邊形未畫完, isDrag設為dragNotFinishDrawingYet
        if !googleMgr.checkFinishDrawing() {
            isDrag = .dragWithoutFinishingDrawing
        }
    }
    
    // 拖曳中
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        print("[didDrag]: \(marker.position)")
        
        googleMgr.modifyPoint(newMarker: marker, mapView: mapView)
        
        /*---
        if googleMgr.checkFinishDrawing() {
            // 多邊形已畫完
        } else {
            // 多邊形未畫完
        }
        ---*/
        
    }
    
    // 結束拖曳
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        print("[didEndDragging]: \(marker.position)")
        
        if googleMgr.checkFinishDrawing() {
            isDrag = .dragWithFinishDrawing
        } else {
            isDrag = .dragWithoutFinishingDrawing
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
            myLocationMgr.startUpdatingLocation() // 將畫面移動到目前使用者的位置
            mapView.isMyLocationEnabled = true  // 開啟我的位置(小藍點)
            mapView.settings.myLocationButton = true // 開啟定位按鈕(右下角的圓點)
            
        default:
            break
        }
    }
    
    // 所在位置只要有更動就會觸發
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.first {
            let lat = location.coordinate.latitude
            let lng = location.coordinate.longitude
            
            // 印出目前所在位置座標
            print("[Current Location]: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            // 將視角切換至使用者當前的位置
            let myPos = GMSCameraPosition.camera(withLatitude: lat, longitude: lng, zoom: 15)
            mapView.animate(to: myPos)

            // 避免自己位置一有變動, 畫面就強制移到定位點
            myLocationMgr.stopUpdatingLocation()
        }
    }
}
