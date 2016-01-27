import Foundation

public class Formatter {
    
    // MARK: - Properties
    
    // MARK: - Methods
    
    static func formatTime(dateAndTime: String) -> String {
        
        var month = dateAndTime[dateAndTime.startIndex.advancedBy(5)...dateAndTime.startIndex.advancedBy(6)]
        
        switch month {
        case "01":
            month = "January"
        case "02":
            month = "February"
        case "03":
            month = "Mars"
        case "04":
            month = "April"
        case "05":
            month = "May"
        case "06":
            month = "June"
        case "07":
            month = "July"
        case "08":
            month = "August"
        case "09":
            month = "September"
        case "10":
            month = "October"
        case "11":
            month = "November"
        case "12":
            month = "December"
        default:
            print("ERROR in timeAndPlace-string")
        }
        
        let day = dateAndTime[dateAndTime.startIndex.advancedBy(8)...dateAndTime.startIndex.advancedBy(9)]
        let year = dateAndTime[dateAndTime.startIndex.advancedBy(0)...dateAndTime.startIndex.advancedBy(3)]
        
        return month + " " + day + ", " + year
    }
    
    static func greetingForCountry(country: String) -> String {
        switch country {
        case "Canada":
            return "Hockey!"
        case "Ireland":
            return "Cheers!"
        case "Sweden":
            return "Hej!"
        case "Dominican Republic":
            return "Hola!"
        case "Japan":
            return "Konnichiwa!"
        case "Singapore":
            return "Ni hau!"
        case "Uruguay":
            return "Hola!"
        case "United Kingdom":
            return "Happy days!"
        default:
            return "Hello!"
        }
    }
}
