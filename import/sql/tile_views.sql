--- Shared ---

CREATE OR REPLACE VIEW railway_line_low AS
  SELECT
    way,
    highspeed,
    -- speeds are converted to kph in this layer because it is used for colouring
    maxspeed,
    train_protection,
    train_protection_rank,
    railway_to_int(voltage) AS voltage,
    railway_to_float(frequency) AS frequency,
    railway_to_int(gauge) AS gaugeint0,
    gauge as gauge0
  FROM (
    SELECT
      way,
      railway_dominant_speed(preferred_direction, maxspeed, maxspeed_forward, maxspeed_backward) AS maxspeed,
      highspeed,
      train_protection,
      train_protection_rank,
      frequency,
      voltage,
      railway_desired_value_from_list(1, gauge) AS gauge
    FROM railway_line
    WHERE railway = 'rail' AND usage = 'main' AND service IS NULL
  ) AS r
  ORDER by
    highspeed,
    maxspeed NULLS FIRST;

CREATE OR REPLACE VIEW railway_line_med AS
  SELECT
    way,
    usage,
    highspeed,
    maxspeed,
    train_protection_rank,
    train_protection,
    electrification_state,
    voltage,
    frequency,
    railway_to_int(gauge) AS gaugeint0,
    gauge as gauge0
  FROM
    (SELECT
       way,
       railway,
       usage,
       highspeed,
       -- speeds are converted to kph in this layer because it is used for colouring
       railway_dominant_speed(preferred_direction, maxspeed, maxspeed_forward, maxspeed_backward) AS maxspeed,
       train_protection_rank,
       train_protection,
       railway_electrification_state(railway, electrified, deelectrified, abandoned_electrified, NULL, NULL, true) AS electrification_state,
       railway_to_int(voltage) AS voltage,
       railway_to_float(frequency) AS frequency,
       railway_desired_value_from_list(1, gauge) AS gauge
     FROM railway_line
     WHERE railway = 'rail' AND usage IN ('main', 'branch') AND service IS NULL
    ) AS r
  ORDER by
    CASE
      WHEN railway = 'rail' AND usage = 'main' AND highspeed THEN 2000
      WHEN railway = 'rail' AND usage = 'main' THEN 1100
      WHEN railway = 'rail' AND usage = 'branch' THEN 1000
      ELSE 50
    END NULLS LAST,
    maxspeed NULLS FIRST;

--- Standard ---

CREATE OR REPLACE VIEW standard_railway_text_stations_low AS
  SELECT
    way,
    label
  FROM stations_with_route_counts
  WHERE
    railway = 'station'
    AND label IS NOT NULL
    AND route_count >= 8
  ORDER BY
    route_count DESC NULLS LAST;

CREATE OR REPLACE VIEW standard_railway_text_stations_med AS
  SELECT
    way,
    label
  FROM stations_with_route_counts
  WHERE
    railway = 'station'
    AND label IS NOT NULL
  ORDER BY
    route_count DESC NULLS LAST;

CREATE OR REPLACE VIEW standard_railway_line_fill AS
  SELECT
    way,
    railway,
    CASE
      WHEN railway = 'proposed' THEN proposed_railway
      WHEN railway = 'construction' THEN construction_railway
      WHEN railway = 'razed' THEN razed_railway
      WHEN railway = 'abandoned' THEN abandoned_railway
      WHEN railway = 'disused' THEN disused_railway
      ELSE railway
    END as feature,
    usage,
    service,
    highspeed,
    (tunnel IS NOT NULL AND tunnel != 'no') as tunnel,
    (bridge IS NOT NULL AND bridge != 'no') as bridge,
    CASE
      WHEN ref IS NOT NULL AND label_name IS NOT NULL THEN ref || ' ' || label_name
      ELSE COALESCE(ref, label_name)
    END AS label,
    ref,
    track_ref,
    CASE
      WHEN railway = 'rail' AND usage IN ('tourism', 'military', 'test') AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service = 'siding' THEN 870
      WHEN railway = 'rail' AND usage IS NULL AND service = 'yard' THEN 860
      WHEN railway = 'rail' AND usage IS NULL AND service = 'spur' THEN 880
      WHEN railway = 'rail' AND usage IS NULL AND service = 'crossover' THEN 300
      WHEN railway = 'rail' AND usage = 'main' AND service IS NULL AND highspeed THEN 2000
      WHEN railway = 'rail' AND usage = 'main' AND service IS NULL THEN 1100
      WHEN railway = 'rail' AND usage = 'branch' AND service IS NULL THEN 1000
      WHEN railway = 'rail' AND usage = 'industrial' AND service IS NULL THEN 850
      WHEN railway = 'rail' AND usage = 'industrial' AND service IN ('siding', 'spur', 'yard', 'crossover') THEN 850
      WHEN railway IN ('preserved', 'construction') THEN 400
      WHEN railway = 'proposed' THEN 350
      WHEN railway = 'disused' THEN 300
      WHEN railway = 'abandoned' THEN 250
      WHEN railway = 'razed' THEN 200
      ELSE 50
    END AS rank
  FROM
    (SELECT
       way,
       railway,
       usage,
       service,
       highspeed,
       disused_railway, abandoned_railway,
       razed_railway, construction_railway,
       proposed_railway,
       layer,
       bridge,
       tunnel,
       track_ref,
       ref,
       CASE
         WHEN railway = 'abandoned' THEN railway_label_name(COALESCE(abandoned_name, name), tunnel, tunnel_name, bridge, bridge_name)
         WHEN railway = 'razed' THEN railway_label_name(COALESCE(razed_name, name), tunnel, tunnel_name, bridge, bridge_name)
         ELSE railway_label_name(name, tunnel, tunnel_name, bridge, bridge_name)
       END AS label_name
     FROM railway_line
     WHERE railway IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'disused', 'abandoned', 'razed', 'construction', 'proposed')
    ) AS r
  ORDER by layer, rank NULLS LAST;

