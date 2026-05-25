const commands = require("../config/command");
const authModel = require("./authModel");
const resourceModel = require("./resourceModel");
const packageModel = require("./packageModel");
const bookingModel = require("./bookingModel");
const paymentModel = require("./paymentModel");
const dashboardModel = require("./dashboardModel");
const mediaModel = require("./mediaModel");
const messageModel = require("./messageModel");
const { httpError } = require("./modelUtils");

async function handleCommand(context) {
  const command = context.body.command;

  if (!command) {
    throw httpError(400, "Command is required");
  }

  const resourceCommand = resourceCommandMap[command];
  if (resourceCommand) {
    return resourceCommand.handler({
      ...context,
      body: {
        ...context.body,
        resource: resourceCommand.resource,
      },
    });
  }

  switch (command) {
    case commands.HEALTH:
      return { message: "API is ready", data: { service: "young-explorers-api" } };
    case commands.AUTH_REGISTER:
      return authModel.register(context.body.data || {});
    case commands.AUTH_LOGIN:
      return authModel.login(context.body.data || {});
    case commands.AUTH_ME:
      return authModel.getCurrentUser(context.user);
    case commands.AUTH_UPDATE_PROFILE:
      return authModel.updateProfile(context);
    case commands.AUTH_CHANGE_PASSWORD:
      return authModel.changePassword(context);
    case commands.USER_SET_STATUS:
      return authModel.setUserStatus(context);
    case commands.LIST:
      return resourceModel.listResource(context);
    case commands.GET:
      return resourceModel.getResource(context);
    case commands.CREATE:
      return resourceModel.createResource(context);
    case commands.UPDATE:
      return resourceModel.updateResource(context);
    case commands.DELETE:
      return resourceModel.deleteResource(context);
    case commands.PACKAGE_CREATE:
      return packageModel.createPackageWithDays(context);
    case commands.PACKAGE_UPDATE:
      return packageModel.updatePackage(context);
    case commands.PACKAGE_DETAILS:
      return packageModel.getPackageDetails(context);
    case commands.PACKAGE_SET_RULES:
      return packageModel.setPackageRules(context);
    case commands.PACKAGE_CREATE_AVAILABILITY:
      return packageModel.createAvailability(context);
    case commands.PACKAGE_UPDATE_AVAILABILITY:
      return packageModel.updateAvailability(context);
    case commands.ITINERARY_UPDATE_DAY:
      return packageModel.updateItineraryDay(context);
    case commands.ITINERARY_ADD_DESTINATION:
      return packageModel.addItineraryDestination(context);
    case commands.ITINERARY_REMOVE_DESTINATION:
      return packageModel.removeItineraryDestination(context);
    case commands.BOOKING_CREATE:
      return bookingModel.createBooking(context);
    case commands.BOOKING_CANCEL:
      return bookingModel.cancelBooking(context);
    case commands.BOOKING_EXPIRE_PENDING:
      return bookingModel.expirePendingBookings(context);
    case commands.PAYMENT_SUBMIT:
      return paymentModel.submitPayment(context);
    case commands.PAYMENT_VERIFY:
      return paymentModel.verifyPayment(context);
    case commands.DASHBOARD_STATS:
      return dashboardModel.getDashboardStats(context);
    case commands.CONTACT_SEND:
      return messageModel.sendContactMessage(context);
    case commands.MEDIA_UPLOAD:
      return mediaModel.uploadMedia(context);
    default:
      throw httpError(400, `Unknown command: ${command}`);
  }
}

const resourceCommandMap = {
  [commands.LIST_DESTINATIONS]: { resource: "destinations", handler: resourceModel.listResource },
  [commands.GET_DESTINATION]: { resource: "destinations", handler: resourceModel.getResource },
  [commands.CREATE_DESTINATION]: { resource: "destinations", handler: resourceModel.createResource },
  [commands.UPDATE_DESTINATION]: { resource: "destinations", handler: resourceModel.updateResource },
  [commands.DELETE_DESTINATION]: { resource: "destinations", handler: resourceModel.deleteResource },
  [commands.LIST_DURATIONS]: { resource: "package_durations", handler: resourceModel.listResource },
  [commands.CREATE_DURATION]: { resource: "package_durations", handler: resourceModel.createResource },
  [commands.UPDATE_DURATION]: { resource: "package_durations", handler: resourceModel.updateResource },
  [commands.DELETE_DURATION]: { resource: "package_durations", handler: resourceModel.deleteResource },
  [commands.LIST_BOOKINGS]: { resource: "bookings", handler: resourceModel.listResource },
  [commands.GET_BOOKING]: { resource: "bookings", handler: resourceModel.getResource },
  [commands.LIST_PAYMENTS]: { resource: "payments", handler: resourceModel.listResource },
  [commands.GET_PAYMENT]: { resource: "payments", handler: resourceModel.getResource },
  [commands.LIST_USERS]: { resource: "users", handler: resourceModel.listResource },
  [commands.GET_USER]: { resource: "users", handler: resourceModel.getResource },
  [commands.LIST_MESSAGES]: { resource: "messages", handler: resourceModel.listResource },
  [commands.GET_MESSAGE]: { resource: "messages", handler: resourceModel.getResource },
  [commands.DELETE_MESSAGE]: { resource: "messages", handler: resourceModel.deleteResource },
  [commands.LIST_MEDIA]: { resource: "media_files", handler: resourceModel.listResource },
  [commands.GET_MEDIA]: { resource: "media_files", handler: resourceModel.getResource },
  [commands.LIST_PACKAGES]: { resource: "packages", handler: resourceModel.listResource },
};

module.exports = {
  handleCommand,
};
