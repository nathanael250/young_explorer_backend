const publicCommands = new Set([
  "HEALTH",
  "REGISTER",
  "LOGIN",
  "LIST_PACKAGES",
  "LIST_DESTINATIONS",
  "GET_DESTINATION",
  "LIST_DURATIONS",
  "GET_PACKAGE_DETAILS",
  "SEND_CONTACT_MESSAGE",
]);

const adminOnlyCommands = new Set([
  "SET_USER_STATUS",
  "CREATE_RESOURCE",
  "UPDATE_RESOURCE",
  "DELETE_RESOURCE",
  "CREATE_DESTINATION",
  "UPDATE_DESTINATION",
  "DELETE_DESTINATION",
  "CREATE_DURATION",
  "UPDATE_DURATION",
  "DELETE_DURATION",
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
  "VERIFY_PAYMENT",
  "GET_DASHBOARD_STATS",
  "UPLOAD_MEDIA",
]);

const protectedCommands = new Set([
  "ME",
  "UPDATE_PROFILE",
  "CHANGE_PASSWORD",
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
