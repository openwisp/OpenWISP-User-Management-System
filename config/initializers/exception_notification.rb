recipients = Configuration.get('exception_notification_recipients').split(',') rescue 'root@localhost'
sender = Configuration.get('exception_notification_sender') rescue 'root@localhost'
email_subject_prefix = Configuration.get('exception_notification_email_prefix') rescue '[OWUMS] '

ExceptionNotification::Notifier.exception_recipients = recipients
ExceptionNotification::Notifier.sender_address = sender
ExceptionNotification::Notifier.email_prefix = email_subject_prefix
