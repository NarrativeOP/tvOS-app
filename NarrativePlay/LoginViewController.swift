import UIKit
import Alamofire

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        self.setupScreen()

        if Authorization.checkIfLoggedIn() == true {
            print("Already logged in")
            
        } else {
            print("No token found. Log in to continue.")
        }
    }
    
    // MARK: - Attributes
    
    // MARK: - Methods
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.text = ""
        
        if textField == self.inputPassword {
            self.inputAccessoryText.text = "Enter your password\n"
            inputPassword.secureTextEntry = true
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == self.inputPassword {
            
            var email: String = ""
            var password: String = ""
            
            guard self.inputPassword.text?.characters.count > 3 &&
                self.inputEmail.text?.containsString("@") == true else {
                    self.messageLabel.text = "Invalid username or password"
                    return
            }
            if let emailInput = inputEmail.text {
                email = emailInput
            }
            if let pwdInput = inputPassword.text {
                password = pwdInput
            }
            
            self.messageLabel.text = "Connecting to server..."
            self.getAuthToken(email, password: password)
        }
    }

    func continueToNarrativeApp() {
        // TODO: - Possibly add animation
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func getAuthToken(email: String, password: String) {
        print("Trying to grab token...")
        
        var statusCode: Int!
        
        Alamofire.request(.POST, AuthURL, parameters: ["grant_type":"password","client_id":"ios","email": email, "password":password])
            .responseJSON { response in
            statusCode = response.response?.statusCode

            switch statusCode {
            case 401:
                self.messageLabel.text = "Invalid username or password"
                return
            case 404:
                self.titleLabel.text = "Connection error"
                return
            case 200:
                if let JSON = response.result.value {
                    if let accessToken = JSON["access_token"] as? String {
                        Authorization.setAccessToken(accessToken)
                        self.continueToNarrativeApp()
                    }
                }
            default:
                return
            }
        }
    }

    // MARK: - Views
    
    // Title label
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 50, width: 1920, height: 200))
        titleLabel.textAlignment = .Center
        titleLabel.font = UIFont.avenirMediumWithSize(60.0)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.text = "Welcome!"
    
        return titleLabel
    }()
    
    // Message label
    lazy var messageLabel: UILabel = {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 150, width: 1920, height: 200))
        messageLabel.textAlignment = .Center
        messageLabel.font = UIFont.avenirMediumWithSize(40.0)
        messageLabel.textColor = UIColor.whiteColor()
        messageLabel.text = "Sign in to continue"
        
        return messageLabel
    }()
    
    // E-mail text field
    lazy var inputEmail: UITextField = {
        let inputEmail = UITextField(frame: CGRect(x: 960 - (300 / 2), y: 324, width: 300, height: 40))
        inputEmail.backgroundColor = UIColor.whiteColor()
        inputEmail.textAlignment = .Center
        inputEmail.font = UIFont.avenirMediumWithSize(20.0)
        inputEmail.keyboardAppearance = .Default
        inputEmail.keyboardType = .EmailAddress
        inputEmail.returnKeyType = .Done
        inputEmail.text = "E-mail"
        
        inputEmail.delegate = self
        
        return inputEmail
    }()
    
    // Password text field
    lazy var inputPassword: UITextField = {
        let inputPassword = UITextField(frame: CGRect(x: 960 - (300 / 2), y: 324 + 75, width: 300, height: 40))
        inputPassword.backgroundColor = UIColor.whiteColor()
        inputPassword.textAlignment = .Center
        inputPassword.font = UIFont.avenirMediumWithSize(20.0)
        inputPassword.keyboardAppearance = .Default
        inputPassword.keyboardType = .Default
        inputPassword.returnKeyType = .Done
        inputPassword.text = "Password"
        
        inputPassword.delegate = self
        
        return inputPassword
    }()
    
    // Login button
    lazy var loginButton: UIButton = {
        let loginButton = UIButton(type: .System)
        loginButton.frame = CGRect(x: 960 - (300 / 2), y: 324 + 150, width: 300, height: 40)
        loginButton.setTitle("Log in", forState: .Normal)
        loginButton.titleLabel?.font = UIFont.avenirMediumWithSize(20.0)
        loginButton.addTarget(self, action: "pressedLogIn:", forControlEvents: .AllEvents)
        
        return loginButton
    }()
    
    // Text field view title label
    lazy var inputAccessoryText: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 1920, height: 150))
        label.font = UIFont.avenirMediumWithSize(45.0)
        label.numberOfLines = 2
        label.textAlignment = .Center
        label.text = "Enter your e-mail\n"
        label.sizeToFit()
        
        return label
    }()
    
    // MARK: - Layout
    
    override var inputAccessoryView: UIView? {
        
        return self.inputAccessoryText
    }
    
    func setupScreen() {
        // Dark background
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "loginBackground")!)

        // Add subviews
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.inputEmail)
        self.view.addSubview(self.loginButton)
        self.view.addSubview(self.messageLabel)
        self.view.addSubview(self.inputPassword)
    }
    
    // MARK: - Animations
    
    // MARK: - User interaction
    
    func pressedLogIn(sender: UIButton) {
        var email: String!
        var password: String!
        
        guard self.inputPassword.text?.characters.count > 3 && self.inputEmail.text?.containsString("@") == true else {
            self.messageLabel.text = "Invalid username or password"
            return
        }
        if let emailInput = inputEmail.text {
            email = emailInput
        }
        if let pwdInput = inputPassword.text {
            password = pwdInput
        }
        
        self.getAuthToken(email, password: password)
        self.messageLabel.text = "Logging in..."
    }
    
    func pressedLogOut(sender: UIButton) {
        print("Logged out")
        
        Authorization.deleteStoredToken()
        
        self.titleLabel.text = "Sign in to continue"
        self.inputEmail.hidden = false
        self.inputPassword.hidden = false
        self.loginButton.hidden = false
    }
}
