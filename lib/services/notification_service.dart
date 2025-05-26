// lib/services/notification_service.dart

/// Holds your user’s notification preferences in one place.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool pushReminders = true; // DI2: neutral, unobtrusive
  bool emailReminders = true; // TL11: friendly reminders
  bool paymentConfirmations = true; // DI2: confirm actions politely

  // Toggle methods (could hook into persistent storage later)
  void setPushReminders(bool v) => pushReminders = v;
  void setEmailReminders(bool v) => emailReminders = v;
  void setPaymentConfirmations(bool v) => paymentConfirmations = v;
}