CREATE OR REPLACE VIEW standard_railway_text_stations AS
  SELECT
    way,
    railway,
    station,
    label,
    name,
    CASE
      WHEN railway = 'station' AND station = 'light_rail' THEN 450
      WHEN railway = 'station' AND station = 'subway' THEN 400
      WHEN railway = 'station' THEN 800
      WHEN railway = 'halt' AND station = 'light_rail' THEN 500
      WHEN railway = 'halt' THEN 550
      WHEN railway = 'tram_stop' THEN 300
      WHEN railway = 'service_station' THEN 600
      WHEN railway = 'yard' THEN 700
      WHEN railway = 'junction' THEN 650
      WHEN railway = 'spur_junction' THEN 420
      WHEN railway = 'site' THEN 600
      WHEN railway = 'crossover' THEN 700
      ELSE 50
    END AS rank
  FROM
    (SELECT
       way,
       railway,
       route_count,
       station,
       label,
       name
     FROM stations_with_route_counts
     WHERE railway IN ('station', 'halt', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site')
       AND name IS NOT NULL
    ) AS r
  ORDER by rank DESC NULLS LAST, route_count DESC NULLS LAST;

CREATE OR REPLACE VIEW standard_railway_symbols AS
  SELECT
    way,
    railway,
    man_made,
    CASE
      WHEN railway = 'crossing' THEN -1::int
      WHEN railway = 'tram_stop' THEN 1::int
      ELSE 0
    END AS prio
  FROM pois
  WHERE railway IN ('crossing', 'level_crossing', 'phone', 'tram_stop', 'border', 'owner_change', 'radio')
  ORDER BY prio DESC;

CREATE OR REPLACE VIEW standard_railway_text_km AS
  SELECT
    way,
    railway,
    pos,
    (railway_pos_decimal(pos) = '0') as zero
  FROM
    (SELECT
       way,
       railway,
       COALESCE(railway_position, railway_pos_round(railway_position_detail)::text) AS pos
     FROM railway_positions
    ) AS r
  WHERE pos IS NOT NULL
  ORDER by zero;

CREATE OR REPLACE VIEW standard_railway_switch_ref AS
  SELECT
    way,
    railway,
    ref,
    railway_local_operated
  FROM railway_switches
  ORDER by char_length(ref);


--- Speed ---

CREATE OR REPLACE VIEW speed_railway_line_fill AS
  SELECT
    way,
    railway,
    usage,
    service,
    CASE
      WHEN railway = 'construction' THEN construction_railway
      WHEN railway = 'disused' THEN disused_railway
      WHEN railway = 'preserved' THEN preserved_railway
      ELSE railway
    END as feature,
    -- speeds are converted to kph in this layer because it is used for colouring
    railway_dominant_speed(preferred_direction, maxspeed, maxspeed_forward, maxspeed_backward) AS maxspeed,
    CASE
      WHEN railway = 'rail' AND usage IN ('tourism', 'military', 'test') AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service = 'siding' THEN 870
      WHEN railway = 'rail' AND usage IS NULL AND service = 'yard' THEN 860
      WHEN railway = 'rail' AND usage IS NULL AND service = 'spur' THEN 880
      WHEN railway = 'rail' AND usage IS NULL AND service = 'crossover' THEN 300
      WHEN railway = 'rail' AND usage = 'main' AND service IS NULL THEN 1100
      WHEN railway = 'rail' AND usage = 'branch' AND service IS NULL THEN 1000
      WHEN railway = 'rail' AND usage = 'industrial' AND service IS NULL THEN 850
      WHEN railway = 'rail' AND usage = 'industrial' AND service IN ('siding', 'spur', 'yard', 'crossover') THEN 850
      WHEN railway IN ('preserved', 'construction') THEN 400
      WHEN railway = 'disused' THEN 300
      ELSE 50
    END AS rank,
    railway_speed_label(speed_arr) AS label
  FROM
    (SELECT
       way,
       railway,
       usage,
       service,
       maxspeed,
       maxspeed_forward,
       maxspeed_backward,
       preferred_direction,
       -- does no unit conversion
       railway_direction_speed_limit(preferred_direction,maxspeed, maxspeed_forward, maxspeed_backward) AS speed_arr,
       disused_railway,
       construction_railway,
       preserved_railway,
       layer
     FROM railway_line
     WHERE railway IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'disused', 'construction', 'preserved')
    ) AS r
  ORDER BY
    layer,
    rank NULLS LAST,
    maxspeed NULLS FIRST;

CREATE OR REPLACE VIEW speed_railway_signals AS
  SELECT
    way,
    CASE
        {% for feature in speed_railway_signals.features %}
        -- ({% feature.country %}) {% feature.description %}
        WHEN{% for tag in feature.tags %} "{% tag.tag %}"{% if tag.value %}='{% tag.value %}'{% elif tag.values %} IN ({% for value in tag.values %}{% unless loop.first %}, {% end %}'{% value %}'{% end %}){% end %}{% unless loop.last %} AND{% end %}{% end %}

          THEN {% if feature.icon.match %} CASE
            {% for case in feature.icon.cases %}
            WHEN "{% feature.icon.match %}"{% if case.null %} IS NULL{% else %} ~ '{% case.regex %}'{% end %} THEN{% if case.value | contains("{}") %} CONCAT('{% case.value | regexReplace("\{\}.*$", "") %}', "{% feature.icon.match %}", '{% case.value | regexReplace("^.*\{\}", "") %}'){% else %} '{% case.value %}'{% end %}

{% end %}
            {% if feature.icon.default %}
            ELSE '{% feature.icon.default %}'
{% end %}
          END{% else %} '{% feature.icon.default %}'{% end %}


