//
//  MemeEditorViewController.swift
//  MemeMev1.0
//
//  Created by Abhijit Apte on 12/03/21.
//

import UIKit

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
	
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
	
	func setDefaultSpecificationsFor(_ textField: UITextField, withDefaultValue: String) {
		
		let memeTextAttributes: [NSAttributedString.Key: Any] = [
			NSAttributedString.Key.strokeColor: UIColor.black,
			NSAttributedString.Key.foregroundColor: UIColor.white,
			NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
			NSAttributedString.Key.strokeWidth:  -2.0
		]
		
		textField.defaultTextAttributes = memeTextAttributes
		textField.textAlignment = .center
		
		textField.text = withDefaultValue
		
		textField.delegate = self
	}
	
	func setDefaults() {
		memedImage = nil
		imageView.image = nil
		imageView.contentMode = .scaleAspectFit

		shareButton.isEnabled = false

		setDefaultSpecificationsFor(topText, withDefaultValue: DefaultText.top.rawValue.uppercased())
		setDefaultSpecificationsFor(bottomText, withDefaultValue: DefaultText.bottom.rawValue.uppercased())
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
	}
	
	func setToolbarVisibility(hide flag: Bool) {
		self.navigationController?.setNavigationBarHidden(flag, animated: false)
		self.navigationController?.setToolbarHidden(flag, animated: false)
	}
		
	func generateMemedImage() -> UIImage {

		setToolbarVisibility(hide: true)

		// Render view to an image
		UIGraphicsBeginImageContext(self.view.frame.size)
		view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
		let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		
		setToolbarVisibility(hide: true)
		
		return memedImage
	}
	
	func setupToolbar() {
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
	
	func pickImageFromSource(_ sourceType: UIImagePickerController.SourceType) {
		let imagePickerVC = UIImagePickerController()
		imagePickerVC.delegate = self
		imagePickerVC.sourceType = sourceType
		present(imagePickerVC, animated: true, completion: nil)
	}
	
	// MARK: View controller methods
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		
		// Programmatically setup a toolbar
		setupToolbar()
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
	
	// MARK: UITextFieldDelegate protocol methods
	
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
	
	// MARK: Meme core logic
	@objc func pickAnImageFromCamera(_ sender: Any) {
		pickImageFromSource(.camera)
	}
	
	@objc func pickAnImageFromAlbum(_ sender: Any) {
		pickImageFromSource(.photoLibrary)
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
	
	@IBAction func shareMeme(_ sender: Any) {
		let memedImage = generateMemedImage()
		self.memedImage = memedImage
		let activityController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
		activityController.completionWithItemsHandler = { (_, completed, _, _) in
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
	
	// MARK: Keyboard handling
	
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
}

