//
//  PhotoContentView.swift
//  AnyImageEditor
//
//  Created by 蒋惠 on 2019/10/24.
//  Copyright © 2019 AnyImageProject.org. All rights reserved.
//

import UIKit

protocol PhotoContentViewDelegate: class {
    
    func photoDidBeginPen()
    func photoDidEndPen()
    
    func mosaicDidCreated()
}

final class PhotoContentView: UIView {

    weak var delegate: PhotoContentViewDelegate?
    
    private(set) lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.clipsToBounds = false
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.maximumZoomScale = 3.0 // 15.0
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        return view
    }()
    private(set) lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        return view
    }()
    /// 画板 - pen
    private(set) lazy var canvas: Canvas = {
        let view = Canvas()
        view.delegate = self
        view.dataSource = self
        view.isUserInteractionEnabled = false
        return view
    }()
    /// 马赛克，延时加载
    internal var mosaic: Mosaic?
    /// 裁剪 - Crop
    private let cornerFrame = CGRect(x: 0, y: 0, width: 40, height: 40)
    private(set) lazy var topLeftCorner: CropCornerView = {
        let view = CropCornerView(frame: cornerFrame, color: .white, position: .topLeft)
        view.alpha = 0
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panCropCorner(_:))))
        return view
    }()
    private(set) lazy var topRightCorner: CropCornerView = {
        let view = CropCornerView(frame: cornerFrame, color: .white, position: .topRight)
        view.alpha = 0
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panCropCorner(_:))))
        return view
    }()
    private(set) lazy var bottomLeftCorner: CropCornerView = {
        let view = CropCornerView(frame: cornerFrame, color: .white, position: .bottomLeft)
        view.alpha = 0
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panCropCorner(_:))))
        return view
    }()
    private(set) lazy var bottomRightCorner: CropCornerView = {
        let view = CropCornerView(frame: cornerFrame, color: .white, position: .bottomRight)
        view.alpha = 0
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panCropCorner(_:))))
        return view
    }()
    private(set) lazy var gridView: CropGridView = {
        let view = CropGridView(frame: UIScreen.main.bounds)
        view.alpha = 0
        return view
    }()
    private(set) lazy var cropLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = bounds
        layer.fillRule = .evenOdd
        layer.fillColor = UIColor.black.cgColor
        return layer
    }()
    
    
    internal let image: UIImage
    internal let config: ImageEditorController.PhotoConfig
    
    internal var isCrop: Bool = false
    internal var didCrop: Bool = false
    internal var cropRect: CGRect = .zero
    internal var cropStartPanRect: CGRect = .zero
    internal var lastCropData: CropData = CropData()
    
    /// 存储马赛克过程图片 // TODO: 改成磁盘存储
    internal var mosaicImageList: [UIImage] = []
    
    init(frame: CGRect, image: UIImage, config: ImageEditorController.PhotoConfig) {
        self.image = image
        self.config = config
        super.init(frame: frame)
        backgroundColor = .black
        setupView()
        setupMosaicView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        imageView.addSubview(canvas)
        layout()
        cropSetupView()
    }
    
    internal func layout() {
        scrollView.frame = bounds
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        scrollView.zoomScale = 1.0
        scrollView.contentInset = .zero
        imageView.frame = fitFrame
        scrollView.contentSize = imageView.bounds.size
        canvas.frame = CGRect(origin: .zero, size: imageView.bounds.size)
    }
}

// MARK: - UIScrollViewDelegate
extension PhotoContentView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if !isCrop && !didCrop {
            imageView.center = centerOfContentSize
        }
    }
}