{% end %}

      END as feature,
    CASE
      {% for feature in speed_railway_signals.features %}
        {% if feature.type %}
        -- ({% feature.country %}) {% feature.description %}
        WHEN{% for tag in feature.tags %} "{% tag.tag %}"{% if tag.value %}='{% tag.value %}'{% elif tag.values %} IN ({% for value in tag.values %}{% unless loop.first %}, {% end %}'{% value %}'{% end %}){% end %}{% unless loop.last %} AND{% end %}{% end %} THEN '{% feature.type %}'

{% end %}
{% end %}

    END as type,
    azimuth
  FROM (
    SELECT
      way,
      {% for tag in speed_railway_signals.tags %}
      {% unless tag | matches("railway:signal:speed_limit:speed") %}
      {% unless tag | matches("railway:signal:speed_limit_distant:speed") %}
      "{% tag %}",
{% end %}
{% end %}
{% end %}
      -- We cast the lowest speed to text to make it possible to only select those speeds in
      -- CartoCSS we have an icon for. Otherwise we might render an icon for 40 kph if
      -- 42 is tagged (but invalid tagging).
      railway_largest_speed_noconvert("railway:signal:speed_limit:speed")::text AS "railway:signal:speed_limit:speed",
      railway_largest_speed_noconvert("railway:signal:speed_limit_distant:speed")::text AS "railway:signal:speed_limit_distant:speed",
      azimuth
    FROM signals_with_azimuth s
    WHERE railway = 'signal'
      AND signal_direction IS NOT NULL
      AND ("railway:signal:speed_limit" IS NOT NULL OR "railway:signal:speed_limit_distant" IS NOT NULL)
  ) AS feature_signals
  ORDER BY
    -- distant signals are less important, signals for slower speeds are more important
    ("railway:signal:speed_limit" IS NOT NULL) DESC NULLS FIRST,
    railway_speed_int(COALESCE("railway:signal:speed_limit:speed", "railway:signal:speed_limit_distant:speed")) DESC NULLS FIRST;


--- Signals ---

CREATE OR REPLACE VIEW signals_railway_line AS
  SELECT
    way,
    railway,
    usage,
    service,
    layer,
    CASE
      WHEN railway = 'construction' THEN construction_railway
      WHEN railway = 'disused' THEN disused_railway
      WHEN railway = 'preserved' THEN preserved_railway
      ELSE railway
    END as feature,
    train_protection_rank,
    train_protection
  FROM railway_line
  WHERE railway IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'disused', 'preserved', 'construction')
  ORDER BY
    layer,
    train_protection_rank NULLS LAST;

CREATE OR REPLACE VIEW signals_signal_boxes AS
  SELECT
    way,
    ref,
    name
  FROM signal_boxes
  ORDER BY way_area DESC NULLS LAST;

