//
//  ViewController.swift
//  QRCodeScanner
//
//  Created by Павел Скуковский on 10.10.2024.
//
import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // Свойства для работы с камерой
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?

    @IBOutlet weak var previewView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Проверка статуса разрешений
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Если разрешение уже предоставлено
            setupCamera()
            
        case .notDetermined:
            // Если разрешение не запрашивалось
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        // Если доступ предоставлен, настраиваем камеру
                        self.setupCamera()
                    }
                }
                else {
                    print("Доступ к камере был отклонен.")
                }
            }
            
        case .denied, .restricted:
            // Если доступ был ранее запрещен
            print("Доступ к камере был отклонен или ограничен.")
            
        @unknown default:
            break
        }
    }
    
    // настройки камеры
    func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("Не удалось получить доступ к камере.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)

            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)

            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [.qr]
        }
        
        catch {
            print("Ошибка при настройке камеры: \(error)")
            return
        }

        // Настройка слоя для отображения видео
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = previewView.layer.bounds
        previewView.layer.addSublayer(videoPreviewLayer!)

        // Запуск камеры
        captureSession.startRunning()

        // Настройка рамки для QR-кода
        qrCodeFrameView = UIView()
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            previewView.addSubview(qrCodeFrameView)
            previewView.bringSubviewToFront(qrCodeFrameView)
        }
    }
    
    // Метод делегата для обработки найденных QR-кодов
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Проверка на наличие метаданных
        if metadataObjects.isEmpty {
            qrCodeFrameView?.frame = CGRect.zero
            print("QR-код не найден")
            return
        }

        // Получение метаданных
        if let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            if metadataObj.type == .qr {
                // Если найден QR-код, выделим его рамкой
                let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
                qrCodeFrameView?.frame = barCodeObject!.bounds
                
                // Если содержимое QR-кода не пустое, обрабатываем его
                if let qrCodeString = metadataObj.stringValue {
                    print("Найден QR-код: \(qrCodeString)")
                    
                    // Проверим, является ли содержимое QR-кода URL-адресом
                    if let url = URL(string: qrCodeString), UIApplication.shared.canOpenURL(url) {
                        // Откроем URL в Safari
                        UIApplication.shared.open(url)
                    }
                    
                    else {
                        // Если это не URL, выведем содержимое в алерт
                        let alert = UIAlertController(title: "QR-код", message: qrCodeString, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
