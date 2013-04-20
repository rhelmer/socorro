.. index:: populate postgres

.. _populatepostgres-chapter:

Populate PostgreSQL
===================

Load the Socorro schema
-------------------

Set up environment
::
  make virtualenv
  . socorro-virtualenv/bin/activate
  export PYTHONPATH=.

Load the Socorro schema
::
  ./socorro/external/postgresql/setupdb_app.py --database_name=breakpad

IMPORTANT NOTE - many reports use the reports_clean_done() stored
procedure to check that reports exist for the last UTC hour of the
day being processed, as a way to catch problems. If your crash
volume does not guarantee one crash per hour, you may want to modify
this function in socorro/external/postgresql/raw_sql/procs/reports_clean_done.sql
and reload the schema
::

  ./socorro/external/postgresql/setupdb_app.py --database_name=breakpad --dropdb

Initially your Socorro install will be empty and not very interesting, because
reports are generated once per day for the previous UTC day. However, you can
easily generate data for testing purposes, and could use this as a starting 
point

Customize CSVs in tools/dataload/, at minimum you probably need to bump the dates and build IDs in
::
  raw_adu.csv reports.csv releases_raw.csv

You will probably want to change "WaterWolf" to your own
product name and version history, if you are setting this up for production.

See :ref:`databasetablesbysource-chapter` for a complete explanation
of each table.

Run backfill function to populate matviews
------------------------------------------
Socorro depends upon materialized views which run nightly, to display
graphs and show reports such as "Top Crash By Signature".

ALSO - the backfill procedure ignores any data over 30 days old.
Make sure you've adjusted the dates in the CSV files appropriately,
or change these functions in socorro/external/postgresql/raw_sql/procs/backfill_*.sql
and reload the schema as above.

There also needs to be at least one featured version, which is
controlled by setting "featured_version" column to "true" for one
or more rows in the product_version table. The import script will go
ahead and set all imported versions as featured.

After modifying CSV files, use the import script to load the data
::
  ./tools/dataload/import.sh

If you ever need to manually backfill for some reason (e.g. incoming data
was held up or needed to be reprocessed), you 
::
    -- backfill from 2013-01-01 to 2013-01-05 inclusive 
    psql breakpad -c "SELECT backfill_matviews('2013-01-01', '2013-01-05')"
