recipients = Configuration.get('exception_notification_recipients').split(',')
sender = Configuration.get('exception_notification_sender')
email_subject_prefix = Configuration.get('exception_notification_email_prefix')

ExceptionNotification::Notifier.exception_recipients = recipients
ExceptionNotification::Notifier.sender_address = sender
ExceptionNotification::Notifier.email_prefix = email_subject_prefix
