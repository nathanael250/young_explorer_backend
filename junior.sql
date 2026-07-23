-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jul 23, 2026 at 10:23 AM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `junior`
--

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` bigint(20) NOT NULL,
  `booking_reference` varchar(100) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `package_id` bigint(20) DEFAULT NULL,
  `availability_id` bigint(20) DEFAULT NULL,
  `total_people` int(11) DEFAULT NULL,
  `total_amount` decimal(10,2) DEFAULT NULL,
  `special_request` text DEFAULT NULL,
  `booking_type` enum('standard','vip') DEFAULT 'standard',
  `vip_request_details` text DEFAULT NULL,
  `quoted_amount` decimal(10,2) DEFAULT NULL,
  `quoted_currency` varchar(10) DEFAULT 'USD',
  `booking_status` enum('quote_pending','pending','confirmed','cancelled','expired','completed') DEFAULT 'pending',
  `payment_status` enum('unpaid','partial','paid','refunded') DEFAULT 'unpaid',
  `booked_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `booking_reference`, `user_id`, `package_id`, `availability_id`, `total_people`, `total_amount`, `special_request`, `booking_type`, `vip_request_details`, `quoted_amount`, `quoted_currency`, `booking_status`, `payment_status`, `booked_at`) VALUES
(1, 'YE-1779723550102-489', 2, 1, 1, 2, 900.00, NULL, 'standard', NULL, NULL, 'USD', 'confirmed', 'paid', '2026-05-25 15:39:10');

-- --------------------------------------------------------

--
-- Table structure for table `booking_participants`
--

CREATE TABLE `booking_participants` (
  `id` bigint(20) NOT NULL,
  `booking_id` bigint(20) DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `gender` varchar(20) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `passport_number` varchar(100) DEFAULT NULL,
  `nationality` varchar(100) DEFAULT NULL,
  `emergency_contact` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `booking_participants`
--

INSERT INTO `booking_participants` (`id`, `booking_id`, `first_name`, `last_name`, `gender`, `date_of_birth`, `passport_number`, `nationality`, `emergency_contact`) VALUES
(1, 1, 'Aline', 'Mutesi', 'female', '2002-04-12', 'P123456', 'Rwandan', '+250788000000');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `slug` varchar(120) DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `slug`, `status`, `created_at`) VALUES
(1, 'History', 'history', 'active', '2026-07-22 19:21:57'),
(2, 'Art', 'art', 'active', '2026-07-22 19:21:57'),
(3, 'Entertainment', 'entertainment', 'active', '2026-07-22 19:21:57'),
(4, 'Science', 'science', 'active', '2026-07-22 19:21:57'),
(5, 'Culture', 'culture', 'active', '2026-07-22 19:21:57'),
(6, 'Nature', 'nature', 'active', '2026-07-22 19:21:57'),
(7, 'Adventure', 'adventure', 'active', '2026-07-22 19:21:57'),
(8, 'Education', 'education', 'active', '2026-07-22 19:21:57'),
(9, 'Technology', 'technology', 'active', '2026-07-22 19:56:40');

-- --------------------------------------------------------

--
-- Table structure for table `destinations`
--

