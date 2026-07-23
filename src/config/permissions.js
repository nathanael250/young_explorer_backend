const publicCommands = new Set([
  "HEALTH",
  "REGISTER",
  "REGISTER_VENDOR",
  "LOGIN",
  "LIST_PACKAGES",
  "LIST_DESTINATIONS",
  "GET_DESTINATION",
  "LIST_DURATIONS",
  "LIST_CATEGORIES",
  "GET_PACKAGE_DETAILS",
  "SEND_CONTACT_MESSAGE",
]);

const adminOnlyCommands = new Set([
  "SET_USER_STATUS",
  "LIST_VENDORS",
  "REVIEW_VENDOR",
  "CREATE_RESOURCE",
  "UPDATE_RESOURCE",
  "DELETE_RESOURCE",
  "CREATE_DESTINATION",
  "UPDATE_DESTINATION",
  "DELETE_DESTINATION",
  "CREATE_DURATION",
  "UPDATE_DURATION",
  "DELETE_DURATION",
  "CREATE_CATEGORY",
  "UPDATE_CATEGORY",
  "DELETE_CATEGORY",
  "LIST_USERS",
  "GET_USER",
  "LIST_PAYMENTS",
  "GET_PAYMENT",
  "LIST_MESSAGES",
  "GET_MESSAGE",
  "DELETE_MESSAGE",
  "LIST_MEDIA",
  "GET_MEDIA",
  "CREATE_PACKAGE",
  "UPDATE_PACKAGE",
  "SET_PACKAGE_RULES",
  "CREATE_PACKAGE_AVAILABILITY",
  "UPDATE_PACKAGE_AVAILABILITY",
  "UPDATE_ITINERARY_DAY",
  "ADD_ITINERARY_DESTINATION",
  "REMOVE_ITINERARY_DESTINATION",
  "EXPIRE_PENDING_BOOKINGS",
  "QUOTE_VIP_BOOKING",
  "MARK_VIP_BOOKING_PAID",
  "VERIFY_PAYMENT",
  "GET_DASHBOARD_STATS",
  "UPLOAD_MEDIA",
]);

const protectedCommands = new Set([
  "ME",
  "UPDATE_PROFILE",
  "CHANGE_PASSWORD",
  "GET_VENDOR",
  "CREATE_BOOKING",
  "CANCEL_BOOKING",
  "SUBMIT_PAYMENT",
  "LIST_BOOKINGS",
  "GET_BOOKING",
]);

function isPublicCommand(command) {
  return publicCommands.has(command);
}

function isProtectedCommand(command) {
  return protectedCommands.has(command) || adminOnlyCommands.has(command);
}

function isAdminOnlyCommand(command) {
  return adminOnlyCommands.has(command);
}

module.exports = {
  publicCommands,
  protectedCommands,
  adminOnlyCommands,
  isPublicCommand,
  isProtectedCommand,
  isAdminOnlyCommand,
};
