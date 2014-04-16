CREATE OR REPLACE FUNCTION update_crash_adu_by_build_signature(
    updateday date,
    checkdata boolean DEFAULT true
)
    RETURNS boolean
    LANGUAGE plpgsql
    SET "TimeZone" to 'UTC'
AS $$
BEGIN

CREATE TEMPORARY TABLE new_build_adus
AS
    WITH build_adus AS (
        SELECT
            product_versions.product_name,
            build_adu.build_date,
            SUM(build_adu.adu_count) AS aducount,
            build_adu.os_name,
            build_adu.adu_date,
            build_type_enum as channel
        FROM build_adu
    JOIN product_versions USING (product_version_id)
        WHERE adu_date BETWEEN updateday::timestamptz AND updateday::timestamptz + '1 day'::interval
        GROUP BY product_versions.product_name,
            build_adu.build_date,
            build_adu.os_name,
            build_adu.adu_date,
            product_versions.build_type_enum
    ),
    sigreports AS (
        SELECT
            build,
            COUNT(*) AS crashcount,
            os_name,
            reports_clean.signature_id,
            signatures.signature as signature
        FROM reports_clean
        JOIN signatures ON reports_clean.signature_id = signatures.signature_id
        WHERE
            date_processed BETWEEN updateday::timestamptz AND updateday::timestamptz + '1 day'::interval
        GROUP BY build, os_name, reports_clean.signature_id, signatures.signature
    )
    SELECT
        build_adus.product_name as product_name,
        build_adus.build_date as build_date,
        build_adus.aducount as adu_count,
        build_adus.os_name as os_name,
        build_adus.adu_date as adu_date,
        build_adus.channel as channel,
        sigreports.signature_id as signature_id,
        sigreports.signature as signature,
        sigreports.build as buildid,
        sigreports.crashcount as crash_count
    FROM build_adus
    JOIN sigreports ON sigreports.os_name = build_adus.os_name AND
    to_date(substring(sigreports.build::text from 1 for 8), 'YYYYMMDD') = build_adus.build_date
    WHERE length(build::text) >= 8
;

PERFORM 1 FROM new_build_adus;
IF NOT FOUND THEN
    IF checkdata THEN
        RAISE NOTICE 'no new build adus for day %', updateday;
        RETURN FALSE;
    END IF;
END IF;

ANALYZE new_build_adus;

INSERT INTO crash_adu_by_build_signature (
    product_name,
    signature_id,
    signature,
    adu_date,
    build_date,
    buildid,
    crash_count,
    adu_count,
    os_name,
    channel
)
SELECT
    new_build_adus.product_name,
    new_build_adus.signature_id,
    new_build_adus.signature,
    new_build_adus.adu_date,
    new_build_adus.build_date,
    new_build_adus.buildid,
    new_build_adus.crash_count,
    new_build_adus.adu_count,
    new_build_adus.os_name,
    new_build_adus.channel
FROM
    new_build_adus
;

DROP TABLE new_build_adus;

RETURN True;

END;
$$;