CREATE OR REPLACE VIEW signals_railway_signals AS
  WITH pre_signals AS (
    SELECT
      way,
      railway,
      ref,
      ref_multiline,
      ref_width,
      ref_height,
      feature,
      rank,
      deactivated,
      wrong_road,
      wrong_road_form,
      combined_form,
      main_form,
      distant_form,
      train_protection_form,
      main_repeated_form,
      minor_form,
      passing_form,
      shunting_form,
      stop_form,
      stop_demand_form,
      station_distant_form,
      crossing_form,
      departure_form,
      speed_limit_form,
      main_height,
      minor_height,
      combined_states,
      main_states,
      distant_states,
      minor_states,
      shunting_states,
      main_repeated_states,
      speed_limit_states,
      distant_repeated,
      crossing_repeated,
      combined_shortened,
      distant_shortened,
      crossing_distant_shortened,
      crossing_shortened,
      ring_only_transit,
      whistle_only_transit,
      train_protection_type,
      passing_type,
      train_protection_shape,
      resetting_switch_form,
      resetting_switch_distant_form,
      azimuth
    FROM signals_with_azimuth
    WHERE
      ((railway IN ('signal', 'buffer_stop') AND signal_direction IS NOT NULL)
        OR railway = 'derail')
      -- TODO investigate signals with null features
      AND feature IS NOT NULL
  )
  SELECT
    way,
    railway,
    ref,
    ref_multiline,
    deactivated,
    CASE

      -- AT --

      -- AT shunting light signals (Verschubverbot)
      WHEN feature = 'AT-V2:verschubsignal' AND shunting_form = 'light' THEN 'at/verschubverbot-aufgehoben'

      -- AT minor light signals (Sperrsignale) as sign
      WHEN feature = 'AT-V2:weiterfahrt_verboten' AND minor_form = 'sign' THEN 'at/weiterfahrt-verboten'

      -- AT minor light signals (Sperrsignale) as semaphore signals
      WHEN feature = 'AT-V2:sperrsignal' AND minor_form = 'semaphore' THEN 'at/weiterfahrt-erlaubt'

      -- AT distant light signals
      WHEN feature = 'AT-V2:vorsignal' AND distant_form = 'light' THEN
        CASE
          WHEN distant_states ~ '^(.*;)?AT-V2:hauptsignal_frei_mit_60(;.*)?$' THEN 'at/vorsignal-hauptsignal-frei-mit-60'
          WHEN distant_states ~ '^(.*;)?AT-V2:hauptsignal_frei_mit_(2|4)0(;.*)?$' THEN 'at/vorsignal-hauptsignal-frei-mit-40'
          WHEN distant_states ~ '^(.*;)?AT-V2:hauptsignal_frei(;.*)?$' THEN 'at/vorsignal-hauptsignal-frei'
          ELSE 'at/vorsignal-vorsicht'
        END

      -- AT distant semaphore signals
      WHEN feature = 'AT-V2:vorsignal' AND distant_form = 'semaphore' THEN 'at/vorsicht-semaphore'

      -- AT main light signals
      WHEN feature = 'AT-V2:hauptsignal' AND main_form = 'light' THEN
        CASE
          WHEN main_states ~ '^(.*;)?AT-V2:frei_mit_60(;.*)?$' THEN 'at/hauptsignal-frei-mit-60'
          WHEN main_states ~ '^(.*;)?AT-V2:frei_mit_(2|4)0(;.*)?$' THEN 'at/hauptsignal-frei-mit-40'
          WHEN main_states ~ '^(.*;)?AT-V2:frei(;.*)?$' THEN 'at/hauptsignal-frei'
          ELSE 'at/hauptsignal-halt'
        END

      -- BE --

      WHEN feature = 'BE:GSA' THEN 'be/GSA-V'

      WHEN feature = 'BE:SAS' THEN 'be/SAS'

      WHEN feature = 'BE:PSA' THEN 'be/PSA'

      -- DE --

      -- DE crossing distant sign Bü 2
      WHEN feature = 'DE-ESO:db:bü4' THEN
        CASE
          WHEN whistle_only_transit = 'yes' THEN 'de/bue4-ds-only-transit'
          ELSE 'de/bue4-ds'
        END

      -- DE whistle sign Bü 2
      WHEN feature = 'DE-ESO:bü2' THEN
        CASE
          WHEN  crossing_distant_shortened = 'yes' THEN 'de/bue2-ds-reduced-distance'
          ELSE 'de/bue2-ds'
        END

      -- DE whistle sign Bü 3
      WHEN feature = 'DE-ESO:bü3' THEN 'de/bue3'

      -- DE whistle sign Pf 1 (DV 301)
      WHEN feature = 'DE-ESO:dr:pf1' THEN
        CASE
          WHEN whistle_only_transit = 'yes' THEN 'de/pf1-dv-only-transit'
          ELSE 'de/pf1-dv'
        END

      -- DE ring sign Bü 5
      WHEN feature = 'DE-ESO:bü5' THEN
        CASE
          WHEN ring_only_transit = 'yes' THEN 'de/bue5-only-transit'
          ELSE 'de/bue5'
        END

      -- DE crossing signal Bü 0/1
      WHEN feature = 'DE-ESO:bü' THEN
        CASE
          WHEN crossing_form = 'sign' THEN
            CASE
              WHEN crossing_repeated = 'yes' THEN 'de/bue0-ds-repeated'
              WHEN crossing_shortened = 'yes' THEN 'de/bue0-ds-shortened'
              ELSE 'de/bue0-ds'
            END
          WHEN crossing_repeated = 'yes' THEN 'de/bue1-ds-repeated'
          WHEN crossing_shortened = 'yes' THEN 'de/bue1-ds-shortened'
          ELSE 'de/bue1-ds'
        END

      -- DE crossing signal Bü 0/1 (ex. So 16a/b) which can show Bü 1 (ex. So 16b)
      WHEN feature = 'DE-ESO:so16' AND crossing_form = 'light' THEN
        CASE
          WHEN crossing_repeated = 'yes' THEN 'de/bue1-dv-repeated'
          WHEN crossing_shortened = 'yes' THEN 'de/bue1-dv-shortened'
          ELSE 'de/bue1-dv'
        END

      -- DE tram signal "start of train protection" So 1
      WHEN feature IN ('DE-BOStrab:so1', 'DE-AVG:so1') AND train_protection_form = 'sign' AND train_protection_type = 'start' THEN 'de/bostrab/so1'

      -- DE tram signal "end of train protection" So 2
      WHEN feature IN ('DE-BOStrab:so2', 'DE-AVG:so2') AND train_protection_form = 'sign' AND train_protection_type = 'end' THEN 'de/bostrab/so2'

      -- DE station distant sign Ne 6
      WHEN feature = 'DE-ESO:ne6' AND station_distant_form = 'sign' THEN 'de/ne6'

      -- DE stop demand post Ne 5 (light)
      WHEN feature = 'DE-ESO:ne5' AND stop_demand_form = 'light' AND stop_form IS NULL THEN 'de/ne5-light'

      -- DE stop demand post Ne 5 (sign)
      WHEN feature = 'DE-ESO:ne5' AND stop_demand_form IS NULL AND stop_form = 'sign' THEN 'de/ne5-sign'

      -- DE Ne13 resetting switch signal
      WHEN feature = 'DE-ESO:ne13' AND resetting_switch_form = 'light' THEN 'de/ne13a'

      -- DE Ne12 resetting switch distant signal
      WHEN feature = 'DE-ESO:ne12' AND resetting_switch_distant_form = 'sign' THEN 'de/ne12'

      -- DE shunting stop sign Ra 10
      -- AT shunting stop sign "Verschubhalttafel"
      WHEN feature IN ('DE-ESO:ra10', 'AT-V2:verschubhalttafel') AND shunting_form = 'sign' THEN 'de/ra10'

      -- DE wrong road signal Zs 6 (DB) / Zs 7 (DR)
      WHEN wrong_road = 'DE-ESO:db:zs6' AND wrong_road_form = 'sign' THEN 'de/zs6-sign'
      WHEN wrong_road = 'DE-ESO:db:zs6' AND wrong_road_form = 'light' THEN 'de/zs6-db-light'
      WHEN wrong_road = 'DE-ESO:db:zs7' AND wrong_road_form = 'light' THEN 'de/zs7-dr-light'

      -- DE tram minor stop sign Sh 1
      WHEN feature = 'DE-BOStrab:sh1' AND minor_form = 'sign' THEN 'de/bostrab/sh1'

      -- DE tram passing prohibited sign So 5
      WHEN feature = 'DE-BOStrab:so5' AND passing_form = 'sign' AND passing_type = 'no_type' THEN 'de/bostrab/so5'

      -- DE tram passing prohibited end sign So 6
      WHEN feature = 'DE-BOStrab:so6' AND passing_form = 'sign' AND passing_type = 'passing_allowed' THEN 'de/bostrab/so6'

      -- DE shunting signal Ra 11 without Sh 1
      -- AT Wartesignal ohne "Verschubverbot aufgehoben"
      WHEN feature IN ('DE-ESO:ra11', 'AT-V2:wartesignal') AND shunting_form = 'sign' THEN 'de/ra11-sign'

      -- DE shunting signal Ra 11 with Sh 1
      WHEN feature = 'DE-ESO:ra11' AND shunting_form = 'light' THEN 'de/ra11-sh1'

      -- DE shunting signal Ra 11b (without Sh 1)
      WHEN feature = 'DE-ESO:ra11b' AND shunting_form = 'sign' THEN 'de/ra11b'

      -- DE minor light signals type Sh
      WHEN feature = 'DE-ESO:sh' AND minor_form = 'light' THEN
        CASE
          WHEN (minor_height = 'normal' AND (minor_states IS NULL OR minor_states ~ '^(.*;)?DE-ESO:sh1(;.*)?$'))
            OR (minor_height IS NULL AND minor_states IS NULL)
          THEN 'de/sh1-light-normal'
          ELSE 'de/sh0-light-dwarf'
        END

      -- DE minor semaphore signals and signs type Sh
      WHEN (feature = 'DE-ESO:sh' AND minor_form = 'semaphore')
        OR (feature = 'DE-ESO:sh0' AND minor_form = 'sign')
      THEN
        CASE
          WHEN minor_states ~ '^(.*;)?DE-ESO:wn7(;.*)?$' THEN 'de/wn7-semaphore-normal'
          WHEN minor_form = 'semaphore' AND (minor_height IS NULL or minor_height = 'normal') THEN 'de/sh1-semaphore-normal'
          ELSE 'de/sh0-semaphore-dwarf'
        END

      -- DE signal Sh 2 as signal and at buffer stops
      WHEN feature IN ('DE-ESO:sh2', 'DE-BOStrab:sh2') THEN 'de/sh2'

      -- DE Signalhaltmelder Zugleitbetrieb
      --   repeats DE-ESO:hp0 of the entrance main signal to the halt position
      WHEN feature = 'DE-DB:signalhaltmelder' AND main_repeated_form = 'light' THEN 'de/zlb-haltmelder-light'

      -- DE main entry sign Ne 1
      WHEN feature IN ('DE-ESO:bü2', 'AT-V2:trapeztafel') AND main_form = 'sign' THEN 'de/ne1'

      -- DE distant light signals type Vr which
      --  - are repeaters or shortened
      --  - have no railway:signal:states=* tag
      --  - OR have railway:signal:states=* tag that does neither include Vr1 nor Vr2
      WHEN feature = 'DE-ESO:vr' AND distant_form = 'light' THEN
        CASE
          WHEN distant_shortened = 'yes' OR distant_repeated = 'yes' THEN
          CASE
            WHEN distant_states ~ '^(.*;)?DE-ESO:vr2(;.*)?$' THEN 'de/vr2-light-repeated'
            WHEN distant_states ~ '^(.*;)?DE-ESO:vr1(;.*)?$' THEN 'de/vr1-light-repeated'
            ELSE 'de/vr0-light-repeated'
          END
          WHEN distant_states ~ '^(.*;)?DE-ESO:vr2(;.*)?$' THEN 'de/vr2-light'
          WHEN distant_states ~ '^(.*;)?DE-ESO:vr1(;.*)?$' THEN 'de/vr1-light'
          ELSE 'de/vr0-light'
        END

      -- DE distant semaphore signals type Vr which
      --  - have no railway:signal:states=* tag
      --  - OR have railway:signal:states=* tag that does neither include Vr1 nor Vr2
      WHEN feature = 'DE-ESO:vr' AND distant_form = 'semaphore' THEN
        CASE
          WHEN distant_states ~ '^(.*;)?DE-ESO:vr2(;.*)?$' THEN 'de/vr2-semaphore'
          WHEN distant_states ~ '^(.*;)?DE-ESO:vr1(;.*)?$' THEN 'de/vr1-semaphore'
          ELSE 'de/vr0-semaphore'
        END

      -- DE Hamburger Hochbahn distant signal
      WHEN feature = 'DE-HHA:v' AND distant_form = 'light' THEN 'de/hha/v1'

      -- DE block marker ("Blockkennzeichen")
      WHEN feature = 'DE-ESO:blockkennzeichen' THEN
        CASE
          WHEN ref_width <= 4 AND ref_height <= 2 THEN CONCAT('de/blockkennzeichen-', ref_width, 'x', ref_height)
          ELSE 'de/blockkennzeichen'
        END

      -- DE distant signal replacement by sign So 106
      -- AT Kreuztafel
      WHEN feature IN ('DE-ESO:so106', 'AT-V2:kreuztafel') AND distant_form = 'sign' THEN 'de/so106'

      -- DE distant signal replacement by sign Ne 2
      WHEN feature = 'DE-ESO:db:ne2' AND distant_form = 'sign' THEN
        CASE
          WHEN distant_shortened = 'yes' THEN 'de/ne2-reduced-distance'
          ELSE 'de/ne2'
        END

      -- DE main semaphore signals type Hp
      -- AT main semaphore signal "Hauptsignal"
      WHEN feature IN ('DE-ESO:hp', 'AT-V2:hauptsignal') AND main_form = 'semaphore' THEN
        CASE
          WHEN main_states ~ '^(.*;)?(DE-ESO:hp2|AT-V2:frei_mit_(4|2)0)(;.*)?$' THEN 'de/hp2-semaphore'
          WHEN main_states ~ '^(.*;)?(DE-ESO:hp1|AT-V2:frei)(;.*)?$' THEN 'de/hp1-semaphore'
          ELSE 'de/hp0-semaphore'
        END

      -- DE main light signals type Hp
      WHEN feature = 'DE-ESO:hp' AND main_form = 'light' THEN
        CASE
          WHEN main_states ~ '^(.*;)?DE-ESO:hp2(;.*)?$' THEN 'de/hp2-light'
          WHEN main_states ~ '^(.*;)?DE-ESO:hp1(;.*)?$' THEN 'de/hp1-light'
          ELSE 'de/hp0-light'
        END

      -- DE main, combined and distant light signals type Hl
      WHEN feature = 'DE-ESO:hl' AND main_form = 'light' THEN
        CASE
          WHEN main_form IS NULL AND distant_form = 'light' AND combined_form IS NULL THEN 'de/hl1-distant'
          WHEN main_form = 'light' AND distant_form IS NULL AND combined_form IS NULL THEN
            CASE
              WHEN main_states ~ '^(.*;)?DE-ESO:hl2(;.*)?$' THEN 'de/hl2'
              WHEN main_states ~ '^(.*;)?DE-ESO:hl3b(;.*)?$' THEN 'de/hl3b'
              WHEN main_states ~ '^(.*;)?DE-ESO:hl3a(;.*)?$' THEN 'de/hl3a'
              WHEN main_states ~ '^(.*;)?DE-ESO:hl1(;.*)?$' THEN 'de/hl1'
              ELSE 'de/hl0'
            END
          WHEN main_form IS NULL AND distant_form IS NULL AND combined_form = 'light' THEN
            CASE
              WHEN combined_states ~ '^(.*;)?DE-ESO:hl11(;.*)?$' THEN 'de/hl11'
              WHEN combined_states ~ '^(.*;)?DE-ESO:hl12b(;.*)?$' THEN 'de/hl12b'
              WHEN combined_states ~ '^(.*;)?DE-ESO:hl12a(;.*)?$' THEN 'de/hl12a'
              WHEN combined_states ~ '^(.*;)?DE-ESO:hl10(;.*)?$' THEN 'de/hl10'
              ELSE 'de/hl0'
            END
          ELSE ''
        END

      -- DE combined light signals type Sv
      WHEN feature = 'DE-ESO:sv' THEN
        CASE
          WHEN combined_states ~ '^(.*;)?DE-ESO:hp0(;.*)?$' THEN 'de/hp0'
          WHEN combined_states ~ '^(.*;)?DE-ESO:sv0(;.*)?$' THEN 'de/sv0'
          ELSE ''
        END

      -- DE tram main signal "Fahrsignal"
      WHEN feature IN ('DE-AVG:f', 'DE-BOStrab:f') AND main_form = 'light' THEN
        CASE
          WHEN main_states ~ '^(.*;)?(DE-AVG|DE-BOStrab):f5(;.*)?$' THEN 'de/bostrab/f5'
          WHEN main_states ~ '^(.*;)?(DE-AVG|DE-BOStrab):f3(;.*)?$' THEN 'de/bostrab/f3'
          WHEN main_states ~ '^(.*;)?(DE-AVG|DE-BOStrab):f2(;.*)?$' THEN 'de/bostrab/f2'
          WHEN main_states ~ '^(.*;)?(DE-AVG|DE-BOStrab):f1(;.*)?$' THEN 'de/bostrab/f1'
          ELSE 'de/bostrab/f0'
        END

      -- DE Hamburger Hochbahn main signal
      WHEN feature = 'DE-HHA:h' AND main_form = 'light' THEN
        CASE
          WHEN main_states IS NULL THEN 'de/hha/h1'
          ELSE 'de/hha/h0'
        END

      -- DE main, combined and distant signals type Ks
      WHEN feature = 'DE-ESO:ks' THEN
        CASE
          WHEN main_form IS NULL AND distant_form = 'light' AND combined_form IS NULL THEN
            CASE
              WHEN distant_repeated = 'yes' THEN 'de/ks-distant-repeated'
              WHEN distant_shortened = 'yes' THEN 'de/ks-distant-shortened'
              ELSE 'de/ks-distant'
            END
          WHEN main_form = 'light' AND distant_form IS NULL AND combined_form IS NULL THEN 'de/ks-main'
          WHEN main_form IS NULL AND distant_form IS NULL AND combined_form = 'light' THEN
            CASE
              WHEN combined_shortened = 'yes' THEN 'de/ks-combined-shortened'
              ELSE 'de/ks-combined'
            END
          ELSE ''
        END


      -- FI --

      -- FI crossing signal To
      WHEN feature = 'FI:To' AND crossing_form = 'light' THEN 'fi/to1'

      -- FI shunting light signals type Ro (new)
      WHEN feature = 'FI:Ro' AND shunting_form = 'light' AND shunting_states ~ '^(.*;)?FI:Ro0(;.*)?$' THEN 'fi/ro0-new'

      -- FI minor light signals type Lo at moveable bridges
      WHEN feature = 'FI:Lo' AND minor_form = 'light' AND shunting_states ~ '^(.*;)?FI:Lo0(;.*)?$' THEN 'fi/lo0'

      -- FI distant light signals
      WHEN feature = 'FI:Eo' AND distant_form = 'light' AND distant_repeated != 'yes' THEN
        CASE
          WHEN distant_states ~ '^(.*;)?FI:Eo2(;.*)?$' THEN 'fi/eo2-new'
          WHEN distant_states ~ '^(.*;)?FI:Eo1(;.*)?$' THEN 'fi/eo1-new'
          ELSE 'fi/eo0-new'
        END
      WHEN feature = 'FI:Eo-v' AND distant_form = 'light' AND distant_repeated != 'yes' THEN
        CASE
          WHEN distant_states ~ '^(.*;)?FI:Eo1(;.*)?$' THEN 'fi/eo1-old'
          ELSE 'fi/eo0-old'
        END

      -- FI main light signals
      WHEN feature = 'FI:Po' AND main_form = 'light' THEN
        CASE
          WHEN main_states ~ '^(.*;)?FI:Po2(;.*)?$' THEN 'fi/po2-new'
          WHEN main_states ~ '^(.*;)?FI:Po1(;.*)?$' THEN 'fi/po1-new'
          ELSE 'fi/po0-new'
        END
      WHEN feature = 'FI:Po-v' AND main_form = 'light' THEN
        CASE
          WHEN main_states ~ '^(.*;)?FI:Po2(;.*)?$' THEN 'fi/po2-old'
          WHEN main_states ~ '^(.*;)?FI:Po1(;.*)?$' THEN 'fi/po1-old'
          ELSE 'fi/po0-old'
        END

      -- FI combined block signal type So
      WHEN feature = 'FI:So' AND combined_form = 'light' AND combined_states ~ '^(.*;)?FI:Po1(;.*)?$' AND combined_states ~ '^(.*;)?FI:Eo1(;.*)?$' THEN 'fi/eo1-po1-combined-block'

      -- NL --

      -- NL departure signals
      WHEN feature IN ('NL', 'NL:VL') AND departure_form = 'light' THEN 'nl/departure'

      WHEN feature = 'NL' THEN
        CASE
          -- NL dwarf shunting signals
          WHEN shunting_form = 'light' AND main_height = 'dwarf' THEN 'nl/main_light_dwarf_shunting'

          -- NL train protection block marker light
          WHEN train_protection_form = 'light' AND train_protection_type = 'block_marker' THEN 'nl/main_light_white_bar'

          -- NL main dwarf signals
          WHEN main_height = 'dwarf' THEN 'nl/main_light_dwarf'

          -- NL main shunting light
          WHEN shunting_form = 'light' THEN 'nl/main_light_shunting'

          -- NL distant light
          WHEN distant_form = 'light' THEN 'nl/distant_light'

          -- NL main repeated light
          WHEN (main_repeated_form = 'light' OR main_repeated_states = 'NL:272;NL:273') THEN 'nl/main_repeated_light'

          -- NL (freight) speed limits
          WHEN speed_limit_form = 'light' AND speed_limit_states = 'H;off' THEN 'nl/H'
          WHEN speed_limit_form = 'light' AND speed_limit_states = 'L;off' THEN 'nl/L'
          WHEN main_form = 'light' AND speed_limit_form = 'light' THEN 'nl/main_light_speed_limit'
          WHEN distant_form = 'light' AND speed_limit_form = 'light' THEN 'nl/distant_light_speed_limit'

          -- NL main light
          WHEN main_form = 'light' THEN 'nl/main_light'
          WHEN speed_limit_form = 'light' THEN 'nl/speed_limit_light'
          ELSE ''
        END

      -- NL Humping ("heuvelen")
      WHEN feature = 'NL:270' THEN 'nl/270a'

      -- NL ATB codewissel
      WHEN feature = 'NL:330' THEN 'nl/atb-codewissel'

      -- NL train protection block markers
      WHEN feature IN ('NL:227b', 'DE-ESO:ne14') AND train_protection_form = 'sign' AND train_protection_type = 'block_marker' THEN
        CASE
          WHEN feature = 'NL:227b' AND train_protection_shape = 'triangle' THEN 'general/etcs-stop-marker-arrow-left'
          ELSE 'general/etcs-stop-marker-triangle-left'
        END

      ELSE ''
    END as feature,
    azimuth
  FROM pre_signals
  WHERE feature IS NOT NULL AND feature != ''
  ORDER BY rank NULLS FIRST;

