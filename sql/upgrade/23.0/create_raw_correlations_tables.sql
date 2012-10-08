/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

\set ON_ERROR_STOP 1

SELECT create_table_if_not_exists( 'correlation_addons_raw',
$x$
CREATE TABLE correlation_addons_raw (
	product text NOT NULL,
	release text NOT NULL,
	os_name text NOT NULL,
	signature text NOT NULL,
	reason text NOT NULL,
	total_signature_count int NOT NULL,
	total_os_count int NOT NULL,
	libname text NOT NULL,
	in_signature_count int NOT NULL,
	in_signature_ratio int NOT NULL,
	in_signature_versions int,
	in_signature_versions_ratio int,
	in_os_count int NOT NULL,
	in_os_ratio int NOT NULL,
	in_os_versions int,
	in_os_versions_ratio int,
	version text
);
$x$,
'breakpad_rw');


SELECT create_table_if_not_exists( 'correlation_modules_raw',
$x$
CREATE TABLE correlation_modules_raw (
	product text NOT NULL,
	release text NOT NULL,
	os_name text NOT NULL,
	signature text NOT NULL,
	reason text NOT NULL,
	total_signature_count int NOT NULL,
	total_os_count int NOT NULL,
	libname text NOT NULL,
	in_signature_count int NOT NULL,
	in_signature_ratio int NOT NULL,
	in_signature_versions int,
	in_signature_versions_ratio int,
	in_os_count int NOT NULL,
	in_os_ratio int NOT NULL,
	in_os_versions int,
	in_os_versions_ratio int,
	version text
);
$x$,
'breakpad_rw');


SELECT create_table_if_not_exists( 'correlation_cores_raw',
$x$
CREATE TABLE correlation_cores_raw (
	product text NOT NULL,
	release text NOT NULL,
	os_name text NOT NULL,
	signature text NOT NULL,
	reason text NOT NULL,
	total_signature_count int NOT NULL,
	total_os_count int NOT NULL,
	in_signature_count int NOT NULL,
	in_signature_ratio int NOT NULL,
	in_os_count int NOT NULL,
	in_os_ratio int NOT NULL,
	family text NOT NULL,
	core_count int NOT NULL
);
$x$,
'breakpad_rw');
