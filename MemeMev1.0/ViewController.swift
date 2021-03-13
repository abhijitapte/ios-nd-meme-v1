//
//  ViewController.swift
//  MemeMev1.0
//
//  Created by Abhijit Apte on 12/03/21.
//

import UIKit

struct Meme {
	var topText: String
	var bottomText: String
	var originalImage: UIImage
	var memedImage: UIImage
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
	
	// MARK: Outlets
	
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var topText: UITextField!
	@IBOutlet weak var bottomText: UITextField!
	@IBOutlet weak var shareButton: UIBarButtonItem!
	
	// MARK: Model
	var memedImage: UIImage!
	var memeModel: Meme?
	
	enum DefaultText: String {
		case top
		case bottom
	}
	
	// MARK: Utility Methods
	func setDefaults() {
		memedImage = nil
		imageView.image = nil
		
		shareButton.isEnabled = false
//		topText.placeholder = "TOP"
		topText.text = DefaultText.top.rawValue.uppercased()
		
//		bottomText.placeholder = "BOTTOM"
		bottomText.text = DefaultText.bottom.rawValue.uppercased()
		
		let memeTextAttributes: [NSAttributedString.Key: Any] = [
			NSAttributedString.Key.strokeColor: UIColor.black,
			NSAttributedString.Key.foregroundColor: UIColor.white,
			NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
			NSAttributedString.Key.strokeWidth:  -2.0
		]
		
		topText.defaultTextAttributes = memeTextAttributes
		bottomText.defaultTextAttributes = memeTextAttributes
		
		topText.textAlignment = .center
		bottomText.textAlignment = .center
		
		imageView.contentMode = .scaleAspectFit
		
	}
	
	func getKeyboardHeight(_ notification:Notification) -> CGFloat {

		let userInfo = notification.userInfo
		let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
		return keyboardSize.cgRectValue.height
	}
	
	func save() {
		// Create the meme
		let meme = Meme(topText: topText.text!, bottomText: bottomText.text!, originalImage: imageView.image!, memedImage: memedImage)
		self.memeModel = meme
		// debug
//		UIImageWriteToSavedPhotosAlbum(memedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
	}
	
	
	// debug image
//	MARK: - Add image to Library
//	@objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//		if let error = error {
//			// we got back an error!
//			let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
//			ac.addAction(UIAlertAction(title: "OK", style: .default))
//			present(ac, animated: true)
//		} else {
//			let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
//			ac.addAction(UIAlertAction(title: "OK", style: .default))
//			present(ac, animated: true)
//		}
//	}
	
	func generateMemedImage() -> UIImage {

		self.navigationController?.setNavigationBarHidden(true, animated: true)
		self.navigationController?.setToolbarHidden(true, animated: false)


		// Render view to an image
		UIGraphicsBeginImageContext(self.view.frame.size)
		view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
		let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()

		self.navigationController?.setNavigationBarHidden(true, animated: false)
		self.navigationController?.setToolbarHidden(false, animated: false)

		return memedImage
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		
		// Programmatically setup a toolbar
		var toolbarItems = [UIBarButtonItem]()
		
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
		let cameraButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(pickAnImageFromCamera(_:)))
		cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
		toolbarItems.append(cameraButton)
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
		toolbarItems.append(UIBarButtonItem(title: "Albums", style: .plain, target: self, action: #selector(pickAnImageFromAlbum(_:))))
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))

		self.setToolbarItems(toolbarItems, animated: true)
		self.navigationController?.isToolbarHidden = false
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setDefaults()
		subscribeToKeyboardNotifications()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		 super.viewWillDisappear(animated)
		 unsubscribeFromKeyboardNotifications()
	 }
	
	@objc func pickAnImageFromCamera(_ sender: Any) {
		let imagePickerVC = UIImagePickerController()
		imagePickerVC.delegate = self
		imagePickerVC.sourceType = .camera
		present(imagePickerVC, animated: true, completion: nil)
	}
	
	@objc func pickAnImageFromAlbum(_ sender: Any) {
		let imagePickerVC = UIImagePickerController()
		imagePickerVC.delegate = self
		imagePickerVC.sourceType = .photoLibrary
		present(imagePickerVC, animated: true, completion: nil)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let image = info[.originalImage] as? UIImage {
			imageView.image = image
			shareButton.isEnabled = true
		}
		dismiss(animated: true, completion: nil)
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		let oldText = textField.text!
		if textField == topText && oldText == DefaultText.top.rawValue.uppercased() {
			textField.text = ""
		} else if textField == bottomText && oldText == DefaultText.bottom.rawValue.uppercased() {
			textField.text = ""
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	func subscribeToKeyboardNotifications() {

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

	}

	func unsubscribeFromKeyboardNotifications() {

		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	@objc func keyboardWillShow(_ notification:Notification) {
				
		if bottomText.isEditing {
			view.frame.origin.y -= getKeyboardHeight(notification)
		}

	}
	
	@objc func keyboardWillHide(_ notification:Notification) {
		if bottomText.isEditing {
			view.frame.origin.y = 0
		}
	}
	
	@IBAction func shareMeme(_ sender: Any) {
		let memedImage = generateMemedImage()
		self.memedImage = memedImage
		let activityController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
		activityController.completionWithItemsHandler = { (activity, completed, items, error) in
			if (completed) {
				self.save()
			}
			self.dismiss(animated: true, completion: nil)
		}
		present(activityController, animated: true, completion: nil)
	}
	
	@IBAction func cancelCreateMeme(_ sender: Any) {
		setDefaults()
	}
}