--- Electrification ---

CREATE OR REPLACE VIEW electrification_railway_line AS
  SELECT
    way,
    railway,
    usage,
    service,
    CASE
      WHEN railway = 'construction' THEN construction_railway
      ELSE railway
    END as feature,
    CASE
      WHEN railway = 'rail' AND usage IN ('tourism', 'military', 'test') AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service = 'siding' THEN 870
      WHEN railway = 'rail' AND usage IS NULL AND service = 'yard' THEN 860
      WHEN railway = 'rail' AND usage IS NULL AND service = 'spur' THEN 880
      WHEN railway = 'rail' AND usage IS NULL AND service = 'crossover' THEN 300
      WHEN railway = 'rail' AND usage = 'main' AND service IS NULL THEN 1100
      WHEN railway = 'rail' AND usage = 'branch' AND service IS NULL THEN 1000
      WHEN railway = 'rail' AND usage = 'industrial' AND service IS NULL THEN 850
      WHEN railway = 'rail' AND usage = 'industrial' AND service IN ('siding', 'spur', 'yard', 'crossover') THEN 850
      WHEN railway IN ('preserved', 'construction') THEN 400
      ELSE 50
    END AS rank,
    electrification_state_without_future AS electrification_state,
    railway_voltage_for_state(electrification_state_without_future, voltage, construction_voltage, proposed_voltage) AS voltage,
    railway_frequency_for_state(electrification_state_without_future, frequency, construction_frequency, proposed_frequency) AS frequency,
    label
  FROM
    (SELECT
       way,
       railway,
       usage,
       service,
       construction_railway,
       railway_electrification_state(railway, electrified, deelectrified, abandoned_electrified, NULL, NULL, true) AS electrification_state_without_future,
       railway_electrification_label(electrified, deelectrified, construction_electrified, proposed_electrified, voltage, frequency, construction_voltage, construction_frequency, proposed_voltage, proposed_frequency) AS label,
       frequency,
       voltage,
       construction_frequency,
       construction_voltage,
       proposed_frequency,
       proposed_voltage,
       layer
     FROM railway_line
     WHERE railway IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'construction', 'preserved')
    ) AS r
  ORDER BY
    layer,
    rank NULLS LAST;

