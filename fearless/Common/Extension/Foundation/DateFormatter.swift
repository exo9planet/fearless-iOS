import Foundation
import SoraFoundation

extension DateFormatter {
    static var txHistory: LocalizableResource<DateFormatter> {
        LocalizableResource { locale in
            let format = DateFormatter.dateFormat(fromTemplate: "HHmm", options: 0, locale: locale)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            dateFormatter.locale = locale
            return dateFormatter
        }
    }

    static var txDetails: LocalizableResource<DateFormatter> {
        LocalizableResource { locale in
            let format = DateFormatter.dateFormat(fromTemplate: "ddMMMyyyyHHmmss", options: 0, locale: locale)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            dateFormatter.locale = locale
            return dateFormatter
        }
    }

    static var shortDate: LocalizableResource<DateFormatter> {
        LocalizableResource { locale in
            let format = DateFormatter.dateFormat(fromTemplate: "ddMMMyyyy", options: 0, locale: locale)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            dateFormatter.locale = locale
            return dateFormatter
        }
    }

    static var sectionedDate: LocalizableResource<DateFormatter> {
        LocalizableResource { locale in
            let format = DateFormatter.dateFormat(fromTemplate: "MMMM dd", options: 0, locale: locale)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            dateFormatter.locale = locale
            return dateFormatter
        }
    }

    static var giantsquidDate: LocalizableResource<DateFormatter> {
        LocalizableResource { _ in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            return dateFormatter
        }
    }

    static var suibsquidInputDate: LocalizableResource<DateFormatter> {
        LocalizableResource { _ in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            return dateFormatter
        }
    }
}
