import UIKit
import PhotosUI
import Photos
import ParseSwift
import CoreLocation

class PostViewController: UIViewController, CLLocationManagerDelegate {

    // MARK: Outlets
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!

    private var pickedImage: UIImage?
    private var currentLocation: CLLocation?
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder() // Added CLGeocoder

    override func viewDidLoad() {
        super.viewDidLoad()

        // Request location access for camera photos
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Actions

    @IBAction func onTakePhotoTapped(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("❌📷 Camera not available")
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    @IBAction func onPickedImageTapped(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func onShareTapped(_ sender: Any) {
        view.endEditing(true)

        guard let image = pickedImage,
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            showAlert(description: "Please select an image before sharing.")
            return
        }

        // Create a new post object as a variable to allow modifications
        var post = Post()
        post.imageFile = ParseFile(name: "image.jpg", data: imageData)
        post.caption = captionTextField.text
        post.user = User.current

        // Add the current location to the post (if available)
        if let location = currentLocation {
            reverseGeocode(location: location) { [weak self] city in
                post.location = city ?? "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                self?.setPostACLAndSave(post)
            }
        } else {
            post.location = "Location unavailable"
            setPostACLAndSave(post)
        }
    }

    private func setPostACLAndSave(_ post: Post) {
        var mutablePost = post // Reassign the post to a mutable var to modify its properties
        mutablePost.ACL = ParseACL()
        mutablePost.ACL?.publicRead = true
        mutablePost.ACL?.publicWrite = true

        savePost(mutablePost)
    }

    private func savePost(_ post: Post) {
        post.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    print("✅ Post Saved! \(post)")
                    self?.updateCurrentUser()

                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }


    private func updateCurrentUser() {
        guard var currentUser = User.current else { return }
        currentUser.lastPostedDate = Date()
        currentUser.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    print("✅ User Saved! \(user)")
                    self?.navigationController?.popViewController(animated: true)

                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func onViewTapped(_ sender: Any) {
        view.endEditing(true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    // MARK: - Reverse Geocoding
    private func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let placemark = placemarks?.first {
                // Get the city or locality from the placemark
                let city = placemark.locality
                print("City found: \(city ?? "Unknown location")")
                completion(city)
            } else {
                completion(nil)
            }
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        if let assetIdentifier = results.first?.assetIdentifier {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
            
            if let asset = fetchResult.firstObject {
                print("Asset fetched: \(asset)")
                if let location = asset.location {
                    print("Location found: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    // Store the location for the post
                    self.currentLocation = location
                } else {
                    print("No location data available for this image.")
                }
            } else {
                print("No asset found with identifier: \(assetIdentifier)")
            }
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let error = error {
                self?.showAlert(description: error.localizedDescription)
                return
            }

            guard let image = object as? UIImage else {
                self?.showAlert()
                return
            }

            DispatchQueue.main.async {
                self?.previewImageView.image = image
                self?.pickedImage = image
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            showAlert(description: "Failed to retrieve the edited image.")
            return
        }

        previewImageView.image = image
        pickedImage = image

        // If we have the current location, use it
        if let location = currentLocation {
            print("Photo taken at location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
}