CREATE OR REPLACE VIEW electrification_future AS
  SELECT
    way,
    railway,
    usage,
    service,
    CASE
      WHEN railway = 'construction' THEN construction_railway
      ELSE railway
    END as feature,
    CASE
      WHEN railway = 'rail' AND usage IN ('tourism', 'military', 'test') AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service = 'siding' THEN 870
      WHEN railway = 'rail' AND usage IS NULL AND service = 'yard' THEN 860
      WHEN railway = 'rail' AND usage IS NULL AND service = 'spur' THEN 880
      WHEN railway = 'rail' AND usage IS NULL AND service = 'crossover' THEN 300
      WHEN railway = 'rail' AND usage = 'main' AND service IS NULL THEN 1100
      WHEN railway = 'rail' AND usage = 'branch' AND service IS NULL THEN 1000
      WHEN railway = 'rail' AND usage = 'industrial' AND service IS NULL THEN 850
      WHEN railway = 'rail' AND usage = 'industrial' AND service IN ('siding', 'spur', 'yard', 'crossover') THEN 850
      WHEN railway IN ('preserved', 'construction') THEN 400
      ELSE 50
    END AS rank,
    electrification_state,
    railway_voltage_for_state(electrification_state, voltage, construction_voltage, proposed_voltage) AS voltage,
    railway_frequency_for_state(electrification_state, frequency, construction_frequency, proposed_frequency) AS frequency
  FROM
    (SELECT
       way,
       railway,
       usage,
       service,
       construction_railway,
       railway_electrification_state(railway, electrified, deelectrified, abandoned_electrified, construction_electrified, proposed_electrified, false) AS electrification_state,
       frequency,
       voltage,
       construction_frequency,
       construction_voltage,
       proposed_frequency,
       proposed_voltage,
       layer
     FROM railway_line
     WHERE railway IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'construction', 'preserved')
    ) AS r
  ORDER BY
    layer,
    rank NULLS LAST;