CREATE TABLE `destinations` (
  `id` bigint(20) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `short_description` text DEFAULT NULL,
  `full_description` longtext DEFAULT NULL,
  `best_time_to_visit` varchar(255) DEFAULT NULL,
  `entry_fee` decimal(10,2) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `main_image` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active',
  `vendor_id` bigint(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `destinations`
--

INSERT INTO `destinations` (`id`, `name`, `slug`, `province`, `district`, `category`, `short_description`, `full_description`, `best_time_to_visit`, `entry_fee`, `latitude`, `longitude`, `main_image`, `status`, `vendor_id`, `created_at`) VALUES
(1, 'Kigali Genocide Memorial', 'kigali-genocide-memorial', 'Kigali', 'Gasabo', 'history', 'A memorial and learning center in Kigali.', 'A key destination for understanding Rwanda history.', 'All year', 0.00, -1.93060000, 30.06060000, NULL, 'active', 0, '2026-05-25 15:08:32'),
(2, 'Gisozi Genocide Memorial', 'gisozi-genocide-memorial', 'Kigali', 'Gasabo', 'history', 'A memorial and learning center in Kigali.', 'A key destination for understanding Rwanda history.', 'All year', 0.00, -1.93060000, 30.06060000, NULL, 'active', 0, '2026-05-28 11:44:16'),
(6, 'Kigali Genocide Memorial', 'kigali-genocide-memorial', 'Kigali', 'Gasabo', 'history', 'A memorial and learning center in Kigali.', 'A key destination for understanding Rwanda history.', 'All year', 0.00, -1.93060000, 30.06060000, '/uploads/1784750053534-280477673.jpg', 'active', 1, '2026-07-22 19:54:13');

-- --------------------------------------------------------

--
-- Table structure for table `destination_images`
--

CREATE TABLE `destination_images` (
  `id` bigint(20) NOT NULL,
  `destination_id` bigint(20) DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `sort_order` int(11) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `destination_images`
--

INSERT INTO `destination_images` (`id`, `destination_id`, `image_path`, `sort_order`, `created_at`) VALUES
(1, 6, '/uploads/1784750053534-280477673.jpg', 1, '2026-07-22 19:54:13');

-- --------------------------------------------------------

--
-- Table structure for table `media_files`
--

CREATE TABLE `media_files` (
  `id` bigint(20) NOT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `file_type` varchar(100) DEFAULT NULL,
  `uploaded_by` bigint(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) NOT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `full_name`, `email`, `subject`, `message`, `created_at`) VALUES
(1, 'Visitor Name', 'visitor@example.com', 'Tour inquiry', 'I want to know more about Young Explorers packages.', '2026-05-25 15:48:06');

-- --------------------------------------------------------

--
-- Table structure for table `packages`
--

CREATE TABLE `packages` (
  `id` bigint(20) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `short_description` text DEFAULT NULL,
  `full_description` longtext DEFAULT NULL,
  `price_per_person` decimal(10,2) DEFAULT 0.00,
  `currency` varchar(10) DEFAULT 'USD',
  `duration_id` bigint(20) DEFAULT NULL,
  `main_image` varchar(255) DEFAULT NULL,
  `meeting_point` varchar(255) DEFAULT NULL,
  `emergency_contact` varchar(100) DEFAULT NULL,
  `age_range` varchar(100) DEFAULT NULL,
  `fitness_level` varchar(100) DEFAULT NULL,
  `cancellation_policy` text DEFAULT NULL,
  `status` enum('draft','published','archived') DEFAULT 'draft',
  `created_by` bigint(20) DEFAULT NULL,
  `vendor_id` bigint(20) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `packages`
--

INSERT INTO `packages` (`id`, `title`, `slug`, `short_description`, `full_description`, `price_per_person`, `currency`, `duration_id`, `main_image`, `meeting_point`, `emergency_contact`, `age_range`, `fitness_level`, `cancellation_policy`, `status`, `created_by`, `vendor_id`, `created_at`) VALUES
(1, '5-Day Rwanda Explorer', '5-day-rwanda-explorer', 'Culture, history, and city highlights.', 'A youth-friendly Rwanda exploration package.', 450.00, 'USD', 2, NULL, 'Kigali International Airport', '+250788222222', '15-25', 'easy', NULL, 'published', 2, 0, '2026-05-25 15:27:55'),
(2, '6-Day Rwanda Explorer', '6-day-rwanda-explorer', 'Culture, history, and city highlights.', 'A youth-friendly Rwanda exploration package.', 450.00, 'USD', 2, NULL, 'Kigali International Airport', '+250788222222', '15-25', 'easy', NULL, 'draft', 2, 0, '2026-05-28 09:48:47'),
(4, '7-Day Rwanda Explorer', '7-day-rwanda-explorer', 'Culture, history, and city highlights.', 'A youth-friendly Rwanda exploration package.', 450.00, 'USD', 2, NULL, 'Kigali International Airport', '+250788222222', '15-25', 'easy', NULL, 'draft', 2, 0, '2026-05-28 09:49:09'),
(6, '8-Day Rwanda Explorer', '8-day-rwanda-explorer', 'Culture, history, and city highlights.', 'A youth-friendly Rwanda exploration package.', 450.00, 'USD', 2, NULL, 'Kigali International Airport', '+250788222222', '15-25', 'easy', NULL, 'published', 2, 0, '2026-05-28 09:49:51'),
(8, '9-Day Rwanda Explorer', '9-day-rwanda-explorer', 'Culture, history, and city highlights.', 'A youth-friendly Rwanda exploration package.', 450.00, 'USD', 2, NULL, 'Kigali International Airport', '+250788222222', '15-25', 'easy', NULL, 'draft', 2, 0, '2026-05-28 09:53:52'),
(10, '2-Day Rwanda Explorer', '2-day-rwanda-explorer', 'Culture, history, and city highlights.', 'A youth-friendly Rwanda exploration package.', 450.00, 'RWD', 2, '/uploads/1779962239110-Screenshot_2026-05-26_at_15.19.04.png', 'Kigali International Airport', '+250788222222', '15-25', 'easy', NULL, 'draft', 2, 0, '2026-05-28 09:57:19');

-- --------------------------------------------------------

--
-- Table structure for table `package_availability`
--

CREATE TABLE `package_availability` (
  `id` bigint(20) NOT NULL,
  `package_id` bigint(20) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `total_seats` int(11) DEFAULT NULL,
  `reserved_seats` int(11) DEFAULT 0,
  `confirmed_seats` int(11) DEFAULT 0,
  `booking_cutoff_hours` int(11) DEFAULT 24,
  `remaining_seats` int(11) GENERATED ALWAYS AS (`total_seats` - `reserved_seats` - `confirmed_seats`) STORED,
  `status` enum('available','fully_booked','cancelled','closed') DEFAULT 'available',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_availability`
--

INSERT INTO `package_availability` (`id`, `package_id`, `start_date`, `end_date`, `total_seats`, `reserved_seats`, `confirmed_seats`, `booking_cutoff_hours`, `status`, `created_at`) VALUES
(1, 1, '2026-07-10', '2026-07-15', 20, 0, 2, 24, 'available', '2026-05-25 15:32:50');

-- --------------------------------------------------------

--
-- Table structure for table `package_categories`
--

CREATE TABLE `package_categories` (
  `package_id` bigint(20) NOT NULL,
  `category_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `package_days`
--

CREATE TABLE `package_days` (
  `id` bigint(20) NOT NULL,
  `package_id` bigint(20) DEFAULT NULL,
  `day_number` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `summary` text DEFAULT NULL,
  `accommodation` varchar(255) DEFAULT NULL,
  `meals` varchar(255) DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_days`
--

INSERT INTO `package_days` (`id`, `package_id`, `day_number`, `title`, `summary`, `accommodation`, `meals`, `start_time`, `end_time`, `created_at`) VALUES
(1, 1, 1, 'Arrival in Kigali', 'Airport pickup and city introduction.', 'Kigali hotel', 'Dinner', '14:00:00', '19:00:00', '2026-05-25 15:27:55'),
(2, 1, 2, 'Day 2', '', NULL, NULL, NULL, NULL, '2026-05-25 15:27:55'),
(3, 1, 3, 'Day 3', '', NULL, NULL, NULL, NULL, '2026-05-25 15:27:55'),
(4, 1, 4, 'Day 4', '', NULL, NULL, NULL, NULL, '2026-05-25 15:27:55'),
(5, 1, 5, 'Day 5', '', NULL, NULL, NULL, NULL, '2026-05-25 15:27:55'),
(6, 2, 1, 'Day 1', '', NULL, NULL, NULL, NULL, '2026-05-28 09:48:47'),
(7, 2, 2, 'Day 2', '', NULL, NULL, NULL, NULL, '2026-05-28 09:48:47'),
(8, 2, 3, 'Day 3', '', NULL, NULL, NULL, NULL, '2026-05-28 09:48:47'),
(9, 2, 4, 'Day 4', '', NULL, NULL, NULL, NULL, '2026-05-28 09:48:47'),
(10, 2, 5, 'Day 5', '', NULL, NULL, NULL, NULL, '2026-05-28 09:48:47'),
(11, 4, 1, 'Day 1', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:09'),
(12, 4, 2, 'Day 2', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:09'),
(13, 4, 3, 'Day 3', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:09'),
(14, 4, 4, 'Day 4', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:09'),
(15, 4, 5, 'Day 5', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:09'),
(16, 6, 1, 'Day 1', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:51'),
(17, 6, 2, 'Day 2', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:51'),
(18, 6, 3, 'Day 3', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:51'),
(19, 6, 4, 'Day 4', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:51'),
(20, 6, 5, 'Day 5', '', NULL, NULL, NULL, NULL, '2026-05-28 09:49:51'),
(21, 8, 1, 'Day 1', '', NULL, NULL, NULL, NULL, '2026-05-28 09:53:52'),
(22, 8, 2, 'Day 2', '', NULL, NULL, NULL, NULL, '2026-05-28 09:53:52'),
(23, 8, 3, 'Day 3', '', NULL, NULL, NULL, NULL, '2026-05-28 09:53:52'),
(24, 8, 4, 'Day 4', '', NULL, NULL, NULL, NULL, '2026-05-28 09:53:52'),
(25, 8, 5, 'Day 5', '', NULL, NULL, NULL, NULL, '2026-05-28 09:53:52'),
(26, 10, 1, 'Day 1', '', NULL, NULL, NULL, NULL, '2026-05-28 09:57:19'),
(27, 10, 2, 'Day 2', '', NULL, NULL, NULL, NULL, '2026-05-28 09:57:19'),
(28, 10, 3, 'Day 3', '', NULL, NULL, NULL, NULL, '2026-05-28 09:57:19'),
(29, 10, 4, 'Day 4', '', NULL, NULL, NULL, NULL, '2026-05-28 09:57:19'),
(30, 10, 5, 'Day 5', '', NULL, NULL, NULL, NULL, '2026-05-28 09:57:19');

-- --------------------------------------------------------

--
-- Table structure for table `package_day_destinations`
--

CREATE TABLE `package_day_destinations` (
  `id` bigint(20) NOT NULL,
  `package_day_id` bigint(20) DEFAULT NULL,
  `destination_id` bigint(20) DEFAULT NULL,
  `visit_order` int(11) DEFAULT NULL,
  `activity_title` varchar(255) DEFAULT NULL,
  `activity_description` text DEFAULT NULL,
  `arrival_time` time DEFAULT NULL,
  `departure_time` time DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_day_destinations`
--

INSERT INTO `package_day_destinations` (`id`, `package_day_id`, `destination_id`, `visit_order`, `activity_title`, `activity_description`, `arrival_time`, `departure_time`, `notes`, `created_at`) VALUES
(1, 1, 1, 1, 'Memorial visit', 'Guided history session.', '15:00:00', '17:00:00', 'Respectful dress recommended.', '2026-05-25 15:31:57');

-- --------------------------------------------------------

--
-- Table structure for table `package_durations`
--

CREATE TABLE `package_durations` (
  `id` bigint(20) NOT NULL,
  `title` varchar(100) DEFAULT NULL,
  `total_days` int(11) DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_durations`
--

INSERT INTO `package_durations` (`id`, `title`, `total_days`, `status`, `created_at`) VALUES
(1, '3 Days', 3, 'active', '2026-05-25 15:17:56'),
(2, '5 Days', 5, 'active', '2026-05-25 15:17:56'),
(3, '7 Days', 7, 'active', '2026-05-25 15:17:56'),
(4, '14 Days', 14, 'active', '2026-05-25 15:17:56');

-- --------------------------------------------------------

--
-- Table structure for table `package_exclusions`
--

CREATE TABLE `package_exclusions` (
  `id` bigint(20) NOT NULL,
  `package_id` bigint(20) DEFAULT NULL,
  `item` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_exclusions`
--

INSERT INTO `package_exclusions` (`id`, `package_id`, `item`) VALUES
(1, 1, 'Visa fees'),
(2, 1, 'Personal shopping');

-- --------------------------------------------------------

--
-- Table structure for table `package_images`
--

CREATE TABLE `package_images` (
  `id` bigint(20) NOT NULL,
  `package_id` bigint(20) DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `sort_order` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_images`
--

INSERT INTO `package_images` (`id`, `package_id`, `image_path`, `sort_order`, `created_at`) VALUES
(1, 10, '/uploads/1779962239110-Screenshot_2026-05-26_at_15.19.04.png', 1, '2026-05-28 09:57:19'),
(2, 10, '/uploads/1779962239112-Screenshot_2026-05-27_at_11.24.48.png', 2, '2026-05-28 09:57:19'),
(3, 10, '/uploads/1779962239114-Screenshot_2026-05-27_at_11.56.28.png', 3, '2026-05-28 09:57:19');

-- --------------------------------------------------------

--
-- Table structure for table `package_inclusions`
--

CREATE TABLE `package_inclusions` (
  `id` bigint(20) NOT NULL,
  `package_id` bigint(20) DEFAULT NULL,
  `item` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_inclusions`
--

INSERT INTO `package_inclusions` (`id`, `package_id`, `item`) VALUES
(1, 1, 'Transport'),
(2, 1, 'Meals'),
(3, 1, 'Tour guide');

-- --------------------------------------------------------

--
-- Table structure for table `package_not_allowed_items`
--

CREATE TABLE `package_not_allowed_items` (
  `id` bigint(20) NOT NULL,
  `package_id` bigint(20) DEFAULT NULL,
  `item` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_not_allowed_items`
--

INSERT INTO `package_not_allowed_items` (`id`, `package_id`, `item`) VALUES
(1, 1, 'Weapons'),
(2, 1, 'Drugs');

-- --------------------------------------------------------

--
-- Table structure for table `package_required_items`
--

CREATE TABLE `package_required_items` (
  `id` bigint(20) NOT NULL,
  `package_id` bigint(20) DEFAULT NULL,
  `item` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_required_items`
--

INSERT INTO `package_required_items` (`id`, `package_id`, `item`) VALUES
(1, 1, 'Passport'),
(2, 1, 'Jacket');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` bigint(20) NOT NULL,
  `booking_id` bigint(20) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `payment_method` varchar(100) DEFAULT NULL,
  `transaction_reference` varchar(255) DEFAULT NULL,
  `payment_proof` varchar(255) DEFAULT NULL,
  `payment_status` enum('pending','verified','rejected') DEFAULT 'pending',
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `booking_id`, `amount`, `payment_method`, `transaction_reference`, `payment_proof`, `payment_status`, `paid_at`, `created_at`) VALUES
(1, 1, 900.00, 'bank_transfer', 'TXN-001', '/uploads/manual-proof.jpg', 'verified', '2026-07-22 19:56:56', '2026-05-25 15:40:08'),
(2, 1, 900.00, 'bank_transfer', 'TXN-001', '/uploads/manual-proof.jpg', 'pending', NULL, '2026-05-25 15:40:58');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) NOT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `role` enum('admin','explorer','vendor') DEFAULT 'explorer',
  `profile_image` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive','blocked') DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `first_name`, `last_name`, `email`, `phone`, `password`, `role`, `profile_image`, `status`, `created_at`) VALUES
(1, 'niyo', 'Nathanael', 'nathan@gmail.com', '+250781796824', '$2a$10$PIToiZEUlC1/Lm3ATZSMyuryAFXPomZaUNjdHeukrL3frLJfzbV2q', 'explorer', NULL, 'active', '2026-05-25 14:07:43'),
(2, 'Admin', 'User', 'admin@gmail.com', '+250781790900', '$2a$10$OzJmTTLR1SEgo7CDv9ztweIKEUV29F6qU4vxcy5BcdWwOK00GKr5C', 'admin', NULL, 'active', '2026-05-25 14:20:40'),
(3, 'Jean', 'Vendor', 'vendor@example.com', '+250788333333', '$2a$10$Qmhoe1ih2jhlhZaGmyof3ek3T2EL6z5sti9z9MZKOiC4z/uEn5pbe', 'vendor', NULL, 'active', '2026-07-22 19:35:24');

-- --------------------------------------------------------

--
-- Table structure for table `vendors`
--

CREATE TABLE `vendors` (
  `id` bigint(20) NOT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `business_name` varchar(255) DEFAULT NULL,
  `business_phone` varchar(30) DEFAULT NULL,
  `business_email` varchar(150) DEFAULT NULL,
  `business_address` varchar(255) DEFAULT NULL,
  `rib_certificate` varchar(255) DEFAULT NULL,
  `approval_status` enum('pending','approved','rejected','blocked') DEFAULT 'pending',
  `review_notes` text DEFAULT NULL,
  `reviewed_by` bigint(20) DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `vendors`
--

INSERT INTO `vendors` (`id`, `user_id`, `business_name`, `business_phone`, `business_email`, `business_address`, `rib_certificate`, `approval_status`, `review_notes`, `reviewed_by`, `reviewed_at`, `created_at`) VALUES
(1, 3, 'Junior Travels Ltd', '+250788444444', 'business@example.com', 'Kigali, Rwanda', '/uploads/1784748924407-cover_letter.pdf', 'approved', 'Business information reviewed and approved.', 2, '2026-07-22 19:35:50', '2026-07-22 19:35:24');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `booking_reference` (`booking_reference`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `package_id` (`package_id`),
  ADD KEY `availability_id` (`availability_id`);

--
-- Indexes for table `booking_participants`
--
ALTER TABLE `booking_participants`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`);

--
-- Indexes for table `destinations`
--
ALTER TABLE `destinations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_vendor_destination_slug` (`vendor_id`,`slug`),
  ADD KEY `idx_destinations_slug` (`slug`);

--
-- Indexes for table `destination_images`
--
ALTER TABLE `destination_images`
  ADD PRIMARY KEY (`id`),
  ADD KEY `destination_id` (`destination_id`);

--
-- Indexes for table `media_files`
--
ALTER TABLE `media_files`
  ADD PRIMARY KEY (`id`),
  ADD KEY `uploaded_by` (`uploaded_by`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `packages`
--
ALTER TABLE `packages`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD KEY `duration_id` (`duration_id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `package_availability`
--
ALTER TABLE `package_availability`
  ADD PRIMARY KEY (`id`),
  ADD KEY `package_id` (`package_id`);

--
-- Indexes for table `package_categories`
--
ALTER TABLE `package_categories`
  ADD PRIMARY KEY (`package_id`,`category_id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `package_days`
--
ALTER TABLE `package_days`
  ADD PRIMARY KEY (`id`),
  ADD KEY `package_id` (`package_id`);

--
-- Indexes for table `package_day_destinations`
--
ALTER TABLE `package_day_destinations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `package_day_id` (`package_day_id`),
  ADD KEY `destination_id` (`destination_id`);

--
-- Indexes for table `package_durations`
--
ALTER TABLE `package_durations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `package_exclusions`
--
ALTER TABLE `package_exclusions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `package_id` (`package_id`);

--
-- Indexes for table `package_images`
--
ALTER TABLE `package_images`
  ADD PRIMARY KEY (`id`),
  ADD KEY `package_id` (`package_id`);

--
-- Indexes for table `package_inclusions`
--
ALTER TABLE `package_inclusions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `package_id` (`package_id`);

--
-- Indexes for table `package_not_allowed_items`
--
ALTER TABLE `package_not_allowed_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `package_id` (`package_id`);

--
-- Indexes for table `package_required_items`
--
ALTER TABLE `package_required_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `package_id` (`package_id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `vendors`
--
ALTER TABLE `vendors`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `reviewed_by` (`reviewed_by`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `booking_participants`
--
ALTER TABLE `booking_participants`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `destinations`
--
ALTER TABLE `destinations`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `destination_images`
--
ALTER TABLE `destination_images`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `media_files`
--
ALTER TABLE `media_files`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `package_availability`
--
ALTER TABLE `package_availability`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `package_days`
--
ALTER TABLE `package_days`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `package_day_destinations`
--
ALTER TABLE `package_day_destinations`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `package_durations`
--
ALTER TABLE `package_durations`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `package_exclusions`
--
ALTER TABLE `package_exclusions`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `package_images`
--
ALTER TABLE `package_images`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `package_inclusions`
--
ALTER TABLE `package_inclusions`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `package_not_allowed_items`
--
ALTER TABLE `package_not_allowed_items`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `package_required_items`
--
ALTER TABLE `package_required_items`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `vendors`
--
ALTER TABLE `vendors`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`),
  ADD CONSTRAINT `bookings_ibfk_3` FOREIGN KEY (`availability_id`) REFERENCES `package_availability` (`id`);

--
-- Constraints for table `booking_participants`
--
ALTER TABLE `booking_participants`
  ADD CONSTRAINT `booking_participants_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`);

--
-- Constraints for table `destination_images`
--
ALTER TABLE `destination_images`
  ADD CONSTRAINT `destination_images_ibfk_1` FOREIGN KEY (`destination_id`) REFERENCES `destinations` (`id`);

--
-- Constraints for table `media_files`
--
ALTER TABLE `media_files`
  ADD CONSTRAINT `media_files_ibfk_1` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `packages`
--
ALTER TABLE `packages`
  ADD CONSTRAINT `packages_ibfk_1` FOREIGN KEY (`duration_id`) REFERENCES `package_durations` (`id`),
  ADD CONSTRAINT `packages_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `package_availability`
--
ALTER TABLE `package_availability`
  ADD CONSTRAINT `package_availability_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`);

--
-- Constraints for table `package_categories`
--
ALTER TABLE `package_categories`
  ADD CONSTRAINT `package_categories_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`),
  ADD CONSTRAINT `package_categories_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`);

--
-- Constraints for table `package_days`
--
ALTER TABLE `package_days`
  ADD CONSTRAINT `package_days_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`);

--
-- Constraints for table `package_day_destinations`
--
ALTER TABLE `package_day_destinations`
  ADD CONSTRAINT `package_day_destinations_ibfk_1` FOREIGN KEY (`package_day_id`) REFERENCES `package_days` (`id`),
  ADD CONSTRAINT `package_day_destinations_ibfk_2` FOREIGN KEY (`destination_id`) REFERENCES `destinations` (`id`);

--
-- Constraints for table `package_exclusions`
--
ALTER TABLE `package_exclusions`
  ADD CONSTRAINT `package_exclusions_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`);

--
-- Constraints for table `package_images`
--
ALTER TABLE `package_images`
  ADD CONSTRAINT `package_images_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`);

--
-- Constraints for table `package_inclusions`
--
ALTER TABLE `package_inclusions`
  ADD CONSTRAINT `package_inclusions_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`);

--
-- Constraints for table `package_not_allowed_items`
--
ALTER TABLE `package_not_allowed_items`
  ADD CONSTRAINT `package_not_allowed_items_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`);

--
-- Constraints for table `package_required_items`
--
ALTER TABLE `package_required_items`
  ADD CONSTRAINT `package_required_items_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`);

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`);

--
-- Constraints for table `vendors`
--
ALTER TABLE `vendors`
  ADD CONSTRAINT `vendors_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `vendors_ibfk_2` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
