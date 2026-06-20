-- Escape text for safe interpolation into a PostgreSQL regular expression.
CREATE OR REPLACE FUNCTION regex_escape(text) RETURNS text
AS $$
  SELECT regexp_replace($1, '([\\.\+\*\?\[\^\]\$\(\)\{\}=!<>\|:\-])', '\\\1', 'g');
$$ LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE;