CREATE OR REPLACE VIEW electrification_signals AS
  SELECT
    way,
    CASE
      {% for feature in electrification_signals.features %}
        -- ({% feature.country %}) {% feature.description %}
        WHEN{% for tag in feature.tags %} "{% tag.tag %}"{% if tag.value %}='{% tag.value %}'{% elif tag.values %} IN ({% for value in tag.values %}{% unless loop.first %}, {% end %}'{% value %}'{% end %}){% end %}{% unless loop.last %} AND{% end %}{% end %}

          THEN {% if feature.icon.match %} CASE
            {% for case in feature.icon.cases %}
            WHEN "{% feature.icon.match %}"{% if case.null %} IS NULL{% else %} ~ '{% case.regex %}'{% end %} THEN '{% case.value %}'
{% end %}
            ELSE '{% feature.icon.default %}'
          END{% else %} '{% feature.icon.default %}'{% end %}


{% end %}
    END as feature,
    azimuth
  FROM signals_with_azimuth
  WHERE
    railway = 'signal'
    AND signal_direction IS NOT NULL
    AND "railway:signal:electricity" IS NOT NULL;

--- Gauge ---

CREATE OR REPLACE VIEW gauge_railway_line_low AS
  SELECT
    way,
    railway,
    usage,
    railway as feature,
    NULL AS service,
    railway_to_int(gauge) AS gaugeint0,
    gauge as gauge0
  FROM
    (SELECT
       way,
       railway,
       usage,
       railway_desired_value_from_list(1, gauge) AS gauge,
       layer
     FROM railway_line
     WHERE railway = 'rail' AND usage = 'main' AND service IS NULL
    ) AS r
  ORDER BY layer NULLS LAST;

