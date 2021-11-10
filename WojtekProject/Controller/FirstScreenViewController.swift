//
//  FirstScreenViewController.swift
//  WojtekProject
//
//  Created by Wojciech Kudrynski on 09/11/2021.
//

import UIKit

class FirstScreenViewController: UIViewController, SecondScreenViewControllerDelegate {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var surnameTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    public var savedUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        surnameTextField.delegate = self
        phoneNumberTextField.delegate = self
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipe(_:)))
        swipeGesture.direction = .left
        self.view.addGestureRecognizer(swipeGesture)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        let userToCreate = User(name: nameTextField.text,
                                surname: surnameTextField.text,
                                phoneNumber: phoneNumberTextField.text)
        if savedUser != userToCreate {
            savedUser = userToCreate
            let alert = UIAlertController(title: "User Details Saved!", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    @objc private func swipe(_ sender: UISwipeGestureRecognizer) {
        performSegue(withIdentifier: "ShowSecondScreen", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as? SecondScreenViewController
        vc?.delegate = self
    }
    
    func isPhoneNumberValid(value: String) -> Bool {
        let validRegex = "\\d{3}-\\d{3}-\\d{3}"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", validRegex)
        let result = phoneTest.evaluate(with: value)
        return result
    }
}

extension FirstScreenViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let nameCount = nameTextField.text?.count,
           let surnameCount = surnameTextField.text?.count,
           let phoneNumber = phoneNumberTextField.text,
           nameCount >= 2 && surnameCount >= 3 && isPhoneNumberValid(value: phoneNumber) {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField.restorationIdentifier == "phoneNumber" {
            if (range.location == 11) || (range.length == 0 && !string.first!.isNumber) {
                return false
            }
            
            if let text = textField.text,
               range.location == 3 || range.location == 7 {
                textField.text = "\(text)-"
            }
            
            if let text = textField.text,
               range.location == 4 || range.location == 8 {
                textField.text = String(text.dropLast())
            }
        }
        
        return true
    }
}
