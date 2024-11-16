-- Table with signals including their azimuth based on the direction of the signal and the railway line
-- and the functional signal feature
CREATE OR REPLACE VIEW signals_with_azimuth_view AS
  SELECT
    s.id,
    s.way,
    s.railway,
    s.ref,
    s.ref_multiline,
    s.deactivated,
    s.signal_direction,
    degrees(ST_Azimuth(
      st_lineinterpolatepoint(sl.way, greatest(0, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) - 0.01)),
      st_lineinterpolatepoint(sl.way, least(1, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) + 0.01))
    )) + (CASE WHEN signal_direction = 'backward' THEN 180.0 ELSE 0.0 END) as azimuth,
    CASE

        {% for feature in signals_railway_signals.features %}
        -- ({% feature.country %}) {% feature.description %}
        WHEN{% for tag in feature.tags %} "{% tag.tag %}"{% if tag.value %}='{% tag.value %}'{% elif tag.values %} IN ({% for value in tag.values %}{% unless loop.first %}, {% end %}'{% value %}'{% end %}){% end %}{% unless loop.last %} AND{% end %}{% end %}

          THEN {% if feature.icon.match %} CASE
            {% for case in feature.icon.cases %}
            WHEN "{% feature.icon.match %}" ~ '{% case.regex %}' THEN '{% case.value %}'

{% end %}
            {% if feature.icon.default %}
            ELSE '{% feature.icon.default %}'
{% end %}
          END{% else %} '{% feature.icon.default %}'{% end %}


{% end %}

    END as signal_feature,
    CASE
        {% for feature in speed_railway_signals.features %}
        -- ({% feature.country %}) {% feature.description %}
        WHEN{% for tag in feature.tags %} "{% tag.tag %}"{% if tag.value %}='{% tag.value %}'{% elif tag.values %} IN ({% for value in tag.values %}{% unless loop.first %}, {% end %}'{% value %}'{% end %}){% end %}{% unless loop.last %} AND{% end %}{% end %}

          THEN {% if feature.icon.match %} CASE
            {% for case in feature.icon.cases %}
            WHEN "{% feature.icon.match %}" ~ '{% case.regex %}' THEN{% if case.value | contains("{}") %} CONCAT('{% case.value | regexReplace("\{\}.*$", "") %}', "{% feature.icon.match %}", '{% case.value | regexReplace("^.*\{\}", "") %}'){% else %} '{% case.value %}'{% end %}

{% end %}
            {% if feature.icon.default %}
            ELSE '{% feature.icon.default %}'
{% end %}
          END{% else %} '{% feature.icon.default %}'{% end %}


{% end %}

    END as speed_feature,
    CASE
      {% for feature in speed_railway_signals.features %}
        {% if feature.type %}
        -- ({% feature.country %}) {% feature.description %}
        WHEN{% for tag in feature.tags %} "{% tag.tag %}"{% if tag.value %}='{% tag.value %}'{% elif tag.values %} IN ({% for value in tag.values %}{% unless loop.first %}, {% end %}'{% value %}'{% end %}){% end %}{% unless loop.last %} AND{% end %}{% end %} THEN '{% feature.type %}'

{% end %}
{% end %}

    END as speed_feature_type,
    CASE
      {% for feature in electrification_signals.features %}
        -- ({% feature.country %}) {% feature.description %}
        WHEN{% for tag in feature.tags %} "{% tag.tag %}"{% if tag.value %}='{% tag.value %}'{% elif tag.values %} IN ({% for value in tag.values %}{% unless loop.first %}, {% end %}'{% value %}'{% end %}){% end %}{% unless loop.last %} AND{% end %}{% end %}

          THEN {% if feature.icon.match %} CASE
            {% for case in feature.icon.cases %}
            WHEN "{% feature.icon.match %}" ~ '{% case.regex %}' THEN '{% case.value %}'
{% end %}
            ELSE '{% feature.icon.default %}'
          END{% else %} '{% feature.icon.default %}'{% end %}


{% end %}
    END as electrification_feature
  FROM signals s
  LEFT JOIN LATERAL (
    SELECT line.way as way
    FROM railway_line line
    WHERE st_dwithin(s.way, line.way, 10) AND line.railway IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'construction', 'preserved', 'monorail', 'miniature') -- TODO use feature
    ORDER BY s.way <-> line.way
    LIMIT 1
  ) as sl ON true
  WHERE
    (railway IN ('signal', 'buffer_stop') AND signal_direction IS NOT NULL)
    OR railway IN ('derail', 'vacancy_detection');

-- Use the view directly such that the query in the view can be updated
CREATE MATERIALIZED VIEW IF NOT EXISTS signals_with_azimuth AS
  SELECT
    *
  FROM
    signals_with_azimuth_view;

CREATE INDEX IF NOT EXISTS signals_with_azimuth_geom_index
  ON signals_with_azimuth
  USING GIST(way);