CREATE OR REPLACE VIEW gauge_railway_line AS
  SELECT
    way,
    railway,
    usage,
    service,
    CASE
      WHEN railway = 'construction' THEN construction_railway
      WHEN railway = 'preserved' THEN preserved_railway
      ELSE railway
    END as feature,
    CASE
      WHEN railway = 'rail' AND usage IN ('tourism', 'military', 'test') AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service IS NULL THEN 400
      WHEN railway = 'rail' AND usage IS NULL AND service = 'siding' THEN 870
      WHEN railway = 'rail' AND usage IS NULL AND service = 'yard' THEN 860
      WHEN railway = 'rail' AND usage IS NULL AND service = 'spur' THEN 880
      WHEN railway = 'rail' AND usage IS NULL AND service = 'crossover' THEN 300
      WHEN railway = 'rail' AND usage = 'main' AND service IS NULL THEN 1100
      WHEN railway = 'rail' AND usage = 'branch' AND service IS NULL THEN 1000
      WHEN railway = 'rail' AND usage = 'industrial' AND service IS NULL THEN 850
      WHEN railway = 'rail' AND usage = 'industrial' AND service IN ('siding', 'spur', 'yard', 'crossover') THEN 850
      WHEN railway IN ('preserved', 'construction') THEN 400
      ELSE 50
    END AS rank,
    railway_to_int(gauge0) AS gaugeint0,
    gauge0,
    railway_to_int(gauge1) AS gaugeint1,
    gauge1,
    railway_to_int(gauge2) AS gaugeint2,
    gauge2,
    label
  FROM
    (SELECT
       way,
       railway,
       usage,
       service,
       construction_railway,
       preserved_railway,
       railway_desired_value_from_list(1, COALESCE(gauge, construction_gauge)) AS gauge0,
       railway_desired_value_from_list(2, COALESCE(gauge, construction_gauge)) AS gauge1,
       railway_desired_value_from_list(3, COALESCE(gauge, construction_gauge)) AS gauge2,
       railway_gauge_label(gauge) AS label,
       layer
     FROM railway_line
     WHERE railway IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'construction', 'preserved', 'monorail', 'miniature')
    ) AS r
  ORDER BY
    layer,
    rank NULLS LAST;
