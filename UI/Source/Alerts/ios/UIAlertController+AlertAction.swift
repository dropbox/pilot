import Pilot

/// Extensions to make it easy to create UIAlertController objects from an AlertAction
extension AlertAction {
    public var alertControllerStyle: UIAlertControllerStyle {
        switch style {
        case .sheet:
            return .actionSheet
        case .dialog:
            return .alert
        }
    }

    public func alertController(context: Context) -> UIAlertController {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: alertControllerStyle)

        for button in buttons {
            let alertAction = UIAlertAction(title: button.title,
                                            style: button.type.alertActionStyle,
                                            handler: { (_) in
                                                if let action = button.action {
                                                    action.send(from: context)
                                                }
            })
            alert.addAction(alertAction)
        }
        return alert
    }
}

extension AlertAction.ButtonType {
    public var alertActionStyle: UIAlertActionStyle {
        switch self {
        case .normal:
            return .default
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}
