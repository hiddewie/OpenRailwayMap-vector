
CREATE OR REPLACE VIEW signal_direction_view AS
  SELECT
    s.osm_id as signal_id,
    (signal_direction = 'both') as direction_both,
    degrees(ST_Azimuth(
      st_lineinterpolatepoint(sl.way, greatest(0, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) - 0.01)),
      st_lineinterpolatepoint(sl.way, least(1, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) + 0.01))
    )) + (CASE WHEN signal_direction = 'backward' THEN 180.0 ELSE 0.0 END) as azimuth
  FROM signals s
  LEFT JOIN LATERAL (
    SELECT line.way as way
    FROM railway_line line
    WHERE st_dwithin(s.way, line.way, 10) AND line.feature IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'monorail', 'miniature', 'funicular')
    ORDER BY s.way <-> line.way
    LIMIT 1
  ) as sl ON true
  WHERE
    (railway IN ('signal', 'buffer_stop') AND signal_direction IS NOT NULL)
      OR railway IN ('derail', 'vacancy_detection');

-- Use the view directly such that the query in the view can be updated
CREATE MATERIALIZED VIEW IF NOT EXISTS signal_direction AS
  SELECT
    *
  FROM
    signal_direction_view;

CREATE INDEX IF NOT EXISTS signal_direction_signal_id_index
  ON signal_direction
    USING btree(signal_id);

CLUSTER signal_direction
  USING signal_direction_signal_id_index;
    
-- Table with functional signal features
CREATE OR REPLACE VIEW signal_features_view AS
  -- For every type of signal, generate the feature and related metadata
  WITH signals_with_features_0 AS (
    SELECT
      osm_id as signal_id,
      railway,
      
      CASE 
        WHEN "railway:signal:main" IS NOT NULL THEN
          CASE 
            -- (AT) Main entry sign Ne 1
            WHEN "railway:signal:main" = 'AT-V2:trapeztafel' AND "railway:signal:main:form" = 'sign'
              THEN array_cat(ARRAY['at/trapeztafel', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '4'])
            
            -- (AT) Hauptsignal (abfahrt)
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND "railway:signal:departure" = 'AT-V2:abfahrt' AND "railway:signal:departure:form" = 'light'
              THEN array_cat(ARRAY['at/hauptsignal-abfahrt', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '14'])
            
            -- (AT) Hauptsignal (semaphore)
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'semaphore'
              THEN array_cat(CASE 
                    WHEN ARRAY['AT-V2:frei_mit_40', 'AT-V2:frei_mit_20'] && "railway:signal:main:states" THEN ARRAY['at/hauptsignal-frei_mit_40-semaphore', NULL, '20', '0', '0']
                    WHEN 'AT-V2:frei' = ANY("railway:signal:main:states") THEN ARRAY['at/hauptsignal-frei-semaphore', NULL, '22', '0', '0']
                    ELSE ARRAY['at/hauptsignal-semaphore', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '15'])
            
            -- (AT) Hauptsignal mit verschubsignal & ersatzsignal
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND 'AT-V2:ersatzsignal' = ANY("railway:signal:main:substitute_signal") AND "railway:signal:shunting" = 'AT-V2:verschubsignal' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['at/hauptsignal-verschubsignal-ersatzsignal', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '16'])
            
            -- (AT) Hauptsignal mit verschubsignal & vorsichtssignal
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND 'AT-V2:vorsichtssignal' = ANY("railway:signal:main:substitute_signal") AND "railway:signal:shunting" = 'AT-V2:verschubsignal' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['at/hauptsignal-verschubsignal-vorsichtssignal', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '17'])
            
            -- (AT) Hauptsignal mit verschubsignal
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND "railway:signal:shunting" = 'AT-V2:verschubsignal' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['at/hauptsignal-verschubsignal', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '18'])
            
            -- (AT) Hauptsignal mit ersatzsignal (light)
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND 'AT-V2:ersatzsignal' = ANY("railway:signal:main:substitute_signal")
              THEN array_cat(CASE 
                    WHEN 'AT-V2:frei_mit_60' = ANY("railway:signal:main:states") THEN ARRAY['at/hauptsignal-ersatzsignal-frei-mit-60', NULL, '22', '0', '0']
                    WHEN ARRAY['AT-V2:frei_mit_20', 'AT-V2:frei_mit_40'] && "railway:signal:main:states" THEN ARRAY['at/hauptsignal-ersatzsignal-frei-mit-40', NULL, '22', '0', '0']
                    WHEN 'AT-V2:frei' = ANY("railway:signal:main:states") THEN ARRAY['at/hauptsignal-ersatzsignal-frei', NULL, '22', '0', '0']
                    ELSE ARRAY['at/hauptsignal-ersatzsignal-halt', NULL, '22', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '19'])
            
            -- (AT) Hauptsignal mit vorsichtssignal (light)
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND 'AT-V2:vorsichtssignal' = ANY("railway:signal:main:substitute_signal")
              THEN array_cat(CASE 
                    WHEN 'AT-V2:frei_mit_60' = ANY("railway:signal:main:states") THEN ARRAY['at/hauptsignal-vorsichtssignal-frei-mit-60', NULL, '22', '0', '0']
                    WHEN ARRAY['AT-V2:frei_mit_20', 'AT-V2:frei_mit_40'] && "railway:signal:main:states" THEN ARRAY['at/hauptsignal-vorsichtssignal-frei-mit-40', NULL, '22', '0', '0']
                    WHEN 'AT-V2:frei' = ANY("railway:signal:main:states") THEN ARRAY['at/hauptsignal-vorsichtssignal-frei', NULL, '22', '0', '0']
                    ELSE ARRAY['at/hauptsignal-vorsichtssignal-halt', NULL, '22', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '20'])
            
            -- (AT) Hauptsignal (light)
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'AT-V2:frei_mit_60' = ANY("railway:signal:main:states") THEN ARRAY['at/hauptsignal-frei-mit-60', NULL, '22', '0', '0']
                    WHEN ARRAY['AT-V2:frei_mit_20', 'AT-V2:frei_mit_40'] && "railway:signal:main:states" THEN ARRAY['at/hauptsignal-frei-mit-40', NULL, '22', '0', '0']
                    WHEN 'AT-V2:frei' = ANY("railway:signal:main:states") THEN ARRAY['at/hauptsignal-frei', NULL, '22', '0', '0']
                    ELSE ARRAY['at/hauptsignal-halt', NULL, '22', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '21'])
            
            -- (AU) Point Position Indicator
            WHEN "railway:signal:main" = 'AU:MNWSW:points_indiciator' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/metro/points_indiciator', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '67'])
            
            -- (AU) Ground Signal
            WHEN "railway:signal:main" = 'AU:LightRail:NSW:ground' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'stop' = ANY("railway:signal:main:states") THEN ARRAY['au/LightRail/signals/ground-stop', NULL, '9', '0', '0']
                    ELSE ARRAY['au/LightRail/signals/ground-clear', NULL, '9', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '109'])
            
            -- (AU) Signal
            WHEN "railway:signal:main" = 'AU:LightRail:NSW:SI' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/LightRail/signals/NSW_SI', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '110'])
            
            -- (AU) Points Indicator
            WHEN "railway:signal:main" = 'AU:LightRail:NSW:PI' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/LightRail/signals/NSW_PI', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '111'])
            
            -- (AU) Signal System Lanterns
            WHEN "railway:signal:main" = 'AU:LightRail:SI' AND "railway:signal:main:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN 'stop' = ANY("railway:signal:main:states") THEN ARRAY['au/LightRail/signals/SI/stop@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'straight' = ANY("railway:signal:main:states") THEN ARRAY['au/LightRail/signals/SI/straight@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'right' = ANY("railway:signal:main:states") THEN ARRAY['au/LightRail/signals/SI/right@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'left' = ANY("railway:signal:main:states") THEN ARRAY['au/LightRail/signals/SI/left@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'error' = ANY("railway:signal:main:states") THEN ARRAY['au/LightRail/signals/SI/error@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'warning' = ANY("railway:signal:main:states") THEN ARRAY['au/LightRail/signals/SI/warning@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '114'])
            
            -- (AU) Main Signal (searchlight)
            WHEN "railway:signal:main" = 'AU:NSW:main' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'searchlight'
              THEN array_cat(CASE 
                    WHEN 'GYR' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/searchlight/GYR', NULL, '9', '0', '0']
                    WHEN 'GR' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/searchlight/GR', NULL, '9', '0', '0']
                    WHEN 'YR' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/searchlight/YR', NULL, '9', '0', '0']
                    WHEN 'R' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/searchlight/R', NULL, '9', '0', '0']
                    WHEN 'G' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/searchlight/G', NULL, '9', '0', '0']
                    ELSE ARRAY['au/nsw/signals/main/searchlight/unknown', NULL, '9', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '169'])
            
            -- (AU) Main Signal
            WHEN "railway:signal:main" = 'AU:NSW:main' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'GYR' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/multi-unit/GYR', NULL, '21', '0', '0']
                    WHEN 'GR' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/multi-unit/GR', NULL, '15', '0', '0']
                    WHEN 'YR' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/multi-unit/YR', NULL, '15', '0', '0']
                    WHEN 'R' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/multi-unit/R', NULL, '9', '0', '0']
                    WHEN 'G' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/multi-unit/G', NULL, '9', '0', '0']
                    ELSE ARRAY['au/nsw/signals/main/multi-unit/unknown', NULL, '15', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '170'])
            
            -- (AU) Main Signal (semaphore)
            WHEN "railway:signal:main" = 'AU:NSW:main' AND "railway:signal:main:form" = 'semaphore'
              THEN array_cat(CASE 
                    WHEN 'GYR' = ANY("railway:signal:main:states") THEN ARRAY['au/nsw/signals/main/semaphore/GYR', NULL, '22', '0', '0']
                    WHEN ARRAY['GR', 'G', 'R'] && "railway:signal:main:states" THEN ARRAY['au/nsw/signals/main/semaphore/GR', NULL, '19.568293', '0', '0']
                    ELSE ARRAY['au/nsw/signals/main/semaphore/unknown', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '171'])
            
            -- (AU) 3-position main signal (dwarf-height, permissive)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:height" = 'dwarf' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'auto'
              THEN array_cat(ARRAY['au/vic/signals/main/main_dwarf_staggered', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '204'])
            
            -- (AU) 3-position main signal (dwarf-height, absolute)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:height" = 'dwarf' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/main/main_dwarf', NULL, '23', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '205'])
            
            -- (AU) 3-position main signal (multi-unit over multi-unit, permissive)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '33' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'auto'
              THEN array_cat(ARRAY['au/vic/signals/main/main_33_staggered', NULL, '49', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '206'])
            
            -- (AU) 3-position main signal (multi-unit over multi-unit, absolute)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '33' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/main/main_33', NULL, '49', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '207'])
            
            -- (AU) 3-position main signal (multi-unit over multi-unit, permissive)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '32' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'auto'
              THEN array_cat(ARRAY['au/vic/signals/main/main_32_staggered', NULL, '40', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '208'])
            
            -- (AU) 3-position main signal (multi-unit over multi-unit, absolute)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '32' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/main/main_32', NULL, '43', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '209'])
            
            -- (AU) 3-position main signal (multi-unit over single-light, permissive)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '31' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'auto'
              THEN array_cat(ARRAY['au/vic/signals/main/main_31_staggered', NULL, '33', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '210'])
            
            -- (AU) 3-position main signal (multi-unit over single-light, absolute)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '31' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/main/main_31', NULL, '33', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '211'])
            
            -- (AU) 3-position main signal (multi-unit over single-light, permissive)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '22' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'auto'
              THEN array_cat(ARRAY['au/vic/signals/main/main_22_staggered', NULL, '34', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '212'])
            
            -- (AU) 3-position main signal (multi-unit over single-light, absolute)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '22' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/main/main_22', NULL, '38', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '213'])
            
            -- (AU) 3-position main signal (single-light over multi-unit, permissive)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '13' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'auto'
              THEN array_cat(ARRAY['au/vic/signals/main/main_13_staggered', NULL, '33', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '214'])
            
            -- (AU) 3-position main signal (single-light over multi-unit, absolute)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '13' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/main/main_13', NULL, '33', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '215'])
            
            -- (AU) 3-position main signal (single-light over 2-aspect multi-unit, permissive)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '12' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'auto'
              THEN array_cat(ARRAY['au/vic/signals/main/main_12_staggered', NULL, '29', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '216'])
            
            -- (AU) 3-position main signal (single-light over 2-aspect multi-unit, absolute)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '12' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/main/main_12', NULL, '29', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '217'])
            
            -- (AU) 3-position main signal (single-light over single-light, permissive)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '11' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'auto'
              THEN array_cat(ARRAY['au/vic/signals/main/main_11_staggered', NULL, '23.75', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '218'])
            
            -- (AU) 3-position main signal (single-light over single-light, absolute)
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '11' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/main/main_11', NULL, '23.75', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '219'])
            
            -- (AU) 2-position main signal
            WHEN "railway:signal:main" = 'AU:VIC:main' AND "railway:signal:main:type" = '2' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/main/main_2', NULL, '18.5', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '220'])
            
            -- (BE) Grand Signal d'Arrêt (opposite regime and only for shunting)
            WHEN "railway:signal:main" = 'BE:GSA' AND "railway:signal:regime" = 'opposite' AND ARRAY['BE:RB', 'BE:R'] <@ "railway:signal:main:states" AND ARRAY['BE:RB', 'BE:R'] @> "railway:signal:main:states" AND "railway:signal:traversable" = 'BE:TR'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['be/GSA-opposite-RB', NULL, '22.253976', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'BE:OF' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['be/OEF@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT ARRAY['be/TR@bottom', NULL, '0', '14', '0'] as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '234'])
            
            -- (BE) Grand Signal d'Arrêt (normal regime and only for shunting)
            WHEN "railway:signal:main" = 'BE:GSA' AND ARRAY['BE:RB', 'BE:R'] <@ "railway:signal:main:states" AND ARRAY['BE:RB', 'BE:R'] @> "railway:signal:main:states" AND "railway:signal:traversable" = 'BE:TR'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['be/GSA-RB', NULL, '22.253976', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'BE:OF' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['be/OEF@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT ARRAY['be/TR@bottom', NULL, '0', '14', '0'] as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '235'])
            
            -- (BE) Grand Signal d'Arrêt (opposite regime)
            WHEN "railway:signal:main" = 'BE:GSA' AND "railway:signal:regime" = 'opposite'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:traversable" = 'BE:TR' THEN ARRAY['be/GSA-opposite-R', NULL, '22.253976', '0', '0']
                    WHEN "railway:signal:traversable" = 'BE:DBR' THEN ARRAY['be/GSA-opposite-V', NULL, '22.253976', '0', '0']
                    WHEN "railway:signal:traversable" = 'BE:CF' THEN ARRAY['be/GSA-opposite-V', NULL, '22.253976', '0', '0']
                    ELSE ARRAY['be/GSA-opposite-R', NULL, '22.253976', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'BE:OF' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['be/OEF@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:traversable" = 'BE:CF' THEN ARRAY['be/CF@bottom', NULL, '0', '10', '0']
                    WHEN "railway:signal:traversable" = 'BE:DBR' THEN ARRAY['be/DBR@bottom', NULL, '0', '14', '0']
                    WHEN "railway:signal:traversable" = 'BE:TR' THEN ARRAY['be/TR@bottom', NULL, '0', '14', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '236'])
            
            -- (BE) Grand Signal d'Arrêt (normal regime)
            WHEN "railway:signal:main" = 'BE:GSA'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:traversable" = 'BE:TR' THEN ARRAY['be/GSA-R', NULL, '22.253976', '0', '0']
                    WHEN "railway:signal:traversable" = 'BE:DBR' THEN ARRAY['be/GSA-V', NULL, '22.253976', '0', '0']
                    WHEN "railway:signal:traversable" = 'BE:CF' THEN ARRAY['be/GSA-V', NULL, '22.253976', '0', '0']
                    ELSE ARRAY['be/GSA-R', NULL, '22.253976', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'BE:OF' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['be/OEF@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:traversable" = 'BE:CF' THEN ARRAY['be/CF@bottom', NULL, '0', '10', '0']
                    WHEN "railway:signal:traversable" = 'BE:DBR' THEN ARRAY['be/DBR@bottom', NULL, '0', '14', '0']
                    WHEN "railway:signal:traversable" = 'BE:TR' THEN ARRAY['be/TR@bottom', NULL, '0', '14', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '237'])
            
            -- (BE) (BME) Approach (semaphore)
            WHEN "railway:signal:main" = 'BE-SME:simplified_stop_signal' AND "railway:signal:main:form" = 'semaphore'
              THEN array_cat(ARRAY['be/bme/semaphore_approach', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '240'])
            
            -- (BE) (BME) Simplified main signal
            WHEN "railway:signal:main" = 'BE-SME:simplified_stop_signal'
              THEN array_cat(CASE 
                    WHEN 'BE-SME:W' = ANY("railway:signal:main:states") THEN ARRAY['be/bme/simplified_xnw', NULL, '20', '0', '0']
                    WHEN 'BE-SME:N' = ANY("railway:signal:main:states") THEN ARRAY['be/bme/simplified_ny', NULL, '20', '0', '0']
                    ELSE ARRAY['be/bme/simplified_unknown', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '241'])
            
            -- (CA) Main signal
            WHEN "railway:signal:main" = 'CA:main' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['ca/main', NULL, '21.234008', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '266'])
            
            -- (CH) Hauptsignal System L
            WHEN "railway:signal:main" = 'CH-FDV:l' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'CH-FDV:550' = ANY("railway:signal:main:states") THEN ARRAY['ch/fdv-l-550', NULL, '29.651538', '0', '0']
                    WHEN 'CH-FDV:547' = ANY("railway:signal:main:states") THEN ARRAY['ch/fdv-l-547', NULL, '29.651538', '0', '0']
                    WHEN 'CH-FDV:542' = ANY("railway:signal:main:states") THEN ARRAY['ch/fdv-l-542', NULL, '29.651538', '0', '0']
                    WHEN 'CH-FDV:545' = ANY("railway:signal:main:states") THEN ARRAY['ch/fdv-l-545', NULL, '29.651538', '0', '0']
                    WHEN 'CH-FDV:530' = ANY("railway:signal:main:states") THEN ARRAY['ch/fdv-l-530', NULL, '29.651538', '0', '0']
                    ELSE ARRAY['ch/fdv-l-524', NULL, '29.651538', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '267'])
            
            -- (CZ) Návěst stůj
            WHEN "railway:signal:main" = 'CZ-D1:stuj' AND "railway:signal:main:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:main:shape" = 'circle' THEN ARRAY['cz/stuj/circle', NULL, '15', '0', '0']
                    ELSE ARRAY['cz/stuj/rectangle', NULL, '10.5', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '326'])
            
            -- (CZ) Hlavní návěstidlo
            WHEN "railway:signal:main" IN ('CZ', 'CZ-D1:hlavni_navestidlo') AND "railway:signal:main:form" = 'light' AND "railway:signal:speed_limit" IN ('CZ', 'CZ-D1:hlavni_navestidlo')
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:volno'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GRWY-GY', NULL, '24.75', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo/GRWY-GY', NULL, '24.75', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'CZ-D1:rychlost_30' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_30-sign@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_50' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_50-sign@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_60' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_60@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_80' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_80@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_100' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_100@bottom', NULL, '0', '11.999977', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '330'])
            
            -- (CZ) Hlavní návěstidlo
            WHEN "railway:signal:main" IN ('CZ', 'CZ-D1:hlavni_navestidlo') AND "railway:signal:main:form" = 'light' AND ARRAY['yes', 'CZ-D1:privolavaci_navest'] && "railway:signal:main:substitute_signal"
              THEN array_cat(CASE 
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:volno'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GRW-G', NULL, '19.5', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:jizda_vlaku_dovolena'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/RBW-B', NULL, '19.5', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/RW-R', NULL, '14.25', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo/GRW-G', NULL, '19.5', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '331'])
            
            -- (CZ) Hlavní návěstidlo
            WHEN "railway:signal:main" IN ('CZ', 'CZ-D1:hlavni_navestidlo', 'Cs-D1', 'Cs-D1:', 'Cs-D1:_') AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:volno', 'CZ-D1:posun_dovolen'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GRW-G', NULL, '19.5', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:volno'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GR-G', NULL, '14.25', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:jizda_vlaku_dovolena', 'CZ-D1:posun_dovolen'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/RBW-B', NULL, '19.5', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:posun_dovolen'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/RW-R', NULL, '14.25', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/R-R', NULL, '9', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'call_signal', 'speed_limit'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YGRWY-YY', NULL, '30', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'call_signal'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YGRW-Y', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'shunting_enabled', 'speed_limit'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YGRWY-YY', NULL, '30', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'shunting_enabled'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YGRW-Y', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'speed_limit'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YGRY-YY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YGR-Y', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'call_signal', 'speed_limit'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YRWY-YY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'call_signal'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YRW-Y', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'shunting_enabled', 'speed_limit'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YRWY-YY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'shunting_enabled'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YRW-Y', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'speed_limit'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YRY-YY', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'approach'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/YR-Y', NULL, '14.25', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'call_signal', 'speed_limit'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GRWY-GY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'call_signal'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GRW-G', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'shunting_enabled', 'speed_limit'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GRWY-GY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'shunting_enabled'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GRW-G', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'speed_limit'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GRY-GY', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'clear'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GR-G', NULL, '14.25', '0', '0']
                    WHEN ARRAY['stop', 'shunting_enabled'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/RW-R', NULL, '14.25', '0', '0']
                    WHEN ARRAY['stop'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/R-R', NULL, '9', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo/GR-G', NULL, '14.25', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '332'])
            
            -- (DE) main entry sign Ne 1
            WHEN "railway:signal:main" = 'DE-ESO:ne1' AND "railway:signal:main:form" = 'sign'
              THEN array_cat(ARRAY['de/ne1', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '446'])
            
            -- (DE) main semaphore signals type Hp
            WHEN "railway:signal:main" = 'DE-ESO:hp' AND "railway:signal:main:form" = 'semaphore'
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:hp2' = ANY("railway:signal:main:states") THEN ARRAY['de/hp2-semaphore', NULL, '20', '0', '0']
                    WHEN 'DE-ESO:hp1' = ANY("railway:signal:main:states") THEN ARRAY['de/hp1-semaphore', NULL, '19', '0', '0']
                    ELSE ARRAY['de/hp0-semaphore', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '447'])
            
            -- (DE) main light signals type Hp
            WHEN "railway:signal:main" = 'DE-ESO:hp' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:hp2' = ANY("railway:signal:main:states") THEN ARRAY['de/hp2-light', NULL, '16', '0', '0']
                    WHEN 'DE-ESO:hp1' = ANY("railway:signal:main:states") THEN ARRAY['de/hp1-light', NULL, '16', '0', '0']
                    ELSE ARRAY['de/hp0-light', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '448'])
            
            -- (DE) main light signals type Hl
            WHEN "railway:signal:main" = 'DE-ESO:hl' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:hl2' = ANY("railway:signal:main:states") THEN ARRAY['de/hl2', NULL, '25.3475', '0', '0']
                    WHEN 'DE-ESO:hl3b' = ANY("railway:signal:main:states") THEN ARRAY['de/hl3b', NULL, '25.3475', '0', '0']
                    WHEN 'DE-ESO:hl3a' = ANY("railway:signal:main:states") THEN ARRAY['de/hl3a', NULL, '18.296614', '0', '0']
                    WHEN 'DE-ESO:hl1' = ANY("railway:signal:main:states") THEN ARRAY['de/hl1', NULL, '18.296614', '0', '0']
                    ELSE ARRAY['de/hl0-main', NULL, '18.296614', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '449'])
            
            -- (DE) tram Fahrsignal
            WHEN "railway:signal:main" IN ('DE-AVG:f', 'DE-BOStrab:f') AND "railway:signal:crossing" = 'DE-DVB:so25' AND "railway:signal:main:form" = 'light' AND ARRAY['DE-BOStrab:f0', 'DE-BOStrab:f1', 'DE-BOStrab:f2', 'DE-BOStrab:f3', 'DE-BOStrab:f4', 'DE-BOStrab:f5', 'DE-AVG:f0', 'DE-AVG:f1', 'DE-AVG:f2', 'DE-AVG:f3', 'DE-AVG:f4', 'DE-AVG:f5'] && "railway:signal:main:states"
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:main:PT_priority" = 'requested;off' THEN ARRAY['de/bostrab/st9@bottom', NULL, '0', '10.066964', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f0', 'DE-BOStrab:f0'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f0@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f4', 'DE-BOStrab:f4'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f4@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f1', 'DE-BOStrab:f1'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f1@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f2', 'DE-BOStrab:f2'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f2@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f3', 'DE-BOStrab:f3'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f3@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f5', 'DE-BOStrab:f5'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f5@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '?' = ANY("railway:signal:main:states") THEN ARRAY['de/bostrab/fahrsignal-empty@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:crossing" = 'DE-DVB:so25' THEN ARRAY['de/dvb/so25@center', NULL, '24', '0', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '450'])
            
            -- (DE) tram Fahrsignal
            WHEN "railway:signal:main" IN ('DE-AVG:f', 'DE-BOStrab:f') AND "railway:signal:main:form" = 'light' AND ARRAY['DE-BOStrab:f0', 'DE-BOStrab:f1', 'DE-BOStrab:f2', 'DE-BOStrab:f3', 'DE-BOStrab:f4', 'DE-BOStrab:f5', 'DE-AVG:f0', 'DE-AVG:f1', 'DE-AVG:f2', 'DE-AVG:f3', 'DE-AVG:f4', 'DE-AVG:f5'] && "railway:signal:main:states"
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:main:PT_priority" = 'requested;off' THEN ARRAY['de/bostrab/st9@bottom', NULL, '0', '10.066964', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f0', 'DE-BOStrab:f0'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f0@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f4', 'DE-BOStrab:f4'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f4@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f1', 'DE-BOStrab:f1'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f1@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f2', 'DE-BOStrab:f2'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f2@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f3', 'DE-BOStrab:f3'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f3@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['DE-AVG:f5', 'DE-BOStrab:f5'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f5@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '?' = ANY("railway:signal:main:states") THEN ARRAY['de/bostrab/fahrsignal-empty@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '451'])
            
            -- (DE) tram Fahrsignal (aspects unknown)
            WHEN "railway:signal:main" IN ('DE-AVG:f', 'DE-BOStrab:f') AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['de/bostrab/f0-old', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '452'])
            
            -- (DE) tram Fahrsignal (sign)
            WHEN "railway:signal:main" IN ('DE-AVG:f', 'DE-BOStrab:f') AND "railway:signal:main:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN ARRAY['DE-AVG:f5', 'DE-BOStrab:f5'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f5-sign', NULL, '10', '0', '0']
                    WHEN ARRAY['DE-AVG:f3', 'DE-BOStrab:f3'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f3-sign', NULL, '10', '0', '0']
                    WHEN ARRAY['DE-AVG:f2', 'DE-BOStrab:f2'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f2-sign', NULL, '10', '0', '0']
                    WHEN ARRAY['DE-AVG:f1', 'DE-BOStrab:f1'] && "railway:signal:main:states" THEN ARRAY['de/bostrab/f1-sign', NULL, '10', '0', '0']
                    ELSE ARRAY['de/bostrab/f0-sign', NULL, '10', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '453'])
            
            -- (DE) BOStrab Hauptsignal
            WHEN "railway:signal:main" = 'DE-BOStrab:h' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-BOStrab:h2' = ANY("railway:signal:main:states") THEN ARRAY['de/bostrab/h2', NULL, '21', '0', '0']
                    WHEN 'DE-BOStrab:h1' = ANY("railway:signal:main:states") THEN ARRAY['de/bostrab/h1', NULL, '21', '0', '0']
                    WHEN 'DE-VAGN:hp2' = ANY("railway:signal:main:states") THEN ARRAY['de/vag-nuremberg/hp2', NULL, '21', '0', '0']
                    WHEN 'DE-VAGN:hp1' = ANY("railway:signal:main:states") THEN ARRAY['de/vag-nuremberg/hp1', NULL, '21', '0', '0']
                    WHEN ARRAY['DE-VAGN:hp0', 'off'] <@ "railway:signal:main:states" THEN ARRAY['de/vag-nuremberg/off', NULL, '21', '0', '0']
                    WHEN 'DE-VAGN:hp3' = ANY("railway:signal:main:states") THEN ARRAY['de/vag-nuremberg/hp3', NULL, '21', '0', '0']
                    WHEN 'DE-VAGN:hp0' = ANY("railway:signal:main:states") THEN ARRAY['de/vag-nuremberg/hp0', NULL, '21', '0', '0']
                    ELSE ARRAY['de/bostrab/h0', NULL, '21', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '454'])
            
            -- (DE) Hamburger Hochbahn main signal
            WHEN "railway:signal:main" = 'DE-HHA:h' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-HHA:h1' = ANY("railway:signal:main:states") THEN ARRAY['de/hha/h1', NULL, '16', '0', '0']
                    ELSE ARRAY['de/hha/h0', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '455'])
            
            -- (DE) main signals type Ks
            WHEN "railway:signal:main" = 'DE-ESO:ks' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['de/ks-main', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '456'])
            
            -- (DE) main signals type Sk
            WHEN "railway:signal:main" = 'DE-ESO:sk' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['de/sk1-light', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '460'])
            
            -- (DK) Perronudkørselssignal
            WHEN "railway:signal:main" = 'DK-SR:PU' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['dk/main-PU', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '511'])
            
            -- (DK) Stationsbloksignal for Udkørsel
            WHEN "railway:signal:main" = 'DK-SR:SU' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['dk/main-SU', NULL, '32', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '512'])
            
            -- (FI) Balise
            WHEN "railway:signal:main" = 'FI:Po' AND "railway:signal:main:form" = 'balise'
              THEN array_cat(ARRAY['fi/t-262', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '540'])
            
            -- (FI) main light signals (new)
            WHEN "railway:signal:main" = 'FI:Po' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'FI:Po2' = ANY("railway:signal:main:states") THEN ARRAY['fi/po2-new', NULL, '15', '0', '0']
                    WHEN 'FI:Po1' = ANY("railway:signal:main:states") THEN ARRAY['fi/po1-new', NULL, '15', '0', '0']
                    ELSE ARRAY['fi/po0-new', NULL, '15', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '541'])
            
            -- (FI) main light signals (old)
            WHEN "railway:signal:main" = 'FI:Po-v' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'FI:Po2' = ANY("railway:signal:main:states") THEN ARRAY['fi/po2-old', NULL, '16', '0', '0']
                    WHEN 'FI:Po1' = ANY("railway:signal:main:states") THEN ARRAY['fi/po1-old', NULL, '16', '0', '0']
                    ELSE ARRAY['fi/po0-old', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '542'])
            
            -- (FI) Main signal type Yo
            WHEN "railway:signal:main" = 'FI:Yo' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['fi/yo-main', NULL, '36', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '543'])
            
            -- (FR) Carré
            WHEN "railway:signal:main" IN ('FR:CARRE', 'FR:C') AND "railway:signal:main:form" = 'light' AND "railway:signal:main:height" = 'dwarf'
              THEN array_cat(ARRAY['fr/C_small-C', NULL, '8.6088', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '594'])
            
            -- (FR) Carré
            WHEN "railway:signal:main" IN ('FR:CARRE', 'FR:C') AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:C'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:M', 'FR:(M)', 'FR:Mr'] && "railway:signal:main:states" THEN ARRAY['fr/C_C-M', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/C_C-A', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/C_C-VL', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:S', 'FR:(S)', 'FR:Sc'] && "railway:signal:main:states" THEN ARRAY['fr/C_C-S', NULL, '24', '0', '0']
                    ELSE ARRAY['fr/C_C-C', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '595'])
            
            -- (FR) Carré
            WHEN "railway:signal:main" IN ('FR:CARRE', 'FR:C') AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:F'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:M', 'FR:(M)', 'FR:Mr'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-M', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-A', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-R-A', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-R', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-VL', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:S', 'FR:(S)', 'FR:Sc'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-S', NULL, '24.707', '0', '0']
                    ELSE ARRAY['fr/C_F-C', NULL, '24.707', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '596'])
            
            -- (FR) Carré
            WHEN "railway:signal:main" IN ('FR:CARRE', 'FR:C') AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:H'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:M', 'FR:(M)', 'FR:Mr'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-M', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:RR+A', 'FR:RR+(A)', 'FR:(RR)+A', 'FR:(RR)+(A)', 'FR:RR(A)', 'FR:RRc(A)', 'FR:RR(Ac)', 'FR:RRc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-RR-A', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:RR', 'FR:(RR)', 'FR:RRc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-RR', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-A', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-R-A', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-R', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-VL', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:S', 'FR:(S)', 'FR:Sc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-S', NULL, '28', '0', '0']
                    ELSE ARRAY['fr/C_H-C', NULL, '28', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '597'])
            
            -- (FR) Carré
            WHEN "railway:signal:main" IN ('FR:CARRE', 'FR:C') AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:RR+A', 'FR:RR+(A)', 'FR:(RR)+A', 'FR:(RR)+(A)', 'FR:RR(A)', 'FR:RRc(A)', 'FR:RR(Ac)', 'FR:RRc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-RR-A-2', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:RR', 'FR:(RR)', 'FR:RRc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-RR-2', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-R-A-2', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-R-2', NULL, '24.707', '0', '0']
                    ELSE ARRAY['fr/C_C-C-2', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '598'])
            
            -- (FR) Carré violet
            WHEN "railway:signal:main" = 'FR:CV' AND "railway:signal:main:form" = 'light' AND "railway:signal:position" = 'ground'
              THEN array_cat(ARRAY['fr/Cv_ground-Cv', NULL, '9.54', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '599'])
            
            -- (FR) Carré violet
            WHEN "railway:signal:main" = 'FR:CV' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:A'
              THEN array_cat(ARRAY['fr/Cv_A-Cv', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '600'])
            
            -- (FR) Carré violet
            WHEN "railway:signal:main" = 'FR:CV' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:C'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:M', 'FR:(M)', 'FR:Mr'] && "railway:signal:main:states" THEN ARRAY['fr/C_C-M-1', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/C_C-A-1', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/C_C-VL-1', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:S', 'FR:(S)', 'FR:Sc'] && "railway:signal:main:states" THEN ARRAY['fr/C_C-S-1', NULL, '24', '0', '0']
                    ELSE ARRAY['fr/C_C-Cv', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '601'])
            
            -- (FR) Carré violet
            WHEN "railway:signal:main" = 'FR:CV' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:F'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:M', 'FR:(M)', 'FR:Mr'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-M-1', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-A-1', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-R-A-1', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-R-1', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-VL-1', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:S', 'FR:(S)', 'FR:Sc'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-S-1', NULL, '24.707', '0', '0']
                    ELSE ARRAY['fr/C_F-Cv', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '602'])
            
            -- (FR) Carré violet
            WHEN "railway:signal:main" = 'FR:CV' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:H'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:M', 'FR:(M)', 'FR:Mr'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-M-1', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:RR+A', 'FR:RR+(A)', 'FR:(RR)+A', 'FR:(RR)+(A)', 'FR:RR(A)', 'FR:RRc(A)', 'FR:RR(Ac)', 'FR:RRc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-RR-A-1', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:RR', 'FR:(RR)', 'FR:RRc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-RR-1', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-A-1', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-R-A-1', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-R-1', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-VL-1', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:S', 'FR:(S)', 'FR:Sc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-S-1', NULL, '28', '0', '0']
                    ELSE ARRAY['fr/C_H-Cv', NULL, '28', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '603'])
            
            -- (FR) Carré violet
            WHEN "railway:signal:main" = 'FR:CV' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:K'
              THEN array_cat(ARRAY['fr/Cv_K-Cv', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '604'])
            
            -- (FR) Carré violet
            WHEN "railway:signal:main" = 'FR:CV' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:RR+A', 'FR:RR+(A)', 'FR:(RR)+A', 'FR:(RR)+(A)', 'FR:RR(A)', 'FR:RRc(A)', 'FR:RR(Ac)', 'FR:RRc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-RR-A-3', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:RR', 'FR:(RR)', 'FR:RRc'] && "railway:signal:main:states" THEN ARRAY['fr/C_H-RR-3', NULL, '28', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-R-A-3', NULL, '24.707', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/C_F-R-3', NULL, '24.707', '0', '0']
                    ELSE ARRAY['fr/C_C-Cv-3', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '605'])
            
            -- (FR) Sémaphore
            WHEN "railway:signal:main" = 'FR:S' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:A'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/S_A-A', NULL, '20', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/S_A-VL', NULL, '20', '0', '0']
                    ELSE ARRAY['fr/S_A-S', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '606'])
            
            -- (FR) Sémaphore
            WHEN "railway:signal:main" = 'FR:S' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:C'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/S_C-A', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/S_C-VL', NULL, '24', '0', '0']
                    ELSE ARRAY['fr/S_C-S', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '607'])
            
            -- (FR) Sémaphore
            WHEN "railway:signal:main" = 'FR:S' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:F'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/S_F-A', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/S_F-R-A', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/S_F-R', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/S_F-VL', NULL, '23.187004', '0', '0']
                    ELSE ARRAY['fr/S_F-S', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '608'])
            
            -- (FR) Sémaphore
            WHEN "railway:signal:main" = 'FR:S' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:H'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:RR+A', 'FR:RR+(A)', 'FR:(RR)+A', 'FR:(RR)+(A)', 'FR:RR(A)', 'FR:RRc(A)', 'FR:RR(Ac)', 'FR:RRc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/S_H-RR-A', NULL, '27.253745', '0', '0']
                    WHEN ARRAY['FR:RR', 'FR:(RR)', 'FR:RRc'] && "railway:signal:main:states" THEN ARRAY['fr/S_H-RR', NULL, '27.253745', '0', '0']
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/S_H-A', NULL, '27.253745', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/S_H-R-A', NULL, '27.253745', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/S_H-R', NULL, '27.253745', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/S_H-VL', NULL, '27.253745', '0', '0']
                    ELSE ARRAY['fr/S_H-S', NULL, '27.281', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '609'])
            
            -- (FR) Sémaphore
            WHEN "railway:signal:main" = 'FR:S' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'FR:K'
              THEN array_cat(ARRAY['fr/S_K-S', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '610'])
            
            -- (FR) Sémaphore
            WHEN "railway:signal:main" = 'FR:S' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:RR+A', 'FR:RR+(A)', 'FR:(RR)+A', 'FR:(RR)+(A)', 'FR:RR(A)', 'FR:RRc(A)', 'FR:RR(Ac)', 'FR:RRc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/S_H-RR-A-1', NULL, '27.253745', '0', '0']
                    WHEN ARRAY['FR:RR', 'FR:(RR)', 'FR:RRc'] && "railway:signal:main:states" THEN ARRAY['fr/S_H-RR-1', NULL, '27.253745', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/S_F-R-A-1', NULL, '24', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/S_F-R-1', NULL, '24', '0', '0']
                    ELSE ARRAY['fr/S_C-S-1', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '611'])
            
            -- (GB) Main (light)
            WHEN "railway:signal:main" = 'GB-NR:main' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN "railway:signal:main:design" = 'combined' THEN ARRAY['gb/main-combined-light', NULL, '14.173443', '0', '0']
                    ELSE ARRAY['gb/main-individual-light', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '677'])
            
            -- (GB) Main (semaphore)
            WHEN "railway:signal:main" = 'GB-NR:main' AND "railway:signal:main:form" = 'semaphore'
              THEN array_cat(ARRAY['gb/main-semaphore', NULL, '19.568293', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '678'])
            
            -- (GB) SPAD
            WHEN "railway:signal:main" = 'GB-NR:SPAD' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['gb/SPAD', NULL, '23.229401', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '679'])
            
            -- (IT) 1ª categoria (1 light)
            WHEN "railway:signal:main" = 'IT:1V' AND "railway:signal:main:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:main:shape" = 'square' THEN ARRAY['it/main-s-1v', NULL, '10', '0', '0']
                    ELSE ARRAY['it/main-1v', NULL, '9.899397', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['(Y)', 'Y'] && "railway:signal:main:states" THEN ARRAY['it/1v-Y', NULL, '9.899397', '0', '0']
                    WHEN 'G' = ANY("railway:signal:main:states") THEN ARRAY['it/1v-G', NULL, '9.899397', '0', '0']
                    ELSE ARRAY['it/1v-R', NULL, '9.899397', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['IT:AVA', 'IT:AVV'] <@ "railway:signal:main:substitute_signal" THEN ARRAY['it/AVV-AVA@bottom', NULL, '0', '11.873437', '0']
                    WHEN 'IT:AVA' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['it/AVA@bottom', NULL, '0', '5.936631', '0']
                    WHEN 'IT:AVV' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['it/AVV@bottom', NULL, '0', '5.937502', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '701'])
            
            -- (IT) 1ª categoria (2 lights)
            WHEN "railway:signal:main" = 'IT:2V' AND "railway:signal:main:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:main:shape" = 'square' THEN ARRAY['it/main-s-2v', NULL, '20', '0', '0']
                    ELSE ARRAY['it/main-2v', NULL, '19.793253', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['R-(Y)', 'R-Y'] && "railway:signal:main:states" THEN ARRAY['it/2v-RY', NULL, '19.798792', '0', '0']
                    WHEN 'R-G' = ANY("railway:signal:main:states") THEN ARRAY['it/2v-RG', NULL, '19.798792', '0', '0']
                    WHEN ARRAY['Y-G', '(Y-G)', '(Y)-(G)'] && "railway:signal:main:states" THEN ARRAY['it/2v-YG', NULL, '19.793253', '0', '0']
                    WHEN 'Y-Y' = ANY("railway:signal:main:states") THEN ARRAY['it/2v-YY', NULL, '19.798792', '0', '0']
                    WHEN ARRAY['(Y)', 'Y'] && "railway:signal:main:states" THEN ARRAY['it/2v-Y', NULL, '19.793253', '0', '0']
                    WHEN 'G' = ANY("railway:signal:main:states") THEN ARRAY['it/2v-G', NULL, '19.793253', '0', '0']
                    ELSE ARRAY['it/2v-R', NULL, '19.798792', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['IT:AVA', 'IT:AVV'] <@ "railway:signal:main:substitute_signal" THEN ARRAY['it/AVV-AVA@bottom', NULL, '0', '11.873437', '0']
                    WHEN 'IT:AVA' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['it/AVA@bottom', NULL, '0', '5.936631', '0']
                    WHEN 'IT:AVV' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['it/AVV@bottom', NULL, '0', '5.937502', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '702'])
            
            -- (IT) 1ª categoria (3 lights)
            WHEN "railway:signal:main" = 'IT:3V' AND "railway:signal:main:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:main:shape" = 'square' THEN ARRAY['it/main-s-3v', NULL, '30', '0', '0']
                    ELSE ARRAY['it/main-3v', NULL, '29.695004', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['R-Y-G', 'R-(Y-G)', 'R-(Y)-(G)'] && "railway:signal:main:states" THEN ARRAY['it/3v-RYG', NULL, '30', '0', '0']
                    WHEN 'R-Y-Y' = ANY("railway:signal:main:states") THEN ARRAY['it/3v-RYY', NULL, '30', '0', '0']
                    WHEN ARRAY['R-(Y)', 'R-Y'] && "railway:signal:main:states" THEN ARRAY['it/3v-RY', NULL, '30', '0', '0']
                    WHEN 'R-G' = ANY("railway:signal:main:states") THEN ARRAY['it/3v-RG', NULL, '30', '0', '0']
                    WHEN ARRAY['Y-G', '(Y-G)', '(Y)-(G)'] && "railway:signal:main:states" THEN ARRAY['it/3v-YG', NULL, '30', '0', '0']
                    WHEN 'Y-Y' = ANY("railway:signal:main:states") THEN ARRAY['it/3v-YY', NULL, '30', '0', '0']
                    WHEN ARRAY['(Y)', 'Y'] && "railway:signal:main:states" THEN ARRAY['it/3v-Y', NULL, '30', '0', '0']
                    WHEN 'G' = ANY("railway:signal:main:states") THEN ARRAY['it/3v-G', NULL, '30', '0', '0']
                    ELSE ARRAY['it/3v-R', NULL, '30', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['IT:AVA', 'IT:AVV'] <@ "railway:signal:main:substitute_signal" THEN ARRAY['it/AVV-AVA@bottom', NULL, '0', '11.873437', '0']
                    WHEN 'IT:AVA' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['it/AVA@bottom', NULL, '0', '5.936631', '0']
                    WHEN 'IT:AVV' = ANY("railway:signal:main:substitute_signal") THEN ARRAY['it/AVV@bottom', NULL, '0', '5.937502', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '703'])
            
            -- (JP) Departure signal
            WHEN "railway:signal:main" = 'JP:出発信号機' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['jp/main-departure', NULL, '21.234007', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '723'])
            
            -- (JP) Block signal
            WHEN "railway:signal:main" = 'JP:閉塞信号機' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['jp/main-block', NULL, '21.234007', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '724'])
            
            -- (JP) Station signal
            WHEN "railway:signal:main" = 'JP:場内信号機' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['jp/main-station', NULL, '21.234007', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '725'])
            
            -- (NL) dwarf shunting signals
            WHEN "railway:signal:main" = 'NL' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:height" = 'dwarf' AND "railway:signal:shunting" = 'NL' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['nl/main_light_dwarf_shunting', NULL, '16.978547', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '736'])
            
            -- (NL) train protection block marker light
            WHEN "railway:signal:main" = 'NL' AND "railway:signal:main:form" = 'light' AND "railway:signal:train_protection" = 'NL:228' AND "railway:signal:train_protection:form" = 'light' AND "railway:signal:train_protection:type" = 'block_marker'
              THEN array_cat(ARRAY['nl/main_light_white_bar', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '737'])
            
            -- (NL) main dwarf signals
            WHEN "railway:signal:main" = 'NL' AND "railway:signal:main:height" = 'dwarf'
              THEN array_cat(ARRAY['nl/main_light_dwarf', NULL, '12.349744', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '738'])
            
            -- (NL) main shunting light
            WHEN "railway:signal:main" = 'NL' AND "railway:signal:main:form" = 'light' AND "railway:signal:shunting" = 'NL' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['nl/main_light_shunting', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '739'])
            
            -- (NL) main light
            WHEN "railway:signal:main" = 'NL' AND "railway:signal:main:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['nl/main_light', NULL, '22', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:traversable" = 'NL:291c' THEN ARRAY['nl/291c@bottom', NULL, '0', '13.272727', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:danger" = 'NL:251aI' THEN ARRAY['nl/251aI@bottom', NULL, '0', '13.272727', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '741'])
            
            -- (NZ) Double multi-unit (permissive)
            WHEN "railway:signal:main" = 'NZ:main_MM' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'staggered'
              THEN array_cat(ARRAY['nz/main/MM-staggered', NULL, '49', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '816'])
            
            -- (NZ) Double multi-unit (absolute)
            WHEN "railway:signal:main" = 'NZ:main_MM' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['nz/main/MM', NULL, '49', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '817'])
            
            -- (NZ) Multi-unit above Searchlight (permissive)
            WHEN "railway:signal:main" = 'NZ:main_MS' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'staggered'
              THEN array_cat(ARRAY['nz/main/MS-staggered', NULL, '33', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '818'])
            
            -- (NZ) Multi-unit above Searchlight (absolute)
            WHEN "railway:signal:main" = 'NZ:main_MS' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['nz/main/MS', NULL, '33', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '819'])
            
            -- (NZ) Multi-unit with marker disk (permissive)
            WHEN "railway:signal:main" = 'NZ:main_MD' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'staggered'
              THEN array_cat(ARRAY['nz/main/MD-staggered', NULL, '32', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '820'])
            
            -- (NZ) Multi-unit with marker disk (absolute)
            WHEN "railway:signal:main" = 'NZ:main_MD' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['nz/main/MD', NULL, '32', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '821'])
            
            -- (NZ) Searchlight above multi-unit (permissive)
            WHEN "railway:signal:main" = 'NZ:main_SM' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'staggered'
              THEN array_cat(ARRAY['nz/main/SM-staggered', NULL, '33', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '822'])
            
            -- (NZ) Searchlight above multi-unit (absolute)
            WHEN "railway:signal:main" = 'NZ:main_SM' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['nz/main/SM', NULL, '33', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '823'])
            
            -- (NZ) Double Searchlight (permissive)
            WHEN "railway:signal:main" = 'NZ:main_SS' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'staggered'
              THEN array_cat(ARRAY['nz/main/SS-staggered', NULL, '23.75', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '824'])
            
            -- (NZ) Double Searchlight (absolute)
            WHEN "railway:signal:main" = 'NZ:main_SS' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['nz/main/SS', NULL, '23.75', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '825'])
            
            -- (NZ) Searchlight with marker disk (permissive)
            WHEN "railway:signal:main" = 'NZ:main_SD' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:shape" = 'staggered'
              THEN array_cat(ARRAY['nz/main/SD-staggered', NULL, '18.75', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '826'])
            
            -- (NZ) Searchlight with marker disk (absolute)
            WHEN "railway:signal:main" = 'NZ:main_SD' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['nz/main/SD', NULL, '18.75', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '827'])
            
            -- (NZ) 2-position main signal
            WHEN "railway:signal:main" = 'NZ:M' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['nz/main/M', NULL, '18.5', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '828'])
            
            -- (NZ) Semaphore main signal
            WHEN "railway:signal:main" = 'NZ:M' AND "railway:signal:main:form" = 'semaphore'
              THEN array_cat(ARRAY['nz/main/semaphore', NULL, '19.568293', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '829'])
            
            -- (PL) Semafor kształtowy
            WHEN "railway:signal:main" = 'PL-PKP:sr' AND "railway:signal:main:form" = 'semaphore'
              THEN array_cat(CASE 
                    WHEN 'PL-PKP:sr3' = ANY("railway:signal:main:states") THEN ARRAY['pl/sr3', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:sr1', 'PL-PKP:sr2'] <@ "railway:signal:main:states" THEN ARRAY['pl/sr2', NULL, '24', '0', '0']
                    ELSE ARRAY['pl/sr1', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '901'])
            
            -- (PL) Semafor świetlny (główny)
            WHEN "railway:signal:main" = 'PL-PKP:s' AND "railway:signal:main:form" = 'light' AND 'PL-PKP:sz' = ANY("railway:signal:main:substitute_signal")
              THEN array_cat(CASE 
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s10a'] <@ "railway:signal:main:states" THEN ARRAY['pl/s6-10a-4-main', NULL, '26', '0', '0']
                    WHEN 'PL-PKP:s6' = ANY("railway:signal:main:states") THEN ARRAY['pl/s6-4-main', NULL, '24', '0', '0']
                    WHEN 'PL-PKP:s10a' = ANY("railway:signal:main:states") THEN ARRAY['pl/s10a-4-main', NULL, '24', '0', '0']
                    WHEN 'PL-PKP:s10' = ANY("railway:signal:main:states") THEN ARRAY['pl/s10-4-main', NULL, '24', '0', '0']
                    ELSE ARRAY['pl/s2-3', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '902'])
            
            -- (PL) Semafor świetlny (główny, bez Sz)
            WHEN "railway:signal:main" = 'PL-PKP:s' AND "railway:signal:main:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s10a'] <@ "railway:signal:main:states" THEN ARRAY['pl/s6-10a-3-main', NULL, '24', '0', '0']
                    WHEN 'PL-PKP:s6' = ANY("railway:signal:main:states") THEN ARRAY['pl/s6-3-main', NULL, '24.61', '0', '0']
                    WHEN 'PL-PKP:s10a' = ANY("railway:signal:main:states") THEN ARRAY['pl/s10a-3-main', NULL, '24.61', '0', '0']
                    WHEN 'PL-PKP:s10' = ANY("railway:signal:main:states") THEN ARRAY['pl/s10-3-main', NULL, '21.23', '0', '0']
                    ELSE ARRAY['pl/s2-2', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '903'])
            
            -- (SE) Mellanblocksignal, Utfartsblocksignal (main)
            WHEN "railway:signal:main" IN ('SE:Utfartsblocksignal', 'SE:Mellanblocksignal') AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['se/main-block', NULL, '16.67868', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '917'])
            
            -- (SE) Linjeplatssignal (main)
            WHEN "railway:signal:main" = 'SE:Linjeplatssignal' AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['se/main-section', NULL, '28.620802', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '918'])
            
            -- (SE) Infartssignal, Mellansignal, Utfartssignal (main)
            WHEN "railway:signal:main" IN ('SE:Huvudsignal', 'SE:Utfartssignal', 'SE:Infartssignal', 'SE:Mellansignal') AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['se/main', NULL, '23.749232', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '919'])
            
            -- (SE) Mellansignal (dvärg)
            WHEN "railway:signal:main" = 'SE:Mellansignal' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:height" = 'dwarf'
              THEN array_cat(ARRAY['se/shunting-main', NULL, '24.620857', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '927'])
            
            -- (US) Main signal
            WHEN "railway:signal:main" IN ('US:main', 'US-ABS:main', 'US:GCOR:main') AND "railway:signal:main:form" = 'light'
              THEN array_cat(ARRAY['us/main', NULL, '21.234009', '0', '0'], ARRAY[NULL, "railway:signal:main:deactivated"::text, 'signals', '937'])
            
            -- Unknown signal (main)
            ELSE
              ARRAY['general/signal-unknown-main', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_main,
      CASE 
        WHEN "railway:signal:combined" IS NOT NULL THEN
          CASE 
            -- (CH) Mini-Hauptsignal System L
            WHEN "railway:signal:combined" = 'CH-FDV:512' AND "railway:signal:combined:form" = 'light' AND "railway:signal:combined:height" = 'dwarf'
              THEN array_cat(ARRAY['ch/fdv-l-522.1', NULL, '20.37736', '0', '0'], ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '268'])
            
            -- (CH) Hauptsignal System L (combined)
            WHEN "railway:signal:combined" = 'CH-FDV:l' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'CH-FDV:548' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-l-548', NULL, '33.881104', '0', '0']
                    WHEN 'CH-FDV:551' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-l-551', NULL, '24.523451', '0', '0']
                    WHEN 'CH-FDV:546' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-l-546', NULL, '24.523451', '0', '0']
                    WHEN 'CH-FDV:543' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-l-543', NULL, '24.523451', '0', '0']
                    WHEN 'CH-FDV:539' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-l-539', NULL, '24.523451', '0', '0']
                    WHEN 'CH-FDV:537' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-l-537', NULL, '24.523451', '0', '0']
                    WHEN 'CH-FDV:535' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-l-535', NULL, '24.523451', '0', '0']
                    WHEN 'CH-FDV:531' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-l-531', NULL, '24.523451', '0', '0']
                    ELSE ARRAY['ch/fdv-l-525', NULL, '24.523449', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '269'])
            
            -- (CH) Hauptsignal System N
            WHEN "railway:signal:combined" = 'CH-FDV:n' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'CH-FDV:523' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-n-523', NULL, '28.099134', '0', '0']
                    WHEN 'CH-FDV:552' = ANY("railway:signal:combined:states") THEN ARRAY['ch/fdv-n-552', NULL, '28.099134', '0', '0']
                    WHEN ARRAY['CH-FDV:532', 'CH-FDV:533'] && "railway:signal:combined:states" THEN ARRAY['ch/fdv-n-532', NULL, '14.02834', '0', '0']
                    ELSE ARRAY['ch/fdv-n-526', NULL, '14.02834', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '270'])
            
            -- (CZ) Hlavní návěstidlo
            WHEN "railway:signal:combined" IN ('CZ', 'CZ-D1:hlavni_navestidlo') AND "railway:signal:combined:form" = 'light' AND "railway:signal:combined:function" = 'block' AND ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha', 'CZ-D1:volno'] <@ "railway:signal:combined:states"
              THEN array_cat(CASE 
                    WHEN "railway:signal:station_distant" = 'CZ-D1:hlavni_navestidlo_slouceno_s_predvesti' THEN ARRAY['cz/hlavni_navestidlo/YGR-Y', NULL, '19.5', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo/YGR-G', NULL, '19.5', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '333'])
            
            -- (CZ) Hlavní návěstidlo
            WHEN "railway:signal:combined" IN ('CZ', 'CZ-D1:hlavni_navestidlo') AND "railway:signal:combined:form" = 'light' AND "railway:signal:speed_limit" IN ('CZ', 'CZ-D1:hlavni_navestidlo')
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:opakovani_vystraha'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGWRY-YWY', NULL, '30', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha', 'CZ-D1:volno'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRWY-YY', NULL, '30', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRWY-YY', NULL, '24.75', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo/YGRWY-YY', NULL, '30', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'CZ-D1:rychlost_30' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_30-sign@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_50' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_50-sign@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_60' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_60@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_80' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_80@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_100' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_100@bottom', NULL, '0', '11.999977', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '334'])
            
            -- (CZ) Hlavní návěstidlo
            WHEN "railway:signal:combined" IN ('CZ', 'CZ-D1:hlavni_navestidlo') AND "railway:signal:combined:form" = 'light' AND ARRAY['yes', 'CZ-D1:privolavaci_navest'] && "railway:signal:combined:substitute_signal"
              THEN array_cat(CASE 
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:opakovani_vystraha', 'CZ-D1:volno'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRW-YW', NULL, '24.75', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:opakovani_vystraha'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRW-YW', NULL, '19.5', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha', 'CZ-D1:volno'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRW-Y', NULL, '24.75', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRW-Y', NULL, '19.5', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo/YGRW-Y', NULL, '24.75', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '335'])
            
            -- (CZ) Hlavní návěstidlo
            WHEN "railway:signal:combined" IN ('CZ', 'CZ-D1:hlavni_navestidlo', 'Cs-D1', 'Cs-D1:', 'Cs-D1:_') AND "railway:signal:combined:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:opakovani_vystraha', 'CZ-D1:volno'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRW-YW', NULL, '24.75', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:opakovani_vystraha'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRW-YW', NULL, '19.5', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha', 'CZ-D1:volno', 'CZ-D1:posun_dovolen'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRW-Y', NULL, '24.75', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha', 'CZ-D1:posun_dovolen'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRW-Y', NULL, '19.5', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha', 'CZ-D1:volno'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGR-Y', NULL, '19.5', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YR-Y', NULL, '14.25', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:odjezdove_navestidlo_dovoluje_jizdu'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/RWB-RB', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'call_signal', 'speed_limit'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRWY-YY', NULL, '30', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'call_signal'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRW-Y', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'shunting_enabled', 'speed_limit'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRWY-YY', NULL, '30', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'shunting_enabled'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRW-Y', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear', 'speed_limit'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRY-YY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'clear'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGR-Y', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'call_signal', 'speed_limit'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRWY-YY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'call_signal'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRW-Y', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'shunting_enabled', 'speed_limit'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRWY-YY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'shunting_enabled'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRW-Y', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'approach', 'speed_limit'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRY-YY', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'approach'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YR-Y', NULL, '14.25', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'call_signal', 'speed_limit'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/GRWY-GY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'call_signal'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/GRW-G', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'shunting_enabled', 'speed_limit'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/GRWY-GY', NULL, '24.75', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'shunting_enabled'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/GRW-G', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'clear', 'speed_limit'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/GRY-GY', NULL, '19.5', '0', '0']
                    WHEN ARRAY['stop', 'clear'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/GR-G', NULL, '14.25', '0', '0']
                    WHEN ARRAY['stop', 'shunting_enabled'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/RW-R', NULL, '14.25', '0', '0']
                    WHEN ARRAY['stop'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/R-R', NULL, '9', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo/YGR-Y', NULL, '19.5', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '336'])
            
            -- (DE) combined light signals type Hl
            WHEN "railway:signal:combined" = 'DE-ESO:hl' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:hl11' = ANY("railway:signal:combined:states") THEN ARRAY['de/hl11', NULL, '25.3475', '0', '0']
                    WHEN 'DE-ESO:hl12b' = ANY("railway:signal:combined:states") THEN ARRAY['de/hl12b', NULL, '25.3475', '0', '0']
                    WHEN 'DE-ESO:hl12a' = ANY("railway:signal:combined:states") THEN ARRAY['de/hl12a', NULL, '18.296614', '0', '0']
                    WHEN 'DE-ESO:hl10' = ANY("railway:signal:combined:states") THEN ARRAY['de/hl10', NULL, '18.296614', '0', '0']
                    ELSE ARRAY['de/hl0-combined', NULL, '18.296614', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '457'])
            
            -- (DE) combined light signals type Sv
            WHEN "railway:signal:combined" = 'DE-ESO:sv' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:hp0' = ANY("railway:signal:combined:states") THEN ARRAY['de/sv-hp0', NULL, '16', '0', '0']
                    ELSE ARRAY['de/sv-sv0', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '458'])
            
            -- (DE) tram Hauptsignal mit Vorsignal
            WHEN "railway:signal:combined" = 'DE-BOStrab:h' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(ARRAY['de/bostrab/h', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '459'])
            
            -- (DE) combined signals type Sk
            WHEN "railway:signal:combined" = 'DE-ESO:sk' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(ARRAY['de/sk0-light', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '461'])
            
            -- (DE) combined signals type Ks
            WHEN "railway:signal:combined" = 'DE-ESO:ks' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(CASE 
                    WHEN "railway:signal:combined:shortened" THEN ARRAY['de/ks-combined-shortened', NULL, '16', '0', '0']
                    ELSE ARRAY['de/ks-combined', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '462'])
            
            -- (FI) combined block signal type So
            WHEN "railway:signal:combined" = 'FI:So' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(ARRAY['fi/eo1-po1-combined-block', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '544'])
            
            -- (FI) Combined signal type Yo
            WHEN "railway:signal:combined" = 'FI:Yo' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(ARRAY['fi/yo-combined', NULL, '36', '0', '0'], ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '545'])
            
            -- (IT) Segnale accoppiato (1 light)
            WHEN "railway:signal:combined" = 'IT:1V' AND "railway:signal:combined:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:combined:shape" = 'square' THEN ARRAY['it/combined-s-1v', NULL, '10', '0', '0']
                    ELSE ARRAY['it/combined-1v', NULL, '9.899397', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['(Y)', 'Y'] && "railway:signal:combined:states" THEN ARRAY['it/1v-Y', NULL, '9.899397', '0', '0']
                    WHEN 'G' = ANY("railway:signal:combined:states") THEN ARRAY['it/1v-G', NULL, '9.899397', '0', '0']
                    ELSE ARRAY['it/1v-R', NULL, '9.899397', '0', '0']
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '704'])
            
            -- (IT) Segnale accoppiato (2 lights)
            WHEN "railway:signal:combined" = 'IT:2V' AND "railway:signal:combined:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:combined:shape" = 'square' THEN ARRAY['it/combined-s-2v', NULL, '20', '0', '0']
                    ELSE ARRAY['it/combined-2v', NULL, '19.793253', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['R-(Y)', 'R-Y'] && "railway:signal:combined:states" THEN ARRAY['it/2v-RY', NULL, '19.798792', '0', '0']
                    WHEN 'R-G' = ANY("railway:signal:combined:states") THEN ARRAY['it/2v-RG', NULL, '19.798792', '0', '0']
                    WHEN ARRAY['Y-G', '(Y-G)', '(Y)-(G)'] && "railway:signal:combined:states" THEN ARRAY['it/2v-YG', NULL, '19.793253', '0', '0']
                    WHEN 'Y-Y' = ANY("railway:signal:combined:states") THEN ARRAY['it/2v-YY', NULL, '19.798792', '0', '0']
                    WHEN ARRAY['(Y)', 'Y'] && "railway:signal:combined:states" THEN ARRAY['it/2v-Y', NULL, '19.793253', '0', '0']
                    WHEN 'G' = ANY("railway:signal:combined:states") THEN ARRAY['it/2v-G', NULL, '19.793253', '0', '0']
                    ELSE ARRAY['it/2v-R', NULL, '19.798792', '0', '0']
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '705'])
            
            -- (IT) Segnale accoppiato (3 lights)
            WHEN "railway:signal:combined" = 'IT:3V' AND "railway:signal:combined:form" = 'light' AND "railway:signal:combined:shape" = 'square'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:combined:shape" = 'square' THEN ARRAY['it/combined-s-3v', NULL, '30', '0', '0']
                    ELSE ARRAY['it/combined-3v', NULL, '29.695004', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['R-Y-G', 'R-(Y-G)', 'R-(Y)-(G)'] && "railway:signal:combined:states" THEN ARRAY['it/3v-RYG', NULL, '30', '0', '0']
                    WHEN 'R-Y-Y' = ANY("railway:signal:combined:states") THEN ARRAY['it/3v-RYY', NULL, '30', '0', '0']
                    WHEN ARRAY['R-(Y)', 'R-Y'] && "railway:signal:combined:states" THEN ARRAY['it/3v-RY', NULL, '30', '0', '0']
                    WHEN 'R-G' = ANY("railway:signal:combined:states") THEN ARRAY['it/3v-RG', NULL, '30', '0', '0']
                    WHEN ARRAY['Y-G', '(Y-G)', '(Y)-(G)'] && "railway:signal:combined:states" THEN ARRAY['it/3v-YG', NULL, '30', '0', '0']
                    WHEN 'Y-Y' = ANY("railway:signal:combined:states") THEN ARRAY['it/3v-YY', NULL, '30', '0', '0']
                    WHEN ARRAY['(Y)', 'Y'] && "railway:signal:combined:states" THEN ARRAY['it/3v-Y', NULL, '30', '0', '0']
                    WHEN 'G' = ANY("railway:signal:combined:states") THEN ARRAY['it/3v-G', NULL, '30', '0', '0']
                    ELSE ARRAY['it/3v-R', NULL, '30', '0', '0']
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '706'])
            
            -- (PL) Semafor świetlny (dwukolumnowy, 6-komorowy)
            WHEN "railway:signal:combined" = 'PL-PKP:s' AND "railway:signal:combined:form" = 'light' AND 'PL-PKP:sz' = ANY("railway:signal:combined:substitute_signal") AND "railway:signal:combined:shape" = 'two_column'
              THEN array_cat(CASE 
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s12a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-6', NULL, '21.48', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s12a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-6', NULL, '21.48', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-6', NULL, '21.48', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-6', NULL, '21.48', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s8'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-6', NULL, '19.1', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s8'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-6', NULL, '19.1', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-6', NULL, '19.1', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-6', NULL, '19.1', '0', '0']
                    WHEN ARRAY['PL-PKP:s10a', 'PL-PKP:s12a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10a-6', NULL, '19.1', '0', '0']
                    WHEN ARRAY['PL-PKP:s11a', 'PL-PKP:s12a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10a-6', NULL, '19.1', '0', '0']
                    WHEN ARRAY['PL-PKP:s10a', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10a-6', NULL, '19.1', '0', '0']
                    WHEN ARRAY['PL-PKP:s11a', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10a-6', NULL, '19.1', '0', '0']
                    ELSE ARRAY['pl/s10-6', NULL, '16.47', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '904'])
            
            -- (PL) Semafor świetlny (kombinowany)
            WHEN "railway:signal:combined" = 'PL-PKP:s' AND "railway:signal:combined:form" = 'light' AND 'PL-PKP:sz' = ANY("railway:signal:combined:substitute_signal")
              THEN array_cat(CASE 
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-5', NULL, '30', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-5', NULL, '30', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s9', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-13a-5', NULL, '30.38', '0', '0']
                    WHEN ARRAY['PL-PKP:s3', 'PL-PKP:s9', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-13a-5', NULL, '30.38', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s3', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s10a', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10a-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s11a', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10a-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s13a-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s3', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s13a-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s10', 'PL-PKP:s13'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s11', 'PL-PKP:s13'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s13'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s13-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s3', 'PL-PKP:s13'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s13-5', NULL, '28', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s10a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-4', NULL, '26', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s11a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-4', NULL, '26', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s7'] && "railway:signal:combined:states" THEN ARRAY['pl/s6-4', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s10a', 'PL-PKP:s11a'] && "railway:signal:combined:states" THEN ARRAY['pl/s10a-4', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s10', 'PL-PKP:s11'] && "railway:signal:combined:states" THEN ARRAY['pl/s10-4', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s9', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-13a-4', NULL, '26', '0', '0']
                    WHEN 'PL-PKP:s9' = ANY("railway:signal:combined:states") THEN ARRAY['pl/s9-4', NULL, '24', '0', '0']
                    WHEN 'PL-PKP:s13a' = ANY("railway:signal:combined:states") THEN ARRAY['pl/s13a-4', NULL, '24', '0', '0']
                    WHEN 'PL-PKP:s13' = ANY("railway:signal:combined:states") THEN ARRAY['pl/s13-4', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s3'] && "railway:signal:combined:states" THEN ARRAY['pl/s1-4', NULL, '24', '0', '0']
                    ELSE ARRAY['pl/s5-3', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '905'])
            
            -- (PL) Semafor świetlny (kombinowany, bez Sz)
            WHEN "railway:signal:combined" = 'PL-PKP:s' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'PL-PKP:s1a' = ANY("railway:signal:combined:states") THEN ARRAY['pl/s1a-4', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-4-sz', NULL, '26', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-4-sz', NULL, '26', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s9', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-13a-4-sz', NULL, '26', '0', '0']
                    WHEN ARRAY['PL-PKP:s3', 'PL-PKP:s9', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-13a-4-sz', NULL, '26', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s3', 'PL-PKP:s9'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s10a', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10a-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s11a', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10a-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s13a-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s3', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s13a-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s10', 'PL-PKP:s13'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s11', 'PL-PKP:s13'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s10-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s13'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s13-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s3', 'PL-PKP:s13'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s13-4-sz', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s10a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-3', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s7', 'PL-PKP:s11a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s6-10a-3', NULL, '24', '0', '0']
                    WHEN ARRAY['PL-PKP:s6', 'PL-PKP:s7'] && "railway:signal:combined:states" THEN ARRAY['pl/s6-3', NULL, '24.61', '0', '0']
                    WHEN ARRAY['PL-PKP:s10a', 'PL-PKP:s11a'] && "railway:signal:combined:states" THEN ARRAY['pl/s10a-3', NULL, '23.18', '0', '0']
                    WHEN ARRAY['PL-PKP:s10', 'PL-PKP:s11'] && "railway:signal:combined:states" THEN ARRAY['pl/s10-3', NULL, '21.234008', '0', '0']
                    WHEN ARRAY['PL-PKP:s9', 'PL-PKP:s13a'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s9-13a-3', NULL, '24', '0', '0']
                    WHEN 'PL-PKP:s9' = ANY("railway:signal:combined:states") THEN ARRAY['pl/s9-3', NULL, '23.18', '0', '0']
                    WHEN 'PL-PKP:s13a' = ANY("railway:signal:combined:states") THEN ARRAY['pl/s13a-3', NULL, '24.606577', '0', '0']
                    WHEN 'PL-PKP:s13' = ANY("railway:signal:combined:states") THEN ARRAY['pl/s13-3', NULL, '20', '0', '0']
                    WHEN ARRAY['PL-PKP:s2', 'PL-PKP:s5'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s1-3', NULL, '20', '0', '0']
                    WHEN ARRAY['PL-PKP:s3', 'PL-PKP:s5'] <@ "railway:signal:combined:states" THEN ARRAY['pl/s1-3', NULL, '20', '0', '0']
                    ELSE ARRAY['pl/s5-2', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '906'])
            
            -- (SE) Mellanblocksignal, Utfartsblocksignal (combined)
            WHEN "railway:signal:combined" IN ('SE:Utfartsblocksignal', 'SE:Mellanblocksignal') AND "railway:signal:combined:form" = 'light'
              THEN array_cat(ARRAY['se/combined-block', NULL, '36.841492', '0', '0'], ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '920'])
            
            -- (SE) Infartssignal, Mellansignal, Utfartssignal (combined)
            WHEN "railway:signal:combined" IN ('SE:Huvudsignal', 'SE:Utfartssignal', 'SE:Infartssignal', 'SE:Mellansignal') AND "railway:signal:combined:form" = 'light'
              THEN array_cat(ARRAY['se/combined', NULL, '36.841492', '0', '0'], ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '921'])
            
            -- (SE) Linjeplatssignal (combined)
            WHEN "railway:signal:combined" = 'SE:Linjeplatssignal' AND "railway:signal:combined:form" = 'light'
              THEN array_cat(ARRAY['se/combined-section', NULL, '46.022657', '0', '0'], ARRAY[NULL, "railway:signal:combined:deactivated"::text, 'signals', '922'])
            
            -- Unknown signal (combined)
            ELSE
              ARRAY['general/signal-unknown-combined', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_combined,
      CASE 
        WHEN "railway:signal:distant" IS NOT NULL THEN
          CASE 
            -- (AT) distant (semaphore)
            WHEN "railway:signal:distant" = 'AT-V2:vorsignal' AND "railway:signal:distant:form" = 'semaphore'
              THEN array_cat(ARRAY['at/vorsicht-semaphore', NULL, '19', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '10'])
            
            -- (AT) Kreuztafel
            WHEN "railway:signal:distant" = 'AT-V2:kreuztafel' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(ARRAY['at/kreuztafel', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '11'])
            
            -- (AT) distant (light)
            WHEN "railway:signal:distant" = 'AT-V2:vorsignal' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'AT-V2:hauptsignal_frei_mit_60' = ANY("railway:signal:distant:states") THEN ARRAY['at/vorsignal-hauptsignal-frei-mit-60', NULL, '14', '0', '0']
                    WHEN ARRAY['AT-V2:hauptsignal_frei_mit_40', 'AT-V2:hauptsignal_frei_mit_20'] && "railway:signal:distant:states" THEN ARRAY['at/vorsignal-hauptsignal-frei-mit-40', NULL, '14', '0', '0']
                    WHEN 'AT-V2:hauptsignal_frei' = ANY("railway:signal:distant:states") THEN ARRAY['at/vorsignal-hauptsignal-frei', NULL, '14', '0', '0']
                    ELSE ARRAY['at/vorsignal-vorsicht', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '13'])
            
            -- (AU) Distant Signal (searchlight)
            WHEN "railway:signal:distant" = 'AU:NSW:distant' AND "railway:signal:distant:form" = 'light' AND "railway:signal:distant:shape" = 'searchlight'
              THEN array_cat(CASE 
                    WHEN 'GYR' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/searchlight/GYR', NULL, '9', '0', '0']
                    WHEN 'GR' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/searchlight/GR', NULL, '9', '0', '0']
                    WHEN 'YR' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/searchlight/YR', NULL, '9', '0', '0']
                    WHEN 'R' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/searchlight/R', NULL, '9', '0', '0']
                    WHEN 'GYRg' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/searchlight/GYRg', NULL, '17', '0', '0']
                    WHEN 'GRg' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/searchlight/GRg', NULL, '17', '0', '0']
                    WHEN 'YRg' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/searchlight/YRg', NULL, '17', '0', '0']
                    ELSE ARRAY['au/nsw/signals/distant/searchlight/unknown', NULL, '9', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '166'])
            
            -- (AU) Distant Signal
            WHEN "railway:signal:distant" = 'AU:NSW:distant' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'GYR' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/multi-unit/GYR', NULL, '21', '0', '0']
                    WHEN 'GR' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/multi-unit/GR', NULL, '15', '0', '0']
                    WHEN 'YR' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/multi-unit/YR', NULL, '15', '0', '0']
                    WHEN 'R' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/multi-unit/R', NULL, '9', '0', '0']
                    WHEN 'GYRg' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/multi-unit/GYRg', NULL, '23', '0', '0']
                    WHEN 'GRg' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/multi-unit/GRg', NULL, '17', '0', '0']
                    WHEN 'YRg' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/multi-unit/YRg', NULL, '17', '0', '0']
                    WHEN 'GY' = ANY("railway:signal:distant:states") THEN ARRAY['au/nsw/signals/distant/multi-unit/GY', NULL, '20', '0', '0']
                    ELSE ARRAY['au/nsw/signals/distant/multi-unit/unknown', NULL, '21', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '167'])
            
            -- (AU) Distant Signal (semaphore)
            WHEN "railway:signal:distant" = 'AU:NSW:distant' AND "railway:signal:distant:form" = 'semaphore'
              THEN array_cat(ARRAY['au/nsw/signals/distant/semaphore/GY', NULL, '19.179643', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '168'])
            
            -- (BE) Distant signal (opposite regime)
            WHEN "railway:signal:distant" = 'BE:SAI' AND "railway:signal:regime" = 'opposite'
              THEN array_cat(ARRAY['be/SAI-opposite-2J', NULL, '22.253976', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '238'])
            
            -- (BE) Distant signal (normal regime)
            WHEN "railway:signal:distant" = 'BE:SAI'
              THEN array_cat(ARRAY['be/SAI-2J', NULL, '22.253976', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '239'])
            
            -- (CH) Vorsignal System L
            WHEN "railway:signal:distant" = 'CH-FDV:l' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'CH-FDV:538' = ANY("railway:signal:distant:states") THEN ARRAY['ch/fdv-l-538', NULL, '14', '0', '0']
                    WHEN 'CH-FDV:536' = ANY("railway:signal:distant:states") THEN ARRAY['ch/fdv-l-536', NULL, '14', '0', '0']
                    WHEN 'CH-FDV:529' = ANY("railway:signal:distant:states") THEN ARRAY['ch/fdv-l-529', NULL, '14', '0', '0']
                    WHEN 'CH-FDV:534' = ANY("railway:signal:distant:states") THEN ARRAY['ch/fdv-l-534', NULL, '14', '0', '0']
                    ELSE ARRAY['ch/fdv-l-528', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '271'])
            
            -- (CH) Vorsignal System N
            WHEN "railway:signal:distant" = 'CH-FDV:n' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['CH-FDV:522', 'CH-FDV:521'] && "railway:signal:distant:states" THEN ARRAY['ch/fdv-n-521', NULL, '14.02834', '0', '0']
                    ELSE ARRAY['ch/fdv-n-533', NULL, '14.02834', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '272'])
            
            -- (CZ) Tabulka s křížem
            WHEN "railway:signal:distant" = 'CZ-D1:tabulka_s_krizem' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(ARRAY['cz/tabulka_s_krizem', NULL, '13.044824', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '318'])
            
            -- (CZ) Návěst výstraha
            WHEN "railway:signal:distant" = 'CZ-D1:vystraha' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:shape" = 'circle' THEN ARRAY['cz/vystraha/circle', NULL, '16', '0', '0']
                    ELSE ARRAY['cz/vystraha/triangle', NULL, '16.00781', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '327'])
            
            -- (CZ) Samostatná opakovací předvěst
            WHEN "railway:signal:distant" IN ('CZ', 'CZ-D1:samostatna_predvest') AND "railway:signal:distant:form" = 'light' AND "railway:signal:distant:repeated"
              THEN array_cat(CASE 
                    WHEN ARRAY['CZ-D1:opakovani_vystraha', 'CZ-D1:opakovani_volno'] <@ "railway:signal:distant:states" THEN ARRAY['cz/samostatna_predvest/YGXW-YW', NULL, '24.75', '0', '0']
                    WHEN ARRAY['CZ-D1:opakovani_vystraha'] <@ "railway:signal:distant:states" THEN ARRAY['cz/samostatna_predvest/YXW-YW', NULL, '19.5', '0', '0']
                    ELSE ARRAY['cz/samostatna_predvest/YGXW-YW', NULL, '24.75', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '328'])
            
            -- (CZ) Samostatná předvěst
            WHEN "railway:signal:distant" IN ('CZ', 'CZ-D1:samostatna_predvest', 'Cs-D1', 'Cs-D1:', 'Cs-D1:_', 'Cs-D1:Př', 'Cs-D1:Př_', 'Cs-D1:Př _') AND "railway:signal:distant:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN ARRAY['CZ-D1:vystraha', 'CZ-D1:volno'] <@ "railway:signal:distant:states" THEN ARRAY['cz/samostatna_predvest/YG-Y', NULL, '14.25', '0', '0']
                    WHEN ARRAY['CZ-D1:vystraha'] <@ "railway:signal:distant:states" THEN ARRAY['cz/samostatna_predvest/Y-Y', NULL, '9', '0', '0']
                    WHEN ARRAY['approach', 'clear'] <@ "railway:signal:distant:states" THEN ARRAY['cz/samostatna_predvest/YG-Y', NULL, '14.25', '0', '0']
                    WHEN ARRAY['approach'] <@ "railway:signal:distant:states" THEN ARRAY['cz/samostatna_predvest/Y-Y', NULL, '9', '0', '0']
                    ELSE ARRAY['cz/samostatna_predvest/YG-Y', NULL, '14.25', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:distant" IN ('Cs-D1', 'Cs-D1:', 'Cs-D1:_', 'Cs-D1:Př', 'Cs-D1:Př_', 'Cs-D1:Př _') THEN ARRAY['cz/stanoviste_samostatne_predvesti/fallback@bottom', NULL, '0', '10.63842', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '329'])
            
            -- (DE) distant signal announcement signs Ne 3 (dwarf)
            WHEN "railway:signal:distant" = 'DE-ESO:ne3' AND "railway:signal:distant:form" = 'sign' AND "railway:signal:distant:height" = 'dwarf'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:type" = 'II' THEN ARRAY['de/ne3-dwarf-II', NULL, '16', '0', '0']
                    WHEN "railway:signal:distant:type" = 'III' THEN ARRAY['de/ne3-dwarf-III', NULL, '16', '0', '0']
                    WHEN "railway:signal:distant:type" = 'IV' THEN ARRAY['de/ne3-dwarf-IV', NULL, '16', '0', '0']
                    ELSE ARRAY['de/ne3-dwarf-I', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '425'])
            
            -- (DE) distant signal announcement signs Ne 3 (normal)
            WHEN "railway:signal:distant" = 'DE-ESO:ne3' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:type" = 'II' THEN ARRAY['de/ne3-normal-II', NULL, '24', '0', '0']
                    WHEN "railway:signal:distant:type" = 'III' THEN ARRAY['de/ne3-normal-III', NULL, '24', '0', '0']
                    WHEN "railway:signal:distant:type" = 'IV' THEN ARRAY['de/ne3-normal-IV', NULL, '24', '0', '0']
                    WHEN "railway:signal:distant:type" = 'V' THEN ARRAY['de/ne3-normal-V', NULL, '24', '0', '0']
                    ELSE ARRAY['de/ne3-normal-I', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '426'])
            
            -- (DE) main signal announcement signs So 19 (normal)
            WHEN "railway:signal:distant" = 'DE-ESO:so19' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:type" = 'II' THEN ARRAY['de/so19-normal-II', NULL, '24', '0', '0']
                    WHEN "railway:signal:distant:type" = 'III' THEN ARRAY['de/so19-normal-III', NULL, '24', '0', '0']
                    ELSE ARRAY['de/so19-normal-I', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '427'])
            
            -- (DE) main signal announcement signs So 19 (dwarf)
            WHEN "railway:signal:distant" = 'DE-ESO:so19' AND "railway:signal:distant:form" = 'sign' AND "railway:signal:distant:height" = 'dwarf'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:type" = 'II' THEN ARRAY['de/so19-dwarf-II', NULL, '12', '0', '0']
                    WHEN "railway:signal:distant:type" = 'III' THEN ARRAY['de/so19-dwarf-III', NULL, '12', '0', '0']
                    ELSE ARRAY['de/so19-dwarf-I', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '428'])
            
            -- (DE) Hamburger Hochbahn distant signal
            WHEN "railway:signal:distant" = 'DE-HHA:v' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['de/hha/v1', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '429'])
            
            -- (DE) distant signal replacement by sign So 106
            WHEN "railway:signal:distant" = 'DE-ESO:so106' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(ARRAY['de/so106', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '430'])
            
            -- (DE) distant light signals type Vr (repeated)
            WHEN "railway:signal:distant" = 'DE-ESO:vr' AND "railway:signal:distant:form" = 'light' AND "railway:signal:distant:repeated"
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:vr2' = ANY("railway:signal:distant:states") THEN ARRAY['de/vr2-light-repeated', NULL, '16', '0', '0']
                    WHEN 'DE-ESO:vr1' = ANY("railway:signal:distant:states") THEN ARRAY['de/vr1-light-repeated', NULL, '16', '0', '0']
                    ELSE ARRAY['de/vr0-light-repeated', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '431'])
            
            -- (DE) distant light signals type Vr (shortened)
            WHEN "railway:signal:distant" = 'DE-ESO:vr' AND "railway:signal:distant:form" = 'light' AND "railway:signal:distant:shortened"
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:vr2' = ANY("railway:signal:distant:states") THEN ARRAY['de/vr2-light-shortened', NULL, '16', '0', '0']
                    WHEN 'DE-ESO:vr1' = ANY("railway:signal:distant:states") THEN ARRAY['de/vr1-light-shortened', NULL, '16', '0', '0']
                    ELSE ARRAY['de/vr0-light-shortened', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '432'])
            
            -- (DE) distant light signals type Vr
            WHEN "railway:signal:distant" = 'DE-ESO:vr' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:vr2' = ANY("railway:signal:distant:states") THEN ARRAY['de/vr2-light', NULL, '16', '0', '0']
                    WHEN 'DE-ESO:vr1' = ANY("railway:signal:distant:states") THEN ARRAY['de/vr1-light', NULL, '16', '0', '0']
                    ELSE ARRAY['de/vr0-light', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '433'])
            
            -- (DE) distant semaphore signals type Vr
            WHEN "railway:signal:distant" = 'DE-ESO:vr' AND "railway:signal:distant:form" = 'semaphore'
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:vr2' = ANY("railway:signal:distant:states") THEN ARRAY['de/vr2-semaphore', NULL, '26', '0', '0']
                    WHEN 'DE-ESO:vr1' = ANY("railway:signal:distant:states") THEN ARRAY['de/vr1-semaphore', NULL, '19', '0', '0']
                    ELSE ARRAY['de/vr0-semaphore', NULL, '26', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '434'])
            
            -- (DE) distant signal replacement by sign Ne 2
            WHEN "railway:signal:distant" = 'DE-ESO:db:ne2' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:shortened" THEN ARRAY['de/ne2-reduced-distance', NULL, '18', '0', '0']
                    ELSE ARRAY['de/ne2', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '435'])
            
            -- (DE) distant signal replacement at reduced distance by sign So 3 (DV 301)
            WHEN "railway:signal:distant" = 'DE-ESO:dr:so3' AND "railway:signal:distant:form" = 'sign' AND "railway:signal:distant:shortened"
              THEN array_cat(ARRAY['de/ne2-dv301-reduced-distance', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '436'])
            
            -- (DE) distant light signals type Hl
            WHEN "railway:signal:distant" = 'DE-ESO:hl' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:repeated" THEN ARRAY['de/hl1-distant-repeated', NULL, '14', '0', '0']
                    ELSE ARRAY['de/hl1-distant', NULL, '13.036842', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '437'])
            
            -- (DE) Karlsruhe VBK Vorsignale (light)
            WHEN "railway:signal:distant" = 'DE-VBK:fv' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-VBK:fv2' = ANY("railway:signal:distant:states") THEN ARRAY['de/vbk/fv2', NULL, '26', '0', '0']
                    WHEN 'DE-VBK:fv3' = ANY("railway:signal:distant:states") THEN ARRAY['de/vbk/fv3', NULL, '26', '0', '0']
                    ELSE ARRAY['de/vbk/fv1', NULL, '26', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '438'])
            
            -- (DE) Karlsruhe VBK Vorsignale (sign)
            WHEN "railway:signal:distant" IN ('DE-VBK:fv', 'DE-VBK:fv0') AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(ARRAY['de/vbk/fv0', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '439'])
            
            -- (DE) BOStrab distant signal
            WHEN "railway:signal:distant" = 'DE-BOStrab:v' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-BOStrab:v2' = ANY("railway:signal:distant:states") THEN ARRAY['de/bostrab/v2', NULL, '14', '0', '0']
                    WHEN 'DE-BOStrab:v1' = ANY("railway:signal:distant:states") THEN ARRAY['de/bostrab/v1', NULL, '14', '0', '0']
                    WHEN 'DE-VAGN:vr2' = ANY("railway:signal:distant:states") THEN ARRAY['de/vag-nuremberg/vr2', NULL, '21', '0', '0']
                    WHEN 'DE-VAGN:vr1' = ANY("railway:signal:distant:states") THEN ARRAY['de/vag-nuremberg/vr1', NULL, '21', '0', '0']
                    WHEN 'DE-VAGN:vr0' = ANY("railway:signal:distant:states") THEN ARRAY['de/vag-nuremberg/vr0', NULL, '21', '0', '0']
                    ELSE ARRAY['de/bostrab/v0', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '440'])
            
            -- (DE) distant signals type Sk (repeated)
            WHEN "railway:signal:distant" = 'DE-ESO:sk' AND "railway:signal:distant:form" = 'light' AND "railway:signal:distant:repeated"
              THEN array_cat(ARRAY['de/sk-distant-repeated', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '441'])
            
            -- (DE) distant signals type Sk
            WHEN "railway:signal:distant" = 'DE-ESO:sk' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['de/sk-distant', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '442'])
            
            -- (DE) distant signals type Ks (repeated)
            WHEN "railway:signal:distant" = 'DE-ESO:ks' AND "railway:signal:distant:form" = 'light' AND "railway:signal:distant:repeated"
              THEN array_cat(ARRAY['de/ks-distant-repeated', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '443'])
            
            -- (DE) distant signals type Ks (shortened)
            WHEN "railway:signal:distant" = 'DE-ESO:ks' AND "railway:signal:distant:form" = 'light' AND "railway:signal:distant:shortened"
              THEN array_cat(ARRAY['de/ks-distant-shortened', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '444'])
            
            -- (DE) distant signals type Ks
            WHEN "railway:signal:distant" = 'DE-ESO:ks' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['de/ks-distant', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '445'])
            
            -- (FI) distant light signals (new)
            WHEN "railway:signal:distant" = 'FI:Eo' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'FI:Eo2' = ANY("railway:signal:distant:states") THEN ARRAY['fi/eo2-new', NULL, '15', '0', '0']
                    WHEN 'FI:Eo1' = ANY("railway:signal:distant:states") THEN ARRAY['fi/eo1-new', NULL, '15', '0', '0']
                    ELSE ARRAY['fi/eo0-new', NULL, '15', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '546'])
            
            -- (FI) distant light signals (old)
            WHEN "railway:signal:distant" = 'FI:Eo-v' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'FI:Eo1' = ANY("railway:signal:distant:states") THEN ARRAY['fi/eo1-old', NULL, '10', '0', '0']
                    ELSE ARRAY['fi/eo0-old', NULL, '10', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '547'])
            
            -- (FI) Distant signal type Yo
            WHEN "railway:signal:distant" = 'FI:Yo' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['fi/yo-distant', NULL, '36', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '548'])
            
            -- (FI) distant signal
            WHEN "railway:signal:distant" = 'FI:T-301A' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-301A', NULL, '23.116016', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '549'])
            
            -- (FR) Avertissement
            WHEN "railway:signal:distant" = 'FR:A' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/D-R-A', NULL, '20', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/D-R', NULL, '20', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/D-VL', NULL, '20', '0', '0']
                    ELSE ARRAY['fr/D-A', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '612'])
            
            -- (FR) Disque
            WHEN "railway:signal:distant" = 'FR:D' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['FR:A', 'FR:(A)', 'FR:Ac'] && "railway:signal:main:states" THEN ARRAY['fr/D-A-1', NULL, '20', '0', '0']
                    WHEN ARRAY['FR:R+A', 'FR:R+(A)', 'FR:(R)+A', 'FR:(R)+(A)', 'FR:R(A)', 'FR:Rc(A)', 'FR:R(Ac)', 'FR:Rc(Ac)'] && "railway:signal:main:states" THEN ARRAY['fr/D-R-A-1', NULL, '20', '0', '0']
                    WHEN ARRAY['FR:R', 'FR:(R)', 'FR:Rc'] && "railway:signal:main:states" THEN ARRAY['fr/D-R-1', NULL, '20', '0', '0']
                    WHEN ARRAY['FR:VL', 'FR:(VL)', 'FR:VLc'] && "railway:signal:main:states" THEN ARRAY['fr/D-VL-1', NULL, '20', '0', '0']
                    ELSE ARRAY['fr/D-D', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '613'])
            
            -- (GB) Distant
            WHEN "railway:signal:distant" = 'GB-NR:distant' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['gb/distant-light', NULL, '14.173443', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '680'])
            
            -- (GB) Distant (semaphore)
            WHEN "railway:signal:distant" = 'GB-NR:distant' AND "railway:signal:distant:form" = 'semaphore'
              THEN array_cat(ARRAY['gb/distant-semaphore', NULL, '19.179643', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '681'])
            
            -- (GB) Distant (board)
            WHEN "railway:signal:distant" = 'GB-NR:distant' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(ARRAY['gb/distant-board', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '682'])
            
            -- (IT) Avviso (1 light)
            WHEN "railway:signal:distant" = 'IT:1V' AND "railway:signal:distant:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:distant:shape" = 'square' THEN ARRAY['it/avviso-s-1v', NULL, '10', '0', '0']
                    ELSE ARRAY['it/avviso-1v', NULL, '9.899397', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['(Y)', 'Y'] && "railway:signal:distant:states" THEN ARRAY['it/1v-Y', NULL, '9.899397', '0', '0']
                    ELSE ARRAY['it/1v-G', NULL, '9.899397', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT ARRAY['it/avviso@bottom', NULL, '0', '10', '0'] as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '707'])
            
            -- (IT) Avviso (2 lights)
            WHEN "railway:signal:distant" = 'IT:2V' AND "railway:signal:distant:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:distant:shape" = 'square' THEN ARRAY['it/avviso-s-2v', NULL, '20', '0', '0']
                    ELSE ARRAY['it/avviso-2v', NULL, '19.793253', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['Y-G', '(Y-G)', '(Y)-(G)'] && "railway:signal:distant:states" THEN ARRAY['it/2v-YG', NULL, '19.793253', '0', '0']
                    WHEN ARRAY['(Y)', 'Y'] && "railway:signal:distant:states" THEN ARRAY['it/2v-Y', NULL, '19.793253', '0', '0']
                    ELSE ARRAY['it/2v-G', NULL, '19.793253', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT ARRAY['it/avviso@bottom', NULL, '0', '10', '0'] as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '708'])
            
            -- (JP) Distant signal
            WHEN "railway:signal:distant" = 'JP:遠方信号機' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['jp/distant', NULL, '26.542889', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '727'])
            
            -- (NL) distant light
            WHEN "railway:signal:distant" = 'NL' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['nl/distant_light', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '742'])
            
            -- (NZ) 2-position distant signal
            WHEN "railway:signal:distant" = 'NZ:M' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['nz/distant/M', NULL, '18.5', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '830'])
            
            -- (NZ) Semaphore distant signal
            WHEN "railway:signal:distant" = 'NZ:M' AND "railway:signal:distant:form" = 'semaphore'
              THEN array_cat(ARRAY['nz/distant/semaphore', NULL, '19.179643', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '831'])
            
            -- (PL) Wskaźnik usytuowania (W1)
            WHEN "railway:signal:distant" = 'PL-PKP:w1' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(ARRAY['pl/w1', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '833'])
            
            -- (PL) Wskaźnik WKD W2
            WHEN "railway:signal:distant" = 'PL-WKD:w2' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(ARRAY['pl/wkd/w2', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '840'])
            
            -- (PL) Wskaźniki uprzedzające (W11a, niskie)
            WHEN "railway:signal:distant" = 'PL-PKP:w11a' AND "railway:signal:distant:form" = 'sign' AND "railway:signal:distant:height" = 'dwarf'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:type" = 'II' THEN ARRAY['pl/w11a-dwarf-II', NULL, '16', '0', '0']
                    WHEN "railway:signal:distant:type" = 'III' THEN ARRAY['pl/w11a-dwarf-III', NULL, '16', '0', '0']
                    WHEN "railway:signal:distant:type" = 'IV' THEN ARRAY['pl/w11a-dwarf-IV', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/w11a-dwarf-I', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '841'])
            
            -- (PL) Wskaźniki uprzedzające (W11a, wysokie)
            WHEN "railway:signal:distant" = 'PL-PKP:w11a' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:type" = 'II' THEN ARRAY['pl/w11a-normal-II', NULL, '24', '0', '0']
                    WHEN "railway:signal:distant:type" = 'III' THEN ARRAY['pl/w11a-normal-III', NULL, '24', '0', '0']
                    WHEN "railway:signal:distant:type" = 'IV' THEN ARRAY['pl/w11a-normal-IV', NULL, '24', '0', '0']
                    ELSE ARRAY['pl/w11a-normal-I', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '842'])
            
            -- (PL) Wskaźniki uprzedzające (W11b, niskie)
            WHEN "railway:signal:distant" = 'PL-PKP:w11b' AND "railway:signal:distant:form" = 'sign' AND "railway:signal:distant:height" = 'dwarf'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:type" = 'II' THEN ARRAY['pl/w11b-dwarf-II', NULL, '16', '0', '0']
                    WHEN "railway:signal:distant:type" = 'III' THEN ARRAY['pl/w11b-dwarf-III', NULL, '16', '0', '0']
                    WHEN "railway:signal:distant:type" = 'IV' THEN ARRAY['pl/w11b-dwarf-IV', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/w11b-dwarf-I', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '843'])
            
            -- (PL) Wskaźniki uprzedzające (W11b, wysokie)
            WHEN "railway:signal:distant" = 'PL-PKP:w11b' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:type" = 'II' THEN ARRAY['pl/w11b-normal-II', NULL, '24', '0', '0']
                    WHEN "railway:signal:distant:type" = 'III' THEN ARRAY['pl/w11b-normal-III', NULL, '24', '0', '0']
                    WHEN "railway:signal:distant:type" = 'IV' THEN ARRAY['pl/w11b-normal-IV', NULL, '24', '0', '0']
                    ELSE ARRAY['pl/w11b-normal-I', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '844'])
            
            -- (PL) Tarcza ostrzegawcza świetlna (To)
            WHEN "railway:signal:distant" = 'PL-PKP:os' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['PL-PKP:os2', 'PL-PKP:os3'] && "railway:signal:distant:states" THEN ARRAY['pl/os1-2', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/os1-1', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '849'])
            
            -- (PL) Tarcza ostrzegawcze kształtowe (To, nieruchoma, dwustawna i trzystawna)
            WHEN "railway:signal:distant" IN ('PL-PKP:on', 'PL-PKP:od', 'PL-PKP:ot') AND "railway:signal:distant:form" IN ('sign', 'semaphore')
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant" = 'PL-PKP:od' THEN ARRAY['pl/od', NULL, '24', '0', '0']
                    WHEN "railway:signal:distant" = 'PL-PKP:ot' THEN ARRAY['pl/ot', NULL, '24', '0', '0']
                    ELSE ARRAY['pl/on', NULL, '24', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '853'])
            
            -- (PL) Sygnalizacja świetlna (AT-1)
            WHEN "railway:signal:distant" = 'PL-tram:at-1' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(ARRAY['pl/tram/at-1', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '881'])
            
            -- (SE) Försignal
            WHEN "railway:signal:distant" = 'SE:Försignal' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['se/försignal', NULL, '15.001416', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '923'])
            
            -- (SE) Orienteringstavla huvudsignal
            WHEN "railway:signal:distant" = 'SE:orienteringstavla' AND "railway:signal:distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:distant:distance" ~ '^.+$' THEN ARRAY['se/orienteringstavla-huvudsignal-avstånd', NULL, '34.561827', '0', '0']
                    ELSE ARRAY['se/orienteringstavla-huvudsignal', NULL, '25.057955', '0', '0']
                  END, ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '926'])
            
            -- (US) Distant signal
            WHEN "railway:signal:distant" = 'US:distant' AND "railway:signal:distant:form" = 'light'
              THEN array_cat(ARRAY['us/distant', NULL, '30.245594', '0', '0'], ARRAY[NULL, "railway:signal:distant:deactivated"::text, 'signals', '938'])
            
            -- Unknown signal (distant)
            ELSE
              ARRAY['general/signal-unknown-distant', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_distant,
      CASE 
        WHEN "railway:signal:train_protection" IS NOT NULL THEN
          CASE 
            -- (AT) LZB Bereichskennzeichen
            WHEN "railway:signal:train_protection" = 'AT-V2:lzb-bereichskennzeichen' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['at/lzb-bereichskennzeichen', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '12'])
            
            -- (AU) Begin ATP
            WHEN "railway:signal:train_protection" = 'AU:NSW:begin_ATP' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/begin_ATP', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '116'])
            
            -- (AU) Begin CAB
            WHEN "railway:signal:train_protection" = 'AU:NSW:begin_CAB' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/begin_CAB', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '117'])
            
            -- (AU) Begin Single Light Indication
            WHEN "railway:signal:train_protection" = 'AU:NSW:begin_single_light' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/begin_single_light', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '118'])
            
            -- (AU) Begin Train Order Working
            WHEN "railway:signal:train_protection" IN ('AU:NSW:begin_TOW', 'AU:VIC:start_TOW') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/begin_TOW', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '119'])
            
            -- (AU) End ATP
            WHEN "railway:signal:train_protection" = 'AU:NSW:end_ATP' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/end_ATP', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '124'])
            
            -- (AU) End CAB
            WHEN "railway:signal:train_protection" = 'AU:NSW:end_CAB' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/end_CAB', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '125'])
            
            -- (AU) End Signalled Authority
            WHEN "railway:signal:train_protection" = 'AU:NSW:end_signalled_authority' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/end_signalled_authority', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '126'])
            
            -- (AU) Network Control Limit
            WHEN "railway:signal:train_protection" = 'AU:NSW:network_control' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/network_control', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '127'])
            
            -- (AU) End Single Light Indication
            WHEN "railway:signal:train_protection" = 'AU:NSW:end_single_light' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/end_single_light', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '128'])
            
            -- (AU) End Train Order Working
            WHEN "railway:signal:train_protection" IN ('AU:NSW:end_TOW', 'AU:VIC:end_TOW') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/end_TOW', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '129'])
            
            -- (AU) Warning Light
            WHEN "railway:signal:train_protection" = 'AU:NSW:warning_light' AND "railway:signal:train_protection:form" = 'light' AND "railway:signal:train_protection:shape" = 'bulb'
              THEN array_cat(ARRAY['au/nsw/signals/warning_light_bulb', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '153'])
            
            -- (AU) Warning Light
            WHEN "railway:signal:train_protection" = 'AU:NSW:warning_light' AND "railway:signal:train_protection:form" = 'light' AND "railway:signal:train_protection:shape" = 'array'
              THEN array_cat(ARRAY['au/nsw/signals/warning_light_array', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '154'])
            
            -- (AU) Automatic Light
            WHEN "railway:signal:train_protection" = 'AU:NSW:A' AND "railway:signal:train_protection:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/automatic', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '156'])
            
            -- (AU) Conventional Block Marker
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:main" = 'AU:VIC:block_marker' AND "railway:signal:train_protection:main:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'right' THEN ARRAY['au/vic/signs/block_marker/STD-left', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['au/vic/signs/block_marker/STD-overhead', NULL, '16', '0', '0']
                    ELSE ARRAY['au/vic/signs/block_marker/STD-right', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '174'])
            
            -- (AU) CBTC Block Marker
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:main" = 'AU:VIC:CBTC_block_marker' AND "railway:signal:train_protection:main:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'right' THEN ARRAY['au/vic/signs/block_marker/CBTC-left', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['au/vic/signs/block_marker/CBTC-overhead', NULL, '16', '0', '0']
                    ELSE ARRAY['au/vic/signs/block_marker/CBTC-right', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '175'])
            
            -- (AU) Start CBTC
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:start_CBTC' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/start_CBTC', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '176'])
            
            -- (AU) End CBTC
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:end_CBTC' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/end_CBTC', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '177'])
            
            -- (AU) Start AXC
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:start_AXC' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/start_AXC', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '178'])
            
            -- (AU) End AXC
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:end_AXC' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/end_AXC', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '179'])
            
            -- (AU) Start CHC
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:start_CHC' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/start_CHC', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '180'])
            
            -- (AU) End CHC
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:end_CHC' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/end_CHC', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '181'])
            
            -- (AU) Start RFR
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:start_RFR' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/start_RFR', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '182'])
            
            -- (AU) End RFR
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:end_RFR' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/end_RFR', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '183'])
            
            -- (AU) Start TPWS
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:start_TPWS' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/start_TPWS', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '184'])
            
            -- (AU) End TPWS
            WHEN "railway:signal:train_protection" = 'yes' AND "railway:signal:train_protection:system_change" = 'AU:VIC:end_TPWS' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/system_change/end_TPWS', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '185'])
            
            -- (BE) train protection block markers (arrow)
            WHEN "railway:signal:train_protection" = 'BE:PRA' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'block_marker' AND "railway:signal:train_protection:shape" = 'arrow'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['be/PRA-arrow-right', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['be/PRA-arrow-down', NULL, '16', '0', '0']
                    ELSE ARRAY['be/PRA-arrow-left', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '260'])
            
            -- (BE) train protection block markers (triangle)
            WHEN "railway:signal:train_protection" = 'BE:PRA' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'block_marker'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['be/PRA-triangle-right', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['be/PRA-triangle-down', NULL, '16', '0', '0']
                    ELSE ARRAY['be/PRA-triangle-left', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '261'])
            
            -- (BE) Start ETCS Level 1 Limited Supervision zone
            WHEN "railway:signal:train_protection" = 'BE:ETCS-1LS' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'start'
              THEN array_cat(ARRAY['be/ETCS1LS', NULL, '9.999997', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '262'])
            
            -- (BE) Start ETCS Level 1 Full Supervision zone
            WHEN "railway:signal:train_protection" = 'BE:ETCS-1FS' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'start'
              THEN array_cat(ARRAY['be/ETCS1', NULL, '10.000003', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '263'])
            
            -- (BE) Start ETCS Level 2 Full Supervision zone
            WHEN "railway:signal:train_protection" = 'BE:ETCS-2' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'start'
              THEN array_cat(ARRAY['be/ETCS2', NULL, '10.000003', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '264'])
            
            -- (BE) End ETCS zone
            WHEN "railway:signal:train_protection" = 'BE:ETCS-end' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'end'
              THEN array_cat(ARRAY['be/ETCS-end', NULL, '10.000002', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '265'])
            
            -- (DE) tram signal "start of train protection" So 1
            WHEN "railway:signal:train_protection" IN ('DE-BOStrab:so1', 'DE-AVG:so1') AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'start'
              THEN array_cat(ARRAY['de/bostrab/so1', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '358'])
            
            -- (DE) tram signal "end of train protection" So 2
            WHEN "railway:signal:train_protection" IN ('DE-BOStrab:so2', 'DE-AVG:so2') AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'end'
              THEN array_cat(ARRAY['de/bostrab/so2', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '359'])
            
            -- (DE) ETCS block marker Ne 14
            WHEN "railway:signal:train_protection" = 'DE-ESO:ne14' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'block_marker'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['de/ne14-right', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['de/ne14-down', NULL, '16', '0', '0']
                    ELSE ARRAY['de/ne14-left', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '360'])
            
            -- (DE) LZB section start
            WHEN "railway:signal:train_protection" = 'DE-ESO:lzb-bereichskennzeichen' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['de/lzb-section-start', NULL, '12.700437', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '361'])
            
            -- (DE) Blockkennzeichen
            WHEN "railway:signal:train_protection" = 'DE-ESO:blockkennzeichen'
              THEN array_cat(ARRAY['de/blockkennzeichen', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '362'])
            
            -- ETCS marker
            WHEN "railway:signal:train_protection" = 'ETCS:marker' AND "railway:signal:train_protection:main" = 'ETCS:stop_marker' AND "railway:signal:train_protection:main:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['etcs/stop_marker-right', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" IN ('overhead', 'bridge') THEN ARRAY['etcs/stop_marker-down', NULL, '16', '0', '0']
                    ELSE ARRAY['etcs/stop_marker-left', NULL, '16', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:train_protection:system_change" = 'ETCS:level_transition' THEN ARRAY['etcs/level_transition@bottom', NULL, '0', '16', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '529'])
            
            -- ETCS marker
            WHEN "railway:signal:train_protection" = 'ETCS:marker' AND "railway:signal:train_protection:main" = 'ETCS:location_marker' AND "railway:signal:train_protection:main:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['etcs/location_marker-right', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" IN ('overhead', 'bridge') THEN ARRAY['etcs/location_marker-down', NULL, '16', '0', '0']
                    ELSE ARRAY['etcs/location_marker-left', NULL, '16', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:train_protection:system_change" = 'ETCS:level_transition' THEN ARRAY['etcs/level_transition@bottom', NULL, '0', '16', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '530'])
            
            -- ETCS marker
            WHEN "railway:signal:train_protection" = 'ETCS:marker' AND "railway:signal:train_protection:system_change" = 'ETCS:level_transition' AND "railway:signal:train_protection:system_change:form" = 'sign'
              THEN array_cat(ARRAY['etcs/level_transition', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '531'])
            
            -- (FI) JKV alkaa
            WHEN "railway:signal:train_protection" IN ('FI:T-140', 'FI:T-140A') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-140', NULL, '14.560487', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '550'])
            
            -- (FI) JKV päättyy
            WHEN "railway:signal:train_protection" IN ('FI:T-141', 'FI:T-141A') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-141', NULL, '14.560487', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '551'])
            
            -- (FI) JKV rakennusalue alkaa
            WHEN "railway:signal:train_protection" IN ('FI:T-142', 'FI:T-142A') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-142', NULL, '14.560487', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '552'])
            
            -- (FI) JKV rakennusalue päättyy
            WHEN "railway:signal:train_protection" IN ('FI:T-143', 'FI:T-143A') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-143', NULL, '14.560487', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '553'])
            
            -- (FI) Baliisiryhmämerkki (old)
            WHEN "railway:signal:train_protection" = 'FI:T-144' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-144', NULL, '16.693377', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '554'])
            
            -- (FI) Baliisiryhmämerkki (new)
            WHEN "railway:signal:train_protection" IN ('FI:T-144A', 'FI:T-144B', 'FI:T-144C', 'FI:T-144D') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['fi/t-144A', NULL, '16.8', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:train_protection" = 'FI:T-144B' THEN ARRAY['fi/t-144-right', NULL, '16.8', '0', '0']
                    WHEN "railway:signal:train_protection" = 'FI:T-144C' THEN ARRAY['fi/t-144-left', NULL, '16.8', '0', '0']
                    WHEN "railway:signal:train_protection" = 'FI:T-144D' THEN ARRAY['fi/t-144-both', NULL, '16.8', '0', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '555'])
            
            -- (FR) Cab signalling announcement
            WHEN "railway:signal:train_protection" IN ('FR:CAB_E', 'FR:pancarte_CAB_entrée') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['fr/CAB_E', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '636'])
            
            -- (FR) Cab signalling start
            WHEN "railway:signal:train_protection" = 'FR:CAB_R' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['fr/CAB_R', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '637'])
            
            -- (FR) Cab signalling end
            WHEN "railway:signal:train_protection" IN ('FR:CAB_S', 'FR:pancarte_CAB_sortie') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['fr/CAB_S', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '638'])
            
            -- (FR) TVM block marker
            WHEN "railway:signal:train_protection" IN ('FR:REP_TVM', 'FR:repère_arrêt_TVM') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['fr/REP_TVM-right', NULL, '14', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['fr/REP_TVM-down', NULL, '14', '0', '0']
                    ELSE ARRAY['fr/REP_TVM-left', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '639'])
            
            -- (FR) ETCS stop marker
            WHEN "railway:signal:train_protection" = 'FR:REP_ETCS' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['fr/REP_ETCS-right', NULL, '14', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['fr/REP_ETCS-down', NULL, '14', '0', '0']
                    ELSE ARRAY['fr/REP_ETCS-left', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '640'])
            
            -- (FR) TVM and ETCS block marker
            WHEN "railway:signal:train_protection" IN ('FR:REP_ETCS;FR:REP_TVM', 'FR:repère_arrêt_ETCS;FR:repère_arrêt_TVM') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['fr/REP_TVM_ETCS-right', NULL, '29.41427', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['fr/REP_TVM_ETCS-down', NULL, '29.4', '0', '0']
                    ELSE ARRAY['fr/REP_TVM_ETCS-left', NULL, '29.128822', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '641'])
            
            -- (GB) Cab Signalling Start Warning Board
            WHEN "railway:signal:train_protection" = 'GB-NR:warning' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['gb/cab-entry-warning', NULL, '16', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:train_protection:turn_direction" = 'left' THEN ARRAY['gb/cab-arrow-left@top', NULL, '0', '5.33334', '0']
                    WHEN "railway:signal:train_protection:turn_direction" = 'right' THEN ARRAY['gb/cab-arrow-right@top', NULL, '0', '5.33334', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '671'])
            
            -- (GB) Cab Signalling Start Board
            WHEN "railway:signal:train_protection" = 'GB-NR:entry' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'start'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['gb/cab-entry', NULL, '16', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:train_protection:turn_direction" = 'left' THEN ARRAY['gb/cab-arrow-left@top', NULL, '0', '5.33334', '0']
                    WHEN "railway:signal:train_protection:turn_direction" = 'right' THEN ARRAY['gb/cab-arrow-right@top', NULL, '0', '5.33334', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '672'])
            
            -- (GB) Cab Signalling End Board
            WHEN "railway:signal:train_protection" = 'GB-NR:exit' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'end'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['gb/cab-exit', NULL, '16', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:train_protection:turn_direction" = 'left' THEN ARRAY['gb/cab-arrow-left@top', NULL, '0', '5.33334', '0']
                    WHEN "railway:signal:train_protection:turn_direction" = 'right' THEN ARRAY['gb/cab-arrow-right@top', NULL, '0', '5.33334', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '673'])
            
            -- (GB) ETCS Block Marker
            WHEN "railway:signal:train_protection" = 'GB-NR:ETCS' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'block_marker'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:position" = 'right' THEN ARRAY['gb/ETCS-left', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['gb/ETCS-overhead', NULL, '16', '0', '0']
                    ELSE ARRAY['gb/ETCS-right', NULL, '16', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:train_protection:block_marker:type" = 'passable' THEN ARRAY['gb/block-passable@bottom', NULL, '0', '16', '0']
                    WHEN "railway:signal:train_protection:block_marker:type" = 'absolute' THEN ARRAY['gb/block-absolute@bottom', NULL, '0', '16', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '674'])
            
            -- (GB) TVM/CBTC Block Marker
            WHEN "railway:signal:train_protection" = 'GB-NR:TVM-CBTC' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'block_marker'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN "railway:signal:position" = 'right' THEN ARRAY['gb/TVM-CBTC-left', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['gb/TVM-CBTC-overhead', NULL, '16', '0', '0']
                    ELSE ARRAY['gb/TVM-CBTC-right', NULL, '16', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:train_protection:block_marker:type" = 'passable' THEN ARRAY['gb/block-passable@bottom', NULL, '0', '16', '0']
                    WHEN "railway:signal:train_protection:block_marker:type" = 'absolute' THEN ARRAY['gb/block-absolute@bottom', NULL, '0', '16', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '675'])
            
            -- (GB) Cab Signalling Shunt Entry Board
            WHEN "railway:signal:train_protection" = 'GB-NR:shunt-entry' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'block_marker'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'right' THEN ARRAY['gb/cab-shunt-left', NULL, '13.436236', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['gb/cab-shunt-overhead', NULL, '19.052955', '0', '0']
                    ELSE ARRAY['gb/cab-shunt-right', NULL, '13.436236', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '676'])
            
            -- (NL) train protection block marker light
            WHEN "railway:signal:main" = 'NL' AND "railway:signal:main:form" = 'light' AND "railway:signal:train_protection" = 'NL:228' AND "railway:signal:train_protection:form" = 'light' AND "railway:signal:train_protection:type" = 'block_marker'
              THEN NULL
            
            -- (NL) block marker (arrow)
            WHEN "railway:signal:train_protection" IN ('NL:227b', 'NL:227') AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'block_marker' AND "railway:signal:train_protection:shape" = 'arrow'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['nl/227b-arrow-right', NULL, '14', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['nl/227b-arrow-down', NULL, '14', '0', '0']
                    ELSE ARRAY['nl/227b-arrow-left', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '744'])
            
            -- (NL) block marker (triangle)
            WHEN "railway:signal:train_protection" IN ('NL:227b', 'NL:227') AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'block_marker'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['nl/227b-triangle-right', NULL, '14', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['nl/227b-triangle-down', NULL, '14', '0', '0']
                    ELSE ARRAY['nl/227b-triangle-left', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '745'])
            
            -- (NL) drive on sight
            WHEN "railway:signal:train_protection" = 'NL:317' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nl/317', NULL, '15.75026', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '746'])
            
            -- (NL) ETCS cab signalling (start)
            WHEN "railway:signal:train_protection" = 'NL:336' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nl/336', NULL, '12.134022', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '747'])
            
            -- (NL) ETCS cab signalling (end)
            WHEN "railway:signal:train_protection" = 'NL:337' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nl/337', NULL, '12.134022', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '748'])
            
            -- (NL) ATB distant
            WHEN "railway:signal:train_protection" = 'NL:328a' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nl/328a', NULL, '17.991795', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '749'])
            
            -- (NL) ATB start
            WHEN "railway:signal:train_protection" = 'NL:328' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nl/328', NULL, '17.991896', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '750'])
            
            -- (NL) ATB code
            WHEN "railway:signal:train_protection" = 'NL:328b' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nl/328b', NULL, '17.991896', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '751'])
            
            -- (NL) ATB end
            WHEN "railway:signal:train_protection" = 'NL:329' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nl/329', NULL, '17.991896', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '752'])
            
            -- (NL) ATB codewissel
            WHEN "railway:signal:train_protection" = 'NL:330' AND "railway:signal:train_protection:form" = 'light'
              THEN array_cat(ARRAY['nl/330', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '753'])
            
            -- (NL) Einde beveiligd gebied
            WHEN "railway:signal:train_protection" = 'NL:333' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nl/333', NULL, '17.992171', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '754'])
            
            -- (NZ) A-Light
            WHEN "railway:signal:train_protection" = 'NZ:A' AND "railway:signal:train_protection:form" = 'light'
              THEN array_cat(ARRAY['nz/A', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '795'])
            
            -- (NZ) Automatic Signaling Begins
            WHEN "railway:signal:train_protection" = 'NZ:AS_begins' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nz/begin_AS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '796'])
            
            -- (NZ) Automatic Signaling Ends
            WHEN "railway:signal:train_protection" = 'NZ:AS_ends' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nz/end_AS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '797'])
            
            -- (NZ) Centralized Traffic Control Begins
            WHEN "railway:signal:train_protection" IN ('NZ:CTC_begins', 'AU:VIC:start_CTC') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nz/begin_CTC', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '798'])
            
            -- (NZ) Centralized Traffic Control Ends
            WHEN "railway:signal:train_protection" IN ('NZ:CTC_ends', 'AU:VIC:end_CTC') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nz/end_CTC', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '799'])
            
            -- (NZ) Entry to European Train Control System
            WHEN "railway:signal:train_protection" = 'NZ:ETCS_begins' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nz/begin_ETCS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '800'])
            
            -- (NZ) Exit from European Train Control System
            WHEN "railway:signal:train_protection" = 'NZ:ETCS_ends' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nz/end_ETCS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '801'])
            
            -- (NZ) Track Warrant Control Begins
            WHEN "railway:signal:train_protection" = 'NZ:TWC_begins' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nz/begin_TWC', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '802'])
            
            -- (NZ) Track Warrant Control Ends
            WHEN "railway:signal:train_protection" = 'NZ:TWC_ends' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['nz/end_TWC', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '803'])
            
            -- (PL) Wskaźniki ETCS L1 Limited Supervision
            WHEN "railway:signal:train_protection" IN ('PL-PKP:wetcs1', 'PL-PKP:wetcs2', 'PL-PKP:wetcs3') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:train_protection" = 'PL-PKP:wetcs2' THEN ARRAY['pl/wetcs2', NULL, '16', '0', '0']
                    WHEN "railway:signal:train_protection" = 'PL-PKP:wetcs3' THEN ARRAY['pl/wetcs3', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/wetcs1', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '835'])
            
            -- (PL) Wskaźniki ETCS L1
            WHEN "railway:signal:train_protection" IN ('PL-PKP:wetcs4', 'PL-PKP:wetcs5', 'PL-PKP:wetcs6') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:train_protection" = 'PL-PKP:wetcs5' THEN ARRAY['pl/wetcs5', NULL, '16', '0', '0']
                    WHEN "railway:signal:train_protection" = 'PL-PKP:wetcs6' THEN ARRAY['pl/wetcs6', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/wetcs4', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '836'])
            
            -- (PL) Wskaźniki ETCS L2
            WHEN "railway:signal:train_protection" IN ('PL-PKP:wetcs7', 'PL-PKP:wetcs8', 'PL-PKP:wetcs9') AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:train_protection" = 'PL-PKP:wetcs8' THEN ARRAY['pl/wetcs8', NULL, '16', '0', '0']
                    WHEN "railway:signal:train_protection" = 'PL-PKP:wetcs9' THEN ARRAY['pl/wetcs9', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/wetcs7', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '837'])
            
            -- (PL) Wskaźnik zatrzymania ETCS (WETCS10)
            WHEN "railway:signal:train_protection" = 'PL-PKP:wetcs10' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'block_marker'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['pl/wetcs10-right', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['pl/wetcs10-down', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/wetcs10-left', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '838'])
            
            -- (PL) Wskaźnik lokalizacji ETCS (WETCS11)
            WHEN "railway:signal:train_protection" = 'PL-PKP:wetcs11' AND "railway:signal:train_protection:form" = 'sign' AND "railway:signal:train_protection:type" = 'location_marker'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'left' THEN ARRAY['pl/wetcs11-right', NULL, '16', '0', '0']
                    WHEN "railway:signal:position" = 'overhead' THEN ARRAY['pl/wetcs11-down', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/wetcs11-left', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '839'])
            
            -- (SE) Repeterbalister
            WHEN "railway:signal:train_protection" = 'SE:Repeterbaliser' AND "railway:signal:train_protection:form" = 'sign'
              THEN array_cat(ARRAY['se/repeterbaliser', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:train_protection:deactivated"::text, 'signals', '924'])
            
            -- Unknown signal (train_protection)
            ELSE
              ARRAY['general/signal-unknown-train_protection', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_train_protection,
      CASE 
        WHEN "railway:signal:main_repeated" IS NOT NULL THEN
          CASE 
            -- (AT) Signalnachahmer with Ersatzsignal
            WHEN "railway:signal:main_repeated" = 'AT-V2:signalnachahmer' AND "railway:signal:main_repeated:form" = 'light' AND 'AT-V2:ersatzsignal' = ANY("railway:signal:main_repeated:substitute_signal")
              THEN array_cat(CASE 
                    WHEN "railway:signal:main_repeated:magnet" THEN ARRAY['at/signalnachahmer-ersatzsignal-magnet', NULL, '14', '0', '0']
                    ELSE ARRAY['at/signalnachahmer-ersatzsignal', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '2'])
            
            -- (AT) Signalnachahmer
            WHEN "railway:signal:main_repeated" = 'AT-V2:signalnachahmer' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(CASE 
                    WHEN "railway:signal:main_repeated:magnet" THEN ARRAY['at/signalnachahmer-magnet', NULL, '14', '0', '0']
                    ELSE ARRAY['at/signalnachahmer', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '3'])
            
            -- (AU) Alert
            WHEN "railway:signal:main_repeated" = 'AU:NSW:alert' AND "railway:signal:main_repeated:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/alert', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '115'])
            
            -- (AU) LED Repeater
            WHEN "railway:signal:main_repeated" = 'AU:NSW:LED_repeater' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/LED_repeater', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '149'])
            
            -- (AU) Guards Indicator
            WHEN "railway:signal:main_repeated" = 'AU:NSW:guards_indicator' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/guards_indicator', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '152'])
            
            -- (AU) Banner Indicator (theatre box)
            WHEN "railway:signal:main_repeated" = 'AU:VIC:banner_indicator' AND "railway:signal:main_repeated:form" = 'light' AND "railway:signal:main_repeated:shape" = 'theatre_box'
              THEN array_cat(ARRAY['au/vic/signals/banner_indicator/theatre_box', NULL, '27', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '191'])
            
            -- (AU) Banner Indicator (compact)
            WHEN "railway:signal:main_repeated" = 'AU:VIC:banner_indicator' AND "railway:signal:main_repeated:form" = 'light' AND "railway:signal:main_repeated:shape" = 'compact'
              THEN array_cat(ARRAY['au/vic/signals/banner_indicator/compact', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '192'])
            
            -- (AU) Banner Indicator (dwarf)
            WHEN "railway:signal:main_repeated" = 'AU:VIC:banner_indicator' AND "railway:signal:main_repeated:form" = 'light' AND "railway:signal:main_repeated:shape" = 'dwarf'
              THEN array_cat(ARRAY['au/vic/signals/banner_indicator/dwarf', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '193'])
            
            -- (AU) Banner Indicator (single)
            WHEN "railway:signal:main_repeated" = 'AU:VIC:banner_indicator' AND "railway:signal:main_repeated:form" = 'light' AND "railway:signal:main_repeated:shape" = 'single'
              THEN array_cat(ARRAY['au/vic/signals/banner_indicator/single', NULL, '22.5', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '194'])
            
            -- (BE) Répétiteur à Traits Lumineux
            WHEN "railway:signal:main_repeated" = 'BE:RTL'
              THEN array_cat(ARRAY['be/RTL-open', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '242'])
            
            -- (CH) Fahrtstellungsmelder
            WHEN "railway:signal:main_repeated" = 'CH-FDV:559' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['ch/fdv-559', NULL, '15.752716', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '273'])
            
            -- (DE) Signalhaltmelder Zugleitbetrieb
            WHEN "railway:signal:main_repeated" = 'DE-DB:signalhaltmelder' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['de/zlb-haltmelder-light', NULL, '12.867646', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '363'])
            
            -- (DE) Fahrtanzeiger
            WHEN "railway:signal:main_repeated" = 'DE-ESO:fahrtanzeiger' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['de/fahrtanzeiger', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '364'])
            
            -- (FI) Main repeated light
            WHEN "railway:signal:main_repeated" = 'FI:Ko' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['fi/ko1', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '562'])
            
            -- (GB) Repeated (banner)
            WHEN "railway:signal:main_repeated" = 'GB-NR:banner' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['gb/repeated-banner', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '683'])
            
            -- (GB) Repeated off
            WHEN "railway:signal:main_repeated" = 'GB-NR:off' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['gb/repeated-off', NULL, '12.754435', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '684'])
            
            -- (JP) Repeated signal
            WHEN "railway:signal:main_repeated" = 'JP:中継信号機' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['jp/main_repeated', NULL, '9.999949', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '728'])
            
            -- (NL) main repeated light
            WHEN "railway:signal:main_repeated" = 'NL' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['nl/main_repeated_light', NULL, '20.540851', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '740'])
            
            -- (NZ) Single Banner Indicator
            WHEN "railway:signal:main_repeated" = 'NZ:banner_indicator3D' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['nz/banner_indicator3D', NULL, '22.5', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '791'])
            
            -- (NZ) Double Banner Indicator
            WHEN "railway:signal:main_repeated" = 'NZ:banner_indicator33' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['nz/banner_indicator33', NULL, '27', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '792'])
            
            -- (PL) Sygnalizator powtarzający (Sp)
            WHEN "railway:signal:main_repeated" = 'PL-PKP:sp' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'PL-PKP:sp2' = ANY("railway:signal:main_repeated:states") THEN ARRAY['pl/sp2-3', NULL, '20', '0', '0']
                    WHEN 'PL-PKP:sp3' = ANY("railway:signal:main_repeated:states") THEN ARRAY['pl/sp1-3', NULL, '20', '0', '0']
                    ELSE ARRAY['pl/sp1-2', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '834'])
            
            -- (SE) Repetersignal
            WHEN "railway:signal:main_repeated" = 'SE:Repetersignal' AND "railway:signal:main_repeated:form" = 'light'
              THEN array_cat(ARRAY['se/repetersignal', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:main_repeated:deactivated"::text, 'signals', '925'])
            
            -- Unknown signal (main_repeated)
            ELSE
              ARRAY['general/signal-unknown-main_repeated', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_main_repeated,
      CASE 
        WHEN "railway:signal:speed_limit" IS NOT NULL THEN
          CASE 
            -- (AT) EK poor sight (GKB)
            WHEN "railway:signal:whistle" = 'AT-GKB:ek_60' AND "railway:signal:whistle:form" = 'sign' AND "railway:signal:speed_limit" = 'AT-GKB:ek_60' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['at/ek-60', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '41'])
            
            -- (AT) Geschwindigkeitsanzeiger (sign)
            WHEN "railway:signal:speed_limit" = 'AT-V2:geschwindigkeitsanzeiger' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[0-6]|[1-9])0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('at/geschwindigkeitsanzeiger-sign-{', (select match from (select regexp_substr(match, '^(1[0-6]|[1-9])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-6]|[1-9])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '14', '0', '0']
                    ELSE ARRAY['at/geschwindigkeitsanzeiger-empty-sign', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '45'])
            
            -- (AT) Geschwindigkeitsanzeiger (light)
            WHEN "railway:signal:speed_limit" = 'AT-V2:geschwindigkeitsanzeiger' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^(1[024]|[2-9])0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('at/geschwindigkeitsanzeiger-light-{', (select match from (select regexp_substr(match, '^(1[024]|[2-9])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[024]|[2-9])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '14', '0', '0']
                    ELSE ARRAY['at/geschwindigkeitsanzeiger-empty-light', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '46'])
            
            -- (AT) Geschwindigkeitstafel
            WHEN "railway:signal:speed_limit" = 'AT-V2:geschwindigkeitstafel' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[0-6]0|[1-9][05]|5)$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('at/geschwindigkeitstafel-sign-{', (select match from (select regexp_substr(match, '^(1[0-6]0|[1-9][05]|5)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-6]0|[1-9][05]|5)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['at/geschwindigkeitstafel-empty-sign', NULL, '16', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '47'])
            
            -- (AT) Salzburger Lokalbahn & Pinzgauer Lokalbahn X40
            WHEN "railway:signal:speed_limit" = 'AT-SLB:x40' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['at/x40', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '48'])
            
            -- (AT) Anfangssignal
            WHEN "railway:signal:speed_limit" = 'AT-V2:anfangssignal' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[1-6]0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('at/anfangssignal-{', (select match from (select regexp_substr(match, '^[1-6]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-6]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['at/anfangssignal-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '49'])
            
            -- (AT) Endsignal
            WHEN "railway:signal:speed_limit" = 'AT-V2:endsignal' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['at/endsignal', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '50'])
            
            -- (AT) EK sicht Pfeiftafel
            WHEN "railway:signal:speed_limit" = 'AT-V2:ek-sicht_pfeiftafel' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['at/ek-sicht-pfeiftafel', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '51'])
            
            -- (BE) Speed limit light (part of main signal)
            WHEN "railway:signal:speed_limit" = 'BE:VIS' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^([4-9]0)$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('be/VIS-{', (select match from (select regexp_substr(match, '^([4-9]0)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([4-9]0)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['be/VIS-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '226'])
            
            -- (BE) Reference speed
            WHEN "railway:signal:speed_limit" = 'BE:PVR' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[4-9]0$|^1[0-6]0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('be/PVR-{', (select match from (select regexp_substr(match, '^[4-9]0$|^1[0-6]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[4-9]0$|^1[0-6]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '17.320999', '0', '0']
                    ELSE ARRAY['be/PVR-empty', NULL, '17.321001', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '227'])
            
            -- (BE) Beginning of a speed limit
            WHEN "railway:signal:speed_limit" = 'BE:PVO' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^5$|^[0-9]0$|^1[0-5]0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('be/PVO-{', (select match from (select regexp_substr(match, '^5$|^[0-9]0$|^1[0-5]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^5$|^[0-9]0$|^1[0-5]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '14.096813', '0', '0']
                    ELSE ARRAY['be/PVO-empty', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '229'])
            
            -- (BE) Higher speed limit below reference speed
            WHEN "railway:signal:speed_limit" = 'BE:PVJ' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^5$|^[0-9]0$|^1[0-5]0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('be/PVJ-{', (select match from (select regexp_substr(match, '^5$|^[0-9]0$|^1[0-5]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^5$|^[0-9]0$|^1[0-5]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '17.320999', '0', '0']
                    ELSE ARRAY['be/PVJ-empty', NULL, '17.321001', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '230'])
            
            -- (BE) Higher speed limit for some traffic
            WHEN "railway:signal:speed_limit" = 'BE:PVV' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^5$|^[0-9]0$|^1[0-5]0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('be/PVV-{', (select match from (select regexp_substr(match, '^5$|^[0-9]0$|^1[0-5]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^5$|^[0-9]0$|^1[0-5]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '17.320999', '0', '0']
                    ELSE ARRAY['be/PVV-empty', NULL, '17.321001', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '231'])
            
            -- (BE) Carwash
            WHEN "railway:signal:speed_limit" = 'BE:SSC' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(ARRAY['be/SSC', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '233'])
            
            -- (CH) Anfangssignal verminderte Geschwindigkeit
            WHEN "railway:signal:speed_limit" = 'CH-FDV:211' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['ch/fdv-211', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '276'])
            
            -- (CH) Endesignal verminderte Geschwindigkeit
            WHEN "railway:signal:speed_limit" = 'CH-FDV:212' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['ch/fdv-212', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '277'])
            
            -- (CH) Anfangssignal verminderte Geschwindigkeit
            WHEN "railway:signal:speed_limit" = 'CH-FDV:214' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['ch/fdv-214', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '279'])
            
            -- (CH) Endesignal verminderte Geschwindigkeit
            WHEN "railway:signal:speed_limit" = 'CH-FDV:215' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['ch/fdv-215', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '280'])
            
            -- (CH) Merktafel für Änderung der Höchstgeschwindigkeit
            WHEN "railway:signal:speed_limit" = 'CH-FDV:217' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['ch/fdv-217', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '281'])
            
            -- (CH) Geschwindigkeits-Ausführung
            WHEN "railway:signal:speed_limit" = 'CH-FDV:549' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^([4-9]|1[0-2])0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('ch/fdv-549-{', (select match from (select regexp_substr(match, '^([4-9]|1[0-2])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([4-9]|1[0-2])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['ch/fdv-549-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '283'])
            
            -- (CH) Merktafel für Streckengeschwindigkeit beim Signalsystem N
            WHEN "railway:signal:speed_limit" = 'CH-FDV:569' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['ch/fdv-569', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '284'])
            
            -- (CZ) Rychlostník NS
            WHEN "railway:signal:speed_limit" IN ('CZ-D1:rychlostnik_ns') AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN 'none' = ANY("railway:signal:speed_limit:speed") THEN ARRAY['cz/rychlostnik/NS/end', NULL, '30', '0', '0']
                    WHEN '^[1-9][05]|1[0-5][05]|160$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('cz/rychlostnik/NS/{', (select match from (select regexp_substr(match, '^[1-9][05]|1[0-5][05]|160$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9][05]|1[0-5][05]|160$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '30', '0', '0']
                    ELSE ARRAY['cz/rychlostnik/NS/unknown', NULL, '24', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:speed_limit:type" = 'immediate' THEN ARRAY['cz/rychlostnik/immediate@top', NULL, '0', '9', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '321'])
            
            -- (CZ) Rychlostník N
            WHEN "railway:signal:speed_limit" IN ('CZ', 'CZ-D1:rychlostnik_n', 'CZ-D1:horni_rychlostnik_n', 'Cs-D1') AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN '^[1-9][05]|1[0-5][05]|160$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('cz/rychlostnik/N/{', (select match from (select regexp_substr(match, '^[1-9][05]|1[0-5][05]|160$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9][05]|1[0-5][05]|160$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '14', '0', '0']
                    ELSE ARRAY['cz/rychlostnik/N/unknown', NULL, '14', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:speed_limit:type" = 'immediate' THEN ARRAY['cz/rychlostnik/immediate@top', NULL, '0', '9', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '322'])
            
            -- (CZ) Rychlostník N s pruhy
            WHEN "railway:signal:speed_limit" IN ('CZ-D1:rychlostnik_n_s_pruhy') AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN '^[1-9][05]|1[0-5][05]|160$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('cz/rychlostnik/N_s_pruhy/{', (select match from (select regexp_substr(match, '^[1-9][05]|1[0-5][05]|160$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9][05]|1[0-5][05]|160$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '14', '0', '0']
                    ELSE ARRAY['cz/rychlostnik/N_s_pruhy/unknown', NULL, '14', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:speed_limit:type" = 'immediate' THEN ARRAY['cz/rychlostnik/immediate@top', NULL, '0', '9', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '323'])
            
            -- (CZ) Speed limit (light)
            WHEN "railway:signal:speed_limit" IN ('CZ', 'CZ-D1:hlavni_navestidlo', 'Cs-D1') AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^(1[0-6]|[1-9]|20)0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('cz/hlavni_navestidlo-speeds/hlavni_navestidlo-light-{', (select match from (select regexp_substr(match, '^(1[0-6]|[1-9]|20)0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-6]|[1-9]|20)0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo-speeds/hlavni_navestidlo-light-unknown', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '324'])
            
            -- (CZ) Hlavní návěstidlo
            WHEN "railway:signal:main" IN ('CZ', 'CZ-D1:hlavni_navestidlo') AND "railway:signal:main:form" = 'light' AND "railway:signal:speed_limit" IN ('CZ', 'CZ-D1:hlavni_navestidlo')
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:volno'] <@ "railway:signal:main:states" THEN ARRAY['cz/hlavni_navestidlo/GRWY-GY', NULL, '24.75', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo/GRWY-GY', NULL, '24.75', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'CZ-D1:rychlost_30' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_30-sign@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_50' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_50-sign@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_60' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_60@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_80' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_80@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_100' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_100@bottom', NULL, '0', '11.999977', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '330'])
            
            -- (CZ) Hlavní návěstidlo
            WHEN "railway:signal:combined" IN ('CZ', 'CZ-D1:hlavni_navestidlo') AND "railway:signal:combined:form" = 'light' AND "railway:signal:speed_limit" IN ('CZ', 'CZ-D1:hlavni_navestidlo')
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:opakovani_vystraha'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGWRY-YWY', NULL, '30', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha', 'CZ-D1:volno'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YGRWY-YY', NULL, '30', '0', '0']
                    WHEN ARRAY['CZ-D1:stuj', 'CZ-D1:vystraha'] <@ "railway:signal:combined:states" THEN ARRAY['cz/hlavni_navestidlo/YRWY-YY', NULL, '24.75', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo/YGRWY-YY', NULL, '30', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'CZ-D1:rychlost_30' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_30-sign@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_50' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_50-sign@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_60' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_60@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_80' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_80@bottom', NULL, '0', '11.999977', '0']
                    WHEN 'CZ-D1:rychlost_100' = ANY("railway:signal:speed_limit:states") THEN ARRAY['cz/hlavni_navestidlo-speeds/rychlost_100@bottom', NULL, '0', '11.999977', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '334'])
            
            -- (DE) East German branch line speed signals (Lf 4)
            WHEN "railway:signal:speed_limit" = 'DE-ESO:dr:lf4' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(100|[2-8]0|1?[05])$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/lf4-dr-sign-down-speed-limit-{', (select match from (select regexp_substr(match, '^(100|[2-8]0|1?[05])$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(100|[2-8]0|1?[05])$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/lf4-dr-sign-down-speed-limit-empty', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '419'])
            
            -- (DE) Speed signals (Zs 3) (light)
            WHEN "railway:signal:speed_limit" = 'DE-ESO:zs3' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([1-9]|1[0-6])0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/zs3-sign-up-{', (select match from (select regexp_substr(match, '^([1-9]|1[0-6])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([1-9]|1[0-6])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/zs3-empty-sign-up', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '463'])
            
            -- (DE) Speed signals (Zs 3) (light)
            WHEN "railway:signal:speed_limit" = 'DE-ESO:zs3' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^([1-9]|1[0-6]|20)0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/zs3-light-{', (select match from (select regexp_substr(match, '^([1-9]|1[0-6]|20)0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([1-9]|1[0-6]|20)0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/zs3-light-unknown', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '464'])
            
            -- (DE) Tram speed limit (G 2a) (sign)
            WHEN "railway:signal:speed_limit" IN ('DE-BOStrab:g2', 'DE-BOStrab:g2a', 'DE-BSVG:g2a') AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(5|[1-7][05])$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/bostrab/g2a-{', (select match from (select regexp_substr(match, '^(5|[1-7][05])$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(5|[1-7][05])$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['de/bostrab/g2a-empty', NULL, '16', '0', '0']
                  END, ARRAY['tram', "railway:signal:speed_limit:deactivated"::text, 'speed', '465'])
            
            -- (DE) Tram speed limit (G 2b) (light)
            WHEN "railway:signal:speed_limit" IN ('DE-BOStrab:g2', 'DE-BOStrab:g2b') AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^[1-7]0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/bostrab/g2b-{', (select match from (select regexp_substr(match, '^[1-7]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-7]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/bostrab/g2b-empty', NULL, '19', '0', '0']
                  END, ARRAY['tram', "railway:signal:speed_limit:deactivated"::text, 'speed', '466'])
            
            -- (DE) Tram signal G3
            WHEN "railway:signal:speed_limit" = 'DE-BOStrab:g3' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/g3', NULL, '16', '0', '0'], ARRAY['tram', "railway:signal:speed_limit:deactivated"::text, 'speed', '467'])
            
            -- (DE) DVB end of increased speed limit (G 3a)
            WHEN "railway:signal:speed_limit" = 'DE-DVB:g3a' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['de/dvb/g3a', NULL, '16', '0', '0'], ARRAY['tram', "railway:signal:speed_limit:deactivated"::text, 'speed', '468'])
            
            -- (DE) German tram speed limit signals as signs (G 4)
            WHEN "railway:signal:speed_limit" = 'DE-BOStrab:g4' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(100|[1-9]0|[235]5)$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/bostrab/g4-{', (select match from (select regexp_substr(match, '^(100|[1-9]0|[235]5)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(100|[1-9]0|[235]5)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['de/bostrab/g4-empty', NULL, '16', '0', '0']
                  END, ARRAY['tram', "railway:signal:speed_limit:deactivated"::text, 'speed', '469'])
            
            -- (DE) DVB short speed restriction (G 5)
            WHEN "railway:signal:speed_limit" = 'DE-DVB:g5' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[1-5]0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/dvb/g5-{', (select match from (select regexp_substr(match, '^[1-5]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-5]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['de/dvb/g5-empty', NULL, '16', '0', '0']
                  END, ARRAY['tram', "railway:signal:speed_limit:deactivated"::text, 'speed', '470'])
            
            -- (DE) Hannover tram speed limit G5
            WHEN "railway:signal:speed_limit" = 'DE-UESTRA:g5' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(5|[1-6][05])$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/bostrab/g5-{', (select match from (select regexp_substr(match, '^(5|[1-6][05])$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(5|[1-6][05])$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/bostrab/g5-empty', NULL, '19', '0', '0']
                  END, ARRAY['tram', "railway:signal:speed_limit:deactivated"::text, 'speed', '471'])
            
            -- (DE) East German line speed signal "Eckentafel" (Lf 5)
            WHEN "railway:signal:speed_limit" = 'DE-ESO:dr:lf5' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['de/lf5-dv301-sign', NULL, '16', '0', '0'], ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '472'])
            
            -- (DE) West German line speed signal "Anfangstafel" (Lf 5)
            WHEN "railway:signal:speed_limit" = 'DE-ESO:db:lf5' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['de/lf5-ds301-sign', NULL, '16', '0', '0'], ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '473'])
            
            -- (DE) German line speed signals (Lf 7)
            WHEN "railway:signal:speed_limit" = 'DE-ESO:lf7' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(5|15|[1-9]0|1[0-9]0|200)$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/lf7-sign-{', (select match from (select regexp_substr(match, '^(5|15|[1-9]0|1[0-9]0|200)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(5|15|[1-9]0|1[0-9]0|200)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['de/lf7-empty-sign', NULL, '16', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '474'])
            
            -- (DE) Hamburger Hochbahn L4
            WHEN "railway:signal:speed_limit" = 'DE-HHA:l4' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['de/hha/l4', NULL, '16', '0', '0'], ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '475'])
            
            -- (DE) Anfangsscheibe
            WHEN "railway:signal:speed_limit" IN ('DE-ESO:lf2', 'DE-ESO:db:lf2') AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['de/lf2-sign', NULL, '19', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '476'])
            
            -- (DE) Langsamfahrbeginnscheibe
            WHEN "railway:signal:speed_limit" = 'DE-ESO:dr:lf1/2' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(5|[1-9]0|1[0-2]0)$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('de/lf1-2-sign-{', (select match from (select regexp_substr(match, '^(5|[1-9]0|1[0-2]0)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(5|[1-9]0|1[0-2]0)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '18.436634', '0', '0']
                    ELSE ARRAY['de/lf1-2-empty-sign', NULL, '18.436634', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '477'])
            
            -- (DE) Endscheibe
            WHEN "railway:signal:speed_limit" = 'DE-ESO:lf3' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['de/lf3-sign', NULL, '18.436634', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '478'])
            
            -- (DE) Ende der Geschwindigkeitsbeschränkung (sign)
            WHEN "railway:signal:speed_limit" = 'DE-ESO:db:zs10' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['de/zs10-sign', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '479'])
            
            -- (DE) Ende der Geschwindigkeitsbeschränkung (light)
            WHEN "railway:signal:speed_limit" = 'DE-ESO:db:zs10' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(ARRAY['de/zs10-light', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '480'])
            
            -- (FI) Nopeusmerkki, speed signal
            WHEN "railway:signal:speed_limit" = 'FI:T-101' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([2-6]0)$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('fi/t-101-{', (select match from (select regexp_substr(match, '^([2-6]0)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([2-6]0)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '18', '0', '0']
                    ELSE ARRAY['fi/t-101-empty', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '574'])
            
            -- (FI) Merkitty nopeus päättyy -merkki, end of speed limit
            WHEN "railway:signal:speed_limit" = 'FI:T-110' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-110', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '576'])
            
            -- (FI) JKV-nopeus, JKV speed limit
            WHEN "railway:signal:speed_limit" = 'FI:T-115' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-115', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '577'])
            
            -- (FR) Pancarte Z & TIV-D
            WHEN "railway:signal:speed_limit" = 'FR:Z' AND "railway:signal:speed_limit:form" = 'sign' AND "railway:signal:speed_limit_distant" = 'FR:TIV-D' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([3-9]0|1[0-3]0)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('fr/Z-TIV-distance-sign-{', (select match from (select regexp_substr(match, '^([3-9]0|1[0-3]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([3-9]0|1[0-3]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '31.68', '0', '0']
                    ELSE ARRAY['fr/Z-TIV-distance-empty-sign', NULL, '31.68', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '614'])
            
            -- (FR) Pancarte Z & TIV-D (B)
            WHEN "railway:signal:speed_limit" = 'FR:Z' AND "railway:signal:speed_limit:form" = 'sign' AND "railway:signal:speed_limit_distant" = 'FR:TIV-D_B' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[5-9]0|200)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('fr/Z-TIV-type-B-{', (select match from (select regexp_substr(match, '^(1[5-9]0|200)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[5-9]0|200)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '28.147003', '0', '0']
                    ELSE ARRAY['fr/Z-TIV-type-B-empty', NULL, '28.147003', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '615'])
            
            -- (FR) Pancarte Z
            WHEN "railway:signal:speed_limit" = 'FR:Z' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['fr/Tableau_Z', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '616'])
            
            -- (FR) Tableau R
            WHEN "railway:signal:speed_limit" = 'FR:R' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['fr/Tableau_R', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '617'])
            
            -- (FR) Chevron pointe en bas
            WHEN "railway:signal:speed_limit" = 'FR:Chevron' AND "railway:signal:speed_limit:pointing" = 'downwards' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['fr/chevron pointe en bas', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '619'])
            
            -- (FR) Chevron pointe en haut
            WHEN "railway:signal:speed_limit" = 'FR:Chevron' AND "railway:signal:speed_limit:pointing" = 'upwards' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['fr/chevron pointe en haut', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '620'])
            
            -- (GB) Permissible speed indicator
            WHEN "railway:signal:speed_limit" = 'GB-NR:speed_limit' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN '^((5|[1-9][05]|1[0-2][05])( mph)?|1[3-9][05]|200)$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('gb/speed-limit-{', (select match from (select regexp_substr(match, '^((5|[1-9][05]|1[0-2][05])( mph)?|1[3-9][05]|200)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^((5|[1-9][05]|1[0-2][05])( mph)?|1[3-9][05]|200)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '20', '0', '0']
                    ELSE ARRAY['gb/speed-limit-empty', NULL, '20', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'left' = ANY("railway:signal:speed_limit:turn_direction") THEN ARRAY['gb/directional-arrow-speed-limit-left@top', NULL, '0', '8', '0']
                    WHEN 'right' = ANY("railway:signal:speed_limit:turn_direction") THEN ARRAY['gb/directional-arrow-speed-limit-right@top', NULL, '0', '8', '0']
                    WHEN ARRAY['left', 'right'] <@ "railway:signal:speed_limit:turn_direction" THEN ARRAY['gb/directional-arrow-speed-limit-left-right@top', NULL, '0', '8', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '696'])
            
            -- (IT) Triangle speed limit
            WHEN "railway:signal:speed_limit" = 'IT:TRI' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '30' = ANY("railway:signal:speed_limit:speed") THEN ARRAY['it/tri-30', NULL, '19.096858', '0', '0']
                    WHEN '60' = ANY("railway:signal:speed_limit:speed") THEN ARRAY['it/tri-60', NULL, '19.096858', '0', '0']
                    ELSE ARRAY['it/tri-unknown', NULL, '19.096858', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '709'])
            
            -- (IT) Rappel
            WHEN "railway:signal:speed_limit" = 'IT:RAP' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '100' = ANY("railway:signal:speed_limit:speed") THEN ARRAY['it/rappel-100', NULL, '16.055547', '0', '0']
                    WHEN '60' = ANY("railway:signal:speed_limit:speed") THEN ARRAY['it/rappel-60', NULL, '16.055547', '0', '0']
                    ELSE ARRAY['it/rappel-30', NULL, '16.055547', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '710'])
            
            -- (IT) Speed limit
            WHEN "railway:signal:speed_limit" IN ('IT:1R', 'IT:2R', 'IT:3R') AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^160$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('it/speed-{', (select match from (select regexp_substr(match, '^160$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^160$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '9.753845', '0', '0']
                    ELSE ARRAY['it/speed-unknown', NULL, '9.753845', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '711'])
            
            -- (NL) L signal
            WHEN "railway:signal:speed_limit" = 'NL' AND "railway:signal:speed_limit:form" = 'light' AND ARRAY['L', 'off'] <@ "railway:signal:speed_limit:states"
              THEN array_cat(ARRAY['nl/276', NULL, '20.081963', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '762'])
            
            -- (NL) H signal
            WHEN "railway:signal:speed_limit" = 'NL' AND "railway:signal:speed_limit:form" = 'light' AND ARRAY['H', 'off'] <@ "railway:signal:speed_limit:states"
              THEN array_cat(ARRAY['nl/277', NULL, '20.081963', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '763'])
            
            -- (NL) X/G signal
            WHEN "railway:signal:speed_limit" = 'NL' AND "railway:signal:speed_limit:form" = 'light' AND ARRAY['X', 'G', 'off'] <@ "railway:signal:speed_limit:states"
              THEN array_cat(ARRAY['nl/279', NULL, '21.42076', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '764'])
            
            -- (NL) speed limit (sign)
            WHEN "railway:signal:speed_limit" = 'NL:314' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[1-9]0|1[0-46]0|[12]5|125$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('nl/314-{', (select match from (select regexp_substr(match, '^[1-9]0|1[0-46]0|[12]5|125$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9]0|1[0-46]0|[12]5|125$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '15.757436', '0', '0']
                    ELSE ARRAY['nl/314-empty', NULL, '15.757436', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '766'])
            
            -- (NL) speed limit increase (sign)
            WHEN "railway:signal:speed_limit" = 'NL:316' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[3-9]0|1[0-46]0|125$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('nl/316-{', (select match from (select regexp_substr(match, '^[3-9]0|1[0-46]0|125$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[3-9]0|1[0-46]0|125$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '15.403672', '0', '0']
                    ELSE ARRAY['nl/316-empty', NULL, '15.433679', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '767'])
            
            -- (NL) speed limit (light)
            WHEN "railway:signal:speed_limit" = 'NL' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^[1-9]0|1[0-9]0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('nl/speed_limit_light-{', (select match from (select regexp_substr(match, '^[1-9]0|1[0-9]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9]0|1[0-9]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '17.735492', '0', '0']
                    ELSE ARRAY['nl/speed_limit_light-empty', NULL, '17.735492', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '769'])
            
            -- (NL) tunnel entry speed limit
            WHEN "railway:signal:speed_limit" = 'NL:281' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[3-8]0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('nl/281-{', (select match from (select regexp_substr(match, '^[3-8]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[3-8]0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '15.753849', '0', '0']
                    ELSE ARRAY['nl/281-empty', NULL, '15.753849', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '771'])
            
            -- (NL) advisory speed (sign)
            WHEN "railway:signal:speed_limit" = 'NL:282' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^15|35|[4-9]0|120$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('nl/282-{', (select match from (select regexp_substr(match, '^15|35|[4-9]0|120$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^15|35|[4-9]0|120$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '18.571669', '0', '0']
                    ELSE ARRAY['nl/282-empty', NULL, '18.571669', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '772'])
            
            -- (NL) advisory speed (light)
            WHEN "railway:signal:speed_limit" = 'NL:282' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^15|35|[4-9]0|120$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('nl/282a-{', (select match from (select regexp_substr(match, '^15|35|[4-9]0|120$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^15|35|[4-9]0|120$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '21.453593', '0', '0']
                    ELSE ARRAY['nl/282a-empty', NULL, '21.453593', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '773'])
            
            -- (NZ) Dynamic Speed Indicator
            WHEN "railway:signal:speed_limit" IN ('NZ:speed_indicator', 'AU:VIC:medium') AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(ARRAY['nz/speed_indicator', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '832'])
            
            -- (PL) Wskaźnik odcinka ograniczonej prędkości (czoło pociągu) (W9)
            WHEN "railway:signal:speed_limit" = 'PL-PKP:w9' AND "railway:signal:speed_limit:form" = 'sign' AND "railway:signal:speed_limit:caption" = 'C'
              THEN array_cat(ARRAY['pl/w9-C', NULL, '23', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '893'])
            
            -- (PL) Wskaźnik odcinka ograniczonej prędkości (W9)
            WHEN "railway:signal:speed_limit" = 'PL-PKP:w9' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[0-9]|2[0-4])0|[1-9][05]$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('pl/w9-{', (select match from (select regexp_substr(match, '^(1[0-9]|2[0-4])0|[1-9][05]$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-9]|2[0-4])0|[1-9][05]$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '23', '0', '0']
                    ELSE ARRAY['pl/w9-empty', NULL, '23', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '894'])
            
            -- (PL) Wskaźniki podwyższenia prędkości (W21)
            WHEN "railway:signal:speed_limit" = 'PL-PKP:w21' AND "railway:signal:speed_limit:form" IN ('light', 'sign')
              THEN array_cat(CASE 
                    WHEN '^([5-9]|1[0-5])0$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('pl/w21-{', (select match from (select regexp_substr(match, '^([5-9]|1[0-5])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([5-9]|1[0-5])0$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['pl/w21-empty', NULL, '16', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '895'])
            
            -- (PL) Wskaźnik W21wg
            WHEN "railway:signal:speed_limit" = 'PL-PKP:w21wg' AND "railway:signal:speed_limit:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^([58]|15)$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('pl/w21wg-{', (select match from (select regexp_substr(match, '^([58]|15)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([58]|15)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '15.99', '0', '0']
                    ELSE ARRAY['pl/w21wg-empty', NULL, '15.99', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '896'])
            
            -- (PL) Wskaźnik zmiany prędkości (W27a)
            WHEN "railway:signal:speed_limit" = 'PL-PKP:w27a' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[0-9]|2[0-4])0|[1-9][05]$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('pl/w27a-{', (select match from (select regexp_substr(match, '^(1[0-9]|2[0-4])0|[1-9][05]$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-9]|2[0-4])0|[1-9][05]$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['pl/w27a-empty', NULL, '16', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '897'])
            
            -- (PL) Wskaźnik ważenia składu (W30)
            WHEN "railway:signal:speed_limit" = 'PL-PKP:w30' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^5$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('pl/w30-{', (select match from (select regexp_substr(match, '^5$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^5$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '15.707715', '0', '0']
                    ELSE ARRAY['pl/w30-empty', NULL, '15.707715', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit:deactivated"::text, 'speed', '898'])
            
            -- (PL) Ograniczenie prędkości (BT-1)
            WHEN "railway:signal:speed_limit" = 'PL-tram:bt-1' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[1-9][05]$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('pl/bt-1-{', (select match from (select regexp_substr(match, '^[1-9][05]$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9][05]$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['pl/bt-1-empty', NULL, '16', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '899'])
            
            -- (PL) Koniec ograniczenia prędkości (BT-2)
            WHEN "railway:signal:speed_limit" = 'PL-tram:bt-2' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[1-9][05]$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('pl/bt-2-{', (select match from (select regexp_substr(match, '^[1-9][05]$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9][05]$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['pl/bt-2-empty', NULL, '16', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '900'])
            
            -- (SE) Hastighetstavla
            WHEN "railway:signal:speed_limit" = 'SE:hastighetstavla' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([3-9]0|1[0-5]0|1[01]5)$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('se/hastighetstavla-{', (select match from (select regexp_substr(match, '^([3-9]0|1[0-5]0|1[01]5)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([3-9]0|1[0-5]0|1[01]5)$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['se/hastighetstavla-empty', NULL, '16', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '932'])
            
            -- (SE) Hastighetstavla med pilspets uppåt
            WHEN "railway:signal:speed_limit" = 'SE:hastighetstavla med pilspets uppåt' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^140$' ~!@# ANY("railway:signal:speed_limit:speed") THEN ARRAY[CONCAT('se/hastighetstavla-pilspets-uppåt-{', (select match from (select regexp_substr(match, '^140$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^140$') as match from (select unnest("railway:signal:speed_limit:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '29.180108', '0', '0']
                    ELSE ARRAY['se/hastighetstavla-pilspets-uppåt-empty', NULL, '29.180108', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit:deactivated"::text, 'speed', '933'])
            
            -- Unknown signal (speed_limit)
            ELSE
              ARRAY['general/signal-unknown-speed_limit', NULL, '17.1', '0', '0', NULL, 'false', 'speed', NULL]
        END
      END as feature_speed_limit,
      CASE 
        WHEN "railway:signal:speed_limit_distant" IS NOT NULL THEN
          CASE 
            -- (AT) Geschwindigkeitsvoranzeiger (sign)
            WHEN "railway:signal:speed_limit_distant" = 'AT-V2:geschwindigkeitsvoranzeiger' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[02]|[1-9])0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('at/geschwindigkeitsvoranzeiger-sign-{', (select match from (select regexp_substr(match, '^(1[02]|[1-9])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[02]|[1-9])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['at/geschwindigkeitsvoranzeiger-empty-sign', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '5'])
            
            -- (AT) Geschwindigkeitsvoranzeiger (light)
            WHEN "railway:signal:speed_limit_distant" = 'AT-V2:geschwindigkeitsvoranzeiger' AND "railway:signal:speed_limit_distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^(1[0-4]|[2-9])0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('at/geschwindigkeitsvoranzeiger-light-{', (select match from (select regexp_substr(match, '^(1[0-4]|[2-9])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-4]|[2-9])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '14', '0', '0']
                    ELSE ARRAY['at/geschwindigkeitsvoranzeiger-empty-light', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '6'])
            
            -- (AT) Ankündigungstafel
            WHEN "railway:signal:speed_limit_distant" = 'AT-V2:ankündigungstafel' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[0-4]0|10|[2-9][05])$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('at/ankuendigungstafel-sign-{', (select match from (select regexp_substr(match, '^(1[0-4]0|10|[2-9][05])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-4]0|10|[2-9][05])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['at/ankuendigungstafel-empty-sign', NULL, '19', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '7'])
            
            -- (AT) Ankündigungssignal
            WHEN "railway:signal:speed_limit_distant" = 'AT-V2:ankündigungssignal' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[1-6]0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('at/ankündigungssignal-{', (select match from (select regexp_substr(match, '^[1-6]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-6]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['at/ankündigungssignal-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '8'])
            
            -- (AT) Ankündigung EK sicht
            WHEN "railway:signal:speed_limit_distant" = 'AT-V2:ankündigung_ek-sicht' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(ARRAY['at/ankündigung-ek-sicht', NULL, '19', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '9'])
            
            -- (BE) Announcement of a speed limit
            WHEN "railway:signal:speed_limit_distant" = 'BE:PVA' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^5$|^[0-9]0$|^1[0-5]0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('be/PVA-{', (select match from (select regexp_substr(match, '^5$|^[0-9]0$|^1[0-5]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^5$|^[0-9]0$|^1[0-5]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '17.320995', '0', '0']
                    ELSE ARRAY['be/PVA-empty', NULL, '17.321001', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '228'])
            
            -- (BE) Speed sign for distant signal
            WHEN "railway:signal:speed_limit_distant" = 'BE:PVSA' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^90$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('be/PVSA-{', (select match from (select regexp_substr(match, '^90$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^90$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '17.320995', '0', '0']
                    ELSE ARRAY['be/PVSA-empty', NULL, '17.321001', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '232'])
            
            -- (BE) Distant speed limit light (part of main signal)
            WHEN "railway:signal:speed_limit_distant" = 'BE:ARV' AND "railway:signal:speed_limit_distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^([4-9]0)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('be/ARV-{', (select match from (select regexp_substr(match, '^([4-9]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([4-9]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['be/ARV-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '252'])
            
            -- (CH) Vorsignal verminderte Geschwindigkeit
            WHEN "railway:signal:speed_limit_distant" IN ('CH-FDV:209', 'CH-FDV:210') AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([6-9][05]|1[0-1][05])$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('ch/fdv-209-{', (select match from (select regexp_substr(match, '^([6-9][05]|1[0-1][05])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([6-9][05]|1[0-1][05])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['ch/fdv-209-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '275'])
            
            -- (CH) Vorsignal verminderte Geschwindigkeit für Neigetechnikzüge
            WHEN "railway:signal:speed_limit_distant" = 'CH-FDV:213' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^1[1-4]0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('ch/fdv-213-{', (select match from (select regexp_substr(match, '^1[1-4]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^1[1-4]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['ch/fdv-213-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '278'])
            
            -- (CH) Geschwindigkeits-Ankündigung
            WHEN "railway:signal:speed_limit_distant" IN ('CH-FDV:540', 'CH-FDV:541') AND "railway:signal:speed_limit_distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^([4-9]|1[0-2])0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('ch/fdv-540-{', (select match from (select regexp_substr(match, '^([4-9]|1[0-2])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([4-9]|1[0-2])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['ch/fdv-540-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '282'])
            
            -- (CZ) Předvěstník NS
            WHEN "railway:signal:speed_limit_distant" IN ('CZ-D1:predvestnik_ns') AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN 'none' = ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY['cz/predvestnik/NS/end', NULL, '30', '0', '0']
                    WHEN '^[1-9]0|1[0-6]0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('cz/predvestnik/NS/{', (select match from (select regexp_substr(match, '^[1-9]0|1[0-6]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9]0|1[0-6]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '24', '0', '0']
                    ELSE ARRAY['cz/predvestnik/NS/unknown', NULL, '24', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:speed_limit_distant:shortened" THEN ARRAY['cz/shortened@top', NULL, '0', '6.709679', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '319'])
            
            -- (CZ) Předvěstník N
            WHEN "railway:signal:speed_limit_distant" IN ('CZ', 'CZ-D1:predvestnik_n', 'CZ-D1:horni_predvestnik_n', 'Cs-D1') AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN '^[1-9]0|1[0-6]0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('cz/predvestnik/N/{', (select match from (select regexp_substr(match, '^[1-9]0|1[0-6]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9]0|1[0-6]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '17', '0', '0']
                    ELSE ARRAY['cz/predvestnik/N/unknown', NULL, '17', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:speed_limit_distant:shortened" THEN ARRAY['cz/shortened@top', NULL, '0', '6.709679', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '320'])
            
            -- (CZ) Distant speed limit (light)
            WHEN "railway:signal:speed_limit_distant" IN ('CZ', 'CZ-D1:hlavni_navestidlo', 'CZ-D1:samostatna_predvest', 'Cs-D1') AND "railway:signal:speed_limit_distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^(1[0-6]|[1-9]|20)0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('cz/hlavni_navestidlo-speeds/hlavni_navestidlo-distant-light-{', (select match from (select regexp_substr(match, '^(1[0-6]|[1-9]|20)0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-6]|[1-9]|20)0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['cz/hlavni_navestidlo-speeds/hlavni_navestidlo-distant-light-unknown', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '325'])
            
            -- (DE) Speed signals (Zs 3v) (sign)
            WHEN "railway:signal:speed_limit_distant" = 'DE-ESO:zs3v' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[0-6]|[1-9])0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('de/zs3v-sign-down-{', (select match from (select regexp_substr(match, '^(1[0-6]|[1-9])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-6]|[1-9])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/zs3v-empty-sign-down', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '415'])
            
            -- (DE) Speed signals (Zs 3v) (light)
            WHEN "railway:signal:speed_limit_distant" = 'DE-ESO:zs3v' AND "railway:signal:speed_limit_distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^([1-9]|1[0-6]|20)0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('de/zs3v-light-{', (select match from (select regexp_substr(match, '^([1-9]|1[0-6]|20)0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([1-9]|1[0-6]|20)0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/zs3v-light-unknown', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '416'])
            
            -- (DE) West German branch line speed signals (Lf 4 DS 301)
            WHEN "railway:signal:speed_limit_distant" = 'DE-ESO:db:lf4' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([2-8]0|1?[05])$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('de/lf4-ds301-sign-down-{', (select match from (select regexp_substr(match, '^([2-8]0|1?[05])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([2-8]0|1?[05])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/lf4-ds301-empty-sign-down', NULL, '19', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '417'])
            
            -- (DE) East German branch line speed signals (Lf 4)
            WHEN "railway:signal:speed_limit_distant" = 'DE-ESO:dr:lf4' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(100|[2-8]0|1?[05])$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('de/lf4-dr-sign-down-{', (select match from (select regexp_substr(match, '^(100|[2-8]0|1?[05])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(100|[2-8]0|1?[05])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/lf4-dr-sign-down-empty', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '418'])
            
            -- (DE) German line speed signals (Lf 6)
            WHEN "railway:signal:speed_limit_distant" = 'DE-ESO:lf6' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^((1[0-9]|[1-9])0|5|15)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('de/lf6-sign-down-{', (select match from (select regexp_substr(match, '^((1[0-9]|[1-9])0|5|15)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^((1[0-9]|[1-9])0|5|15)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/lf6-empty-sign-down', NULL, '19', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '420'])
            
            -- (DE) Langsamfahrscheibe
            WHEN "railway:signal:speed_limit_distant" = 'DE-ESO:lf1' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(5|15|[1-9]0|1[0-9]0|200)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('de/lf1-sign-down-{', (select match from (select regexp_substr(match, '^(5|15|[1-9]0|1[0-9]0|200)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(5|15|[1-9]0|1[0-9]0|200)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/lf1-empty-sign-down', NULL, '19', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '421'])
            
            -- (DE) Hamburger Hochbahn L1
            WHEN "railway:signal:speed_limit_distant" = 'DE-HHA:l1' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([3-7]0)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('de/hha/l1-sign-{', (select match from (select regexp_substr(match, '^([3-7]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([3-7]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/hha/l1-empty-sign', NULL, '19', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '422'])
            
            -- (DE) Tram distance speed limit (G 1a) (sign)
            WHEN "railway:signal:speed_limit_distant" IN ('DE-BOStrab:g1', 'DE-BOStrab:g1a', 'DE-BSVG:g1a') AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(5|[1-7][0-5])$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('de/bostrab/g1a-{', (select match from (select regexp_substr(match, '^(5|[1-7][0-5])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(5|[1-7][0-5])$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/bostrab/g1a-empty', NULL, '16', '0', '0']
                  END, ARRAY['tram', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '423'])
            
            -- (DE) Tram distance speed limit (G 1b) (light)
            WHEN "railway:signal:speed_limit_distant" IN ('DE-BOStrab:g1', 'DE-BOStrab:g1b') AND "railway:signal:speed_limit_distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^[1-7]0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('de/bostrab/g1b-{', (select match from (select regexp_substr(match, '^[1-7]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-7]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '19', '0', '0']
                    ELSE ARRAY['de/bostrab/g1b-empty', NULL, '19', '0', '0']
                  END, ARRAY['tram', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '424'])
            
            -- (FI) Nopeusmerkin etumerkki, distant signal
            WHEN "railway:signal:speed_limit_distant" = 'FI:T-102' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([2-6]0)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('fi/t-102-{', (select match from (select regexp_substr(match, '^([2-6]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([2-6]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '18', '0', '0']
                    ELSE ARRAY['fi/t-102-empty', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '575'])
            
            -- (FR) Pancarte Z & TIV-D
            WHEN "railway:signal:speed_limit" = 'FR:Z' AND "railway:signal:speed_limit:form" = 'sign' AND "railway:signal:speed_limit_distant" = 'FR:TIV-D' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN NULL
            
            -- (FR) Pancarte Z & TIV-D (B)
            WHEN "railway:signal:speed_limit" = 'FR:Z' AND "railway:signal:speed_limit:form" = 'sign' AND "railway:signal:speed_limit_distant" = 'FR:TIV-D_B' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN NULL
            
            -- (FR) Tableau P
            WHEN "railway:signal:speed_limit_distant" = 'FR:P' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(ARRAY['fr/Tableau_P', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '618'])
            
            -- (FR) TIV-D (mobile)
            WHEN "railway:signal:speed_limit_distant" = 'FR:TIV-D' AND "railway:signal:speed_limit_distant:mobile" AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([3-9]0|1[0-3]0)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('fr/TIV-distance-light-{', (select match from (select regexp_substr(match, '^([3-9]0|1[0-3]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([3-9]0|1[0-3]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '20', '0', '0']
                    ELSE ARRAY['fr/TIV-distance-empty-light', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '621'])
            
            -- (FR) TIV-D (fixed)
            WHEN "railway:signal:speed_limit_distant" = 'FR:TIV-D' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([3-9]0|1[0-3]0)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('fr/TIV-distance-sign-{', (select match from (select regexp_substr(match, '^([3-9]0|1[0-3]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([3-9]0|1[0-3]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['fr/TIV-distance-empty-sign', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '622'])
            
            -- (FR) TIV-D (B)
            WHEN "railway:signal:speed_limit_distant" = 'FR:TIV-D_B' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[5-9]0|200)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('fr/TIV-type-B-{', (select match from (select regexp_substr(match, '^(1[5-9]0|200)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[5-9]0|200)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '12.147003', '0', '0']
                    ELSE ARRAY['fr/TIV-type-B-empty', NULL, '12.147003', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '623'])
            
            -- (FR) TIV-D (C)
            WHEN "railway:signal:speed_limit_distant" = 'FR:TIV-D_C' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[5-9]0)$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('fr/TIV-type-C-{', (select match from (select regexp_substr(match, '^(1[5-9]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[5-9]0)$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '12.147003', '0', '0']
                    ELSE ARRAY['fr/TIV-type-C-empty', NULL, '12.147003', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '624'])
            
            -- (IT) Distant speed limit (distance 1)
            WHEN "railway:signal:speed_limit_distant" IN ('IT:1R', 'IT:2R', 'IT:3R') AND "railway:signal:speed_limit_distant:form" = 'sign' AND "railway:signal:speed_limit_distant:distance" = '1'
              THEN array_cat(CASE 
                    WHEN '^160$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('it/speed-distant-1-{', (select match from (select regexp_substr(match, '^160$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^160$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '15.285085', '0', '0']
                    ELSE ARRAY['it/speed-distant-1-unknown', NULL, '15.285055', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '712'])
            
            -- (IT) Distant speed limit (distance 2)
            WHEN "railway:signal:speed_limit_distant" IN ('IT:1R', 'IT:2R', 'IT:3R') AND "railway:signal:speed_limit_distant:form" = 'sign' AND "railway:signal:speed_limit_distant:distance" = '2'
              THEN array_cat(CASE 
                    WHEN '^160$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('it/speed-distant-2-{', (select match from (select regexp_substr(match, '^160$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^160$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '15.285085', '0', '0']
                    ELSE ARRAY['it/speed-distant-2-unknown', NULL, '15.284394', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '713'])
            
            -- (NL) distant speed limit distant (sign)
            WHEN "railway:signal:speed_limit_distant" = 'NL:313' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^[1-9]0|1[0-4]0|125$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('nl/313-{', (select match from (select regexp_substr(match, '^[1-9]0|1[0-4]0|125$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9]0|1[0-4]0|125$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '15.413925', '0', '0']
                    ELSE ARRAY['nl/313-empty', NULL, '15.413925', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '765'])
            
            -- (NL) distant speed limit (light)
            WHEN "railway:signal:speed_limit_distant" = 'NL' AND "railway:signal:speed_limit_distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^[1-9]0|1[0-9]0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('nl/speed_limit_distant_light-{', (select match from (select regexp_substr(match, '^[1-9]0|1[0-9]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-9]0|1[0-9]0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '17.735493', '0', '0']
                    ELSE ARRAY['nl/speed_limit_distant_light-empty', NULL, '17.735493', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '768'])
            
            -- (NL) tunnel distant speed limit
            WHEN "railway:signal:speed_limit_distant" = 'NL:286' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^80$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('nl/286-{', (select match from (select regexp_substr(match, '^80$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^80$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '17.126584', '0', '0']
                    ELSE ARRAY['nl/286-empty', NULL, '17.126584', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '770'])
            
            -- (PL) Tarcza zwolnić bieg (D6)
            WHEN "railway:signal:speed_limit_distant" = 'PL-PKP:d6' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([1-9]|1[0-9]|2[0-4])0$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('pl/d6-{', (select match from (select regexp_substr(match, '^([1-9]|1[0-9]|2[0-4])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([1-9]|1[0-9]|2[0-4])0$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['pl/d6-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '891'])
            
            -- (PL) Wskaźnik ograniczenia prędkości (W8)
            WHEN "railway:signal:speed_limit_distant" = 'PL-PKP:w8' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[0-9]|2[0-4])0|[1-9][05]$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('pl/w8-{', (select match from (select regexp_substr(match, '^(1[0-9]|2[0-4])0|[1-9][05]$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-9]|2[0-4])0|[1-9][05]$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '16', '0', '0']
                    ELSE ARRAY['pl/w8-empty', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '892'])
            
            -- (SE) Orienteringstavla för lägre hastighet
            WHEN "railway:signal:speed_limit_distant" = 'SE:lägre_hastighet' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(1[0-4]0|[7-9]0)|105$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('se/orienteringstavla-hastighet-{', (select match from (select regexp_substr(match, '^(1[0-4]0|[7-9]0)|105$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(1[0-4]0|[7-9]0)|105$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '27.767088', '0', '0']
                    ELSE ARRAY['se/orienteringstavla-hastighet-empty', NULL, '27.767088', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '934'])
            
            -- (SE) Orienteringstavla med tilläggsskylt ”ATC-överskridande”
            WHEN "railway:signal:speed_limit_distant" = 'SE:atc_överskridande' AND "railway:signal:speed_limit_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^150$' ~!@# ANY("railway:signal:speed_limit_distant:speed") THEN ARRAY[CONCAT('se/orienteringstavla-hastighet-atc-överskridande-{', (select match from (select regexp_substr(match, '^150$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^150$') as match from (select unnest("railway:signal:speed_limit_distant:speed") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '42.097591', '0', '0']
                    ELSE ARRAY['se/orienteringstavla-hastighet-atc-överskridande-empty', NULL, '42.097591', '0', '0']
                  END, ARRAY['line', "railway:signal:speed_limit_distant:deactivated"::text, 'speed', '935'])
            
            -- Unknown signal (speed_limit_distant)
            ELSE
              ARRAY['general/signal-unknown-speed_limit_distant', NULL, '17.1', '0', '0', NULL, 'false', 'speed', NULL]
        END
      END as feature_speed_limit_distant,
      CASE 
        WHEN "railway:signal:minor" IS NOT NULL THEN
          CASE 
            -- (AT) Sperrsignale (sign)
            WHEN "railway:signal:minor" = 'AT-V2:weiterfahrt_verboten' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['at/weiterfahrt-verboten', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '22'])
            
            -- (AT) Sperrsignale (semaphore)
            WHEN "railway:signal:minor" = 'AT-V2:sperrsignal' AND "railway:signal:minor:form" = 'semaphore'
              THEN array_cat(ARRAY['at/weiterfahrt-erlaubt', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '23'])
            
            -- (AT) Schutzsignal (abfahrt)
            WHEN "railway:signal:minor" = 'AT-V2:schutzsignal' AND "railway:signal:minor:form" = 'light' AND "railway:signal:departure" = 'AT-V2:abfahrt' AND "railway:signal:departure:form" = 'light'
              THEN array_cat(ARRAY['at/schutzsignal-abfahrt', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '24'])
            
            -- (AT) Schutzsignal
            WHEN "railway:signal:minor" = 'AT-V2:schutzsignal' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['at/schutzsignal', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '25'])
            
            -- (AT) Fahrwegende
            WHEN "railway:signal:minor" = 'AT-V2:fahrwegende' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['at/fahrwegende', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '26'])
            
            -- (AT) Haltscheibe
            WHEN "railway:signal:minor" = 'AT-V2:haltscheibe' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['at/haltscheibe', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '27'])
            
            -- (AU) Location Marker Board
            WHEN "railway:signal:minor" = 'AU:MNWSW:location' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/metro/location', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '66'])
            
            -- (AU) CS
            WHEN "railway:signal:minor" = 'AU:LightRail:NSW:CS' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/CS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '72'])
            
            -- (AU) Train Detector
            WHEN "railway:signal:minor" = 'AU:LightRail:NSW:D' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/D', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '73'])
            
            -- (AU) Points Indicator
            WHEN "railway:signal:minor" = 'AU:LightRail:PI' AND "railway:signal:minor:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN 'stop' = ANY("railway:signal:minor:states") THEN ARRAY['au/LightRail/signals/PI/stop@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'stop_red' = ANY("railway:signal:minor:states") THEN ARRAY['au/LightRail/signals/PI/stop_red@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'straight' = ANY("railway:signal:minor:states") THEN ARRAY['au/LightRail/signals/PI/straight@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'right' = ANY("railway:signal:minor:states") THEN ARRAY['au/LightRail/signals/PI/right@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'left' = ANY("railway:signal:minor:states") THEN ARRAY['au/LightRail/signals/PI/left@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '112'])
            
            -- (AU) Signal Operated Points Indicator
            WHEN "railway:signal:minor" = 'AU:LightRail:SPI' AND "railway:signal:minor:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN 'locked' = ANY("railway:signal:minor:states") THEN ARRAY['au/LightRail/signals/SPI/locked@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'straight' = ANY("railway:signal:minor:states") THEN ARRAY['au/LightRail/signals/SPI/straight@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'right' = ANY("railway:signal:minor:states") THEN ARRAY['au/LightRail/signals/SPI/right@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'left' = ANY("railway:signal:minor:states") THEN ARRAY['au/LightRail/signals/SPI/left@bottom', NULL, '0', '10', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '113'])
            
            -- (AU) Close Up
            WHEN "railway:signal:minor" = 'AU:NSW:close_up' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/close_up', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '161'])
            
            -- (AU) Low Speed
            WHEN "railway:signal:minor" = 'AU:NSW:low_speed' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/low_speed', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '162'])
            
            -- (AU) Mainline Indicator
            WHEN "railway:signal:minor" = 'AU:NSW:MLI' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'WYR' = ANY("railway:signal:minor:states") THEN ARRAY['au/nsw/signals/MLI/WYR', NULL, '21', '0', '0']
                    WHEN 'WR' = ANY("railway:signal:minor:states") THEN ARRAY['au/nsw/signals/MLI/WR', NULL, '15', '0', '0']
                    ELSE ARRAY['au/nsw/signals/MLI/unknown', NULL, '21', '0', '0']
                  END, ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '165'])
            
            -- (AU) Landmark
            WHEN "railway:signal:minor" = 'AU:VIC:landmark' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/landmark', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '188'])
            
            -- (AU) Automatic Indicator
            WHEN "railway:signal:minor" = 'AU:VIC:A' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/automatic', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '201'])
            
            -- (BE) Signal d'Arrêt Simplifié
            WHEN "railway:signal:minor" = 'BE:SAS'
              THEN array_cat(ARRAY['be/SAS', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '243'])
            
            -- (CH) Minor signal
            WHEN "railway:signal:minor" = 'CH-FDV:232' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['ch/fdv-232', NULL, '11.660505', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '274'])
            
            -- (DE) tram minor stop sign Sh 1
            WHEN "railway:signal:minor" = 'DE-BOStrab:sh1' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/sh1', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '349'])
            
            -- (DE) minor light signals type Sh
            WHEN "railway:signal:minor" = 'DE-ESO:sh' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(CASE 
                    WHEN "railway:signal:minor:height" = 'normal' THEN ARRAY['de/sh1-light-normal', NULL, '10.74747', '0', '0']
                    ELSE ARRAY['de/sh0-light-dwarf', NULL, '8', '0', '0']
                  END, ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '350'])
            
            -- (DE) minor light signals type Sh attached to main signals
            WHEN "railway:signal:minor" = 'DE-ESO:sh1' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['de/sh1-light-dwarf', NULL, '7.68464', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '351'])
            
            -- (DE) minor semaphore signals type Sh with wn7
            WHEN "railway:signal:minor" = 'DE-ESO:sh' AND "railway:signal:minor:form" = 'semaphore' AND ARRAY['DE-ESO:sh0', 'DE-ESO:wn7'] <@ "railway:signal:minor:states"
              THEN array_cat(ARRAY['de/wn7-semaphore-normal', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '352'])
            
            -- (DE) minor semaphore signals type Sh
            WHEN "railway:signal:minor" = 'DE-ESO:sh' AND "railway:signal:minor:form" = 'semaphore'
              THEN array_cat(CASE 
                    WHEN "railway:signal:minor:height" = 'normal' THEN ARRAY['de/sh1-semaphore-normal', NULL, '12', '0', '0']
                    ELSE ARRAY['de/sh0-semaphore-dwarf', NULL, '11', '0', '0']
                  END, ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '353'])
            
            -- (DE) minor sign signal type Sh
            WHEN "railway:signal:minor" = 'DE-ESO:sh0' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['de/sh0-sign', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '354'])
            
            -- (DE) Sh 2 buffer stop
            WHEN "railway:signal:minor" = 'DE-ESO:sh2' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['de/sh2', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '355'])
            
            -- (DE) tram signal Sh 2
            WHEN "railway:signal:minor" = 'DE-BOStrab:sh2' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/sh2', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '356'])
            
            -- (DE) Hamburger Hochbahn Sh 3
            WHEN "railway:signal:minor" = 'DE-HHA:sh3' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['de/hha/sh3', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '357'])
            
            -- (DE) Karlsruhe AVG end of EBO structure gauge Ra 14
            WHEN "railway:signal:minor" = 'DE-AVG:ra14' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['de/avg/ra14', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '408'])
            
            -- (DE) give way to other traffic
            WHEN "railway:signal:minor" = 'DE-BOStrab:st23' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/st23', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '505'])
            
            -- (DE) priority over other traffic
            WHEN "railway:signal:minor" IN ('DE-BOStrab:st24', 'DE-BOStrab:st24a') AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:minor" = 'DE-BOStrab:st24a' THEN ARRAY['de/bostrab/st24a', NULL, '12', '0', '0']
                    ELSE ARRAY['de/bostrab/st24', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '506'])
            
            -- (DE) apply brakes
            WHEN "railway:signal:minor" = 'DE-BOStrab:st25' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/st25', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '507'])
            
            -- (DE) DVB curve lubrication system ahead (So 11)
            WHEN "railway:signal:minor" = 'DE-DVB:so11' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['de/dvb/so11', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '508'])
            
            -- (DE) RSAG Halt bei Überflutung (So 13)
            WHEN "railway:signal:minor:form" = 'sign' AND "railway:signal:minor" = 'DE-RSAG:so13'
              THEN array_cat(ARRAY['de/rsag/so13', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '509'])
            
            -- (FI) minor light signals type Lo at moveable bridges
            WHEN "railway:signal:minor" = 'FI:Lo' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['fi/lo0', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '563'])
            
            -- (NL) middenvoetbrugsein
            WHEN "railway:signal:minor" = 'NL:middenvoetbrugsein' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['nl/215b', NULL, '17.969912', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '755'])
            
            -- (NZ) Restricted-speed Light
            WHEN "railway:signal:minor" = 'NZ:R' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['nz/R', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '806'])
            
            -- (NZ) Low-speed Light
            WHEN "railway:signal:minor" = 'NZ:low_speed' AND "railway:signal:minor:form" = 'light'
              THEN array_cat(ARRAY['nz/low_speed', NULL, '9', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '807'])
            
            -- (NZ) TWC Siding
            WHEN "railway:signal:minor" = 'NZ:TWC_siding' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['nz/TWC_siding', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '808'])
            
            -- (NZ) TWC Intermediate Board
            WHEN "railway:signal:minor" = 'NZ:TWC_intermediate' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['nz/TWC_intermediate', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '809'])
            
            -- (PL) Sygnalizator sygnału zastępczego (Sz)
            WHEN "railway:signal:minor" = 'PL-PKP:sz' AND "railway:signal:minor:form" = 'light' AND 'PL-PKP:sz' = ANY("railway:signal:minor:substitute_signal")
              THEN array_cat(ARRAY['pl/sz-1', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '845'])
            
            -- (PL) Tarcza zaporowa kształtowa (Tz, ruchoma, nieruchoma)
            WHEN "railway:signal:minor" = 'PL-PKP:z' AND "railway:signal:minor:form" IN ('semaphore', 'sign') AND ARRAY['PL-PKP:z1', 'PL-PKP:z2'] && "railway:signal:minor:states"
              THEN array_cat(CASE 
                    WHEN "railway:signal:minor:form" = 'semaphore' THEN ARRAY['pl/z-semaphore', NULL, '12', '0', '0']
                    ELSE ARRAY['pl/z-sign', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '846'])
            
            -- (PL) Tarcza zaporowa świetlna (Tz)
            WHEN "railway:signal:minor" = 'PL-PKP:z' AND "railway:signal:minor:form" = 'light' AND ARRAY['PL-PKP:s1', 'PL-PKP:ms2'] && "railway:signal:minor:states"
              THEN array_cat(CASE 
                    WHEN 'PL-PKP:sz' = ANY("railway:signal:minor:substitute_signal") THEN ARRAY['pl/z-2-s1', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/z-1-s1', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '847'])
            
            -- (PL) Tarcza zatrzymania (D1)
            WHEN "railway:signal:minor" = 'PL-PKP:d1' AND "railway:signal:minor:form" = 'sign'
              THEN array_cat(ARRAY['pl/d1', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '855'])
            
            -- (PL) Wskaźnik unieważnienia (W3)
            WHEN "railway:signal:minor" = 'PL-PKP:w3' AND "railway:signal:minor:form" IN ('light', 'semaphore')
              THEN array_cat(ARRAY['pl/w3', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:minor:deactivated"::text, 'signals', '859'])
            
            -- Unknown signal (minor)
            ELSE
              ARRAY['general/signal-unknown-minor', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_minor,
      CASE 
        WHEN "railway:signal:minor_distant" IS NOT NULL THEN
          CASE 
            -- (PL) Tarcza ostrzegawcza nieruchoma (DO)
            WHEN "railway:signal:minor_distant" = 'PL-PKP:do' AND "railway:signal:minor_distant:form" = 'sign'
              THEN array_cat(ARRAY['pl/do', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:minor_distant:deactivated"::text, 'signals', '848'])
            
            -- Unknown signal (minor_distant)
            ELSE
              ARRAY['general/signal-unknown-minor_distant', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_minor_distant,
      CASE 
        WHEN "railway:signal:passing" IS NOT NULL THEN
          CASE 
            -- (DE) tram passing prohibited sign So 5
            WHEN "railway:signal:passing" = 'DE-BOStrab:so5' AND "railway:signal:passing:form" = 'sign' AND "railway:signal:passing:type" = 'no_passing'
              THEN array_cat(ARRAY['de/bostrab/so5', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:passing:deactivated"::text, 'signals', '365'])
            
            -- (DE) DVB tram passing prohibited, give way to oncoming trams (So 5a)
            WHEN "railway:signal:passing" = 'DE-DVB:so5a' AND "railway:signal:passing:form" = 'sign'
              THEN array_cat(ARRAY['de/dvb/so5a', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:passing:deactivated"::text, 'signals', '366'])
            
            -- (DE) tram passing prohibited end sign So 6
            WHEN "railway:signal:passing" = 'DE-BOStrab:so6' AND "railway:signal:passing:form" = 'sign' AND "railway:signal:passing:type" = 'passing_allowed'
              THEN array_cat(ARRAY['de/bostrab/so6', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:passing:deactivated"::text, 'signals', '367'])
            
            -- (PL) Wskaźnik jazdy pociągu towarowego (W22)
            WHEN "railway:signal:passing" = 'PL-PKP:w22' AND "railway:signal:passing:form" = 'sign'
              THEN array_cat(ARRAY['pl/w22', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:passing:deactivated"::text, 'signals', '856'])
            
            -- Unknown signal (passing)
            ELSE
              ARRAY['general/signal-unknown-passing', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_passing,
      CASE 
        WHEN "railway:signal:shunting" IS NOT NULL THEN
          CASE 
            -- (AT) Hauptsignal mit verschubsignal & ersatzsignal
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND 'AT-V2:ersatzsignal' = ANY("railway:signal:main:substitute_signal") AND "railway:signal:shunting" = 'AT-V2:verschubsignal' AND "railway:signal:shunting:form" = 'light'
              THEN NULL
            
            -- (AT) Hauptsignal mit verschubsignal & vorsichtssignal
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND 'AT-V2:vorsichtssignal' = ANY("railway:signal:main:substitute_signal") AND "railway:signal:shunting" = 'AT-V2:verschubsignal' AND "railway:signal:shunting:form" = 'light'
              THEN NULL
            
            -- (AT) Hauptsignal mit verschubsignal
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND "railway:signal:shunting" = 'AT-V2:verschubsignal' AND "railway:signal:shunting:form" = 'light'
              THEN NULL
            
            -- (AT) Verschubsignal
            WHEN "railway:signal:shunting" = 'AT-V2:verschubsignal' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(CASE 
                    WHEN "railway:signal:shunting:height" = 'dwarf' THEN ARRAY['at/verschubsignal-dwarf', NULL, '12', '0', '0']
                    ELSE ARRAY['at/verschubsignal', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '28'])
            
            -- (AT) Verschubhalttafel
            WHEN "railway:signal:shunting" = 'AT-V2:verschubhalttafel' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['at/verschubhalttafel', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '29'])
            
            -- (AT) Wartesignal mit "Verschubverbot aufgehoben"
            WHEN "railway:signal:shunting" = 'AT-V2:wartesignal' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['at/wartesignal-verschubverbot-aufgehoben', NULL, '20.181561', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '30'])
            
            -- (AT) Wartesignal ohne "Verschubverbot aufgehoben"
            WHEN "railway:signal:shunting" = 'AT-V2:wartesignal' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['at/wartesignal', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '31'])
            
            -- (AU) Shunting Limit
            WHEN "railway:signal:shunting" = 'AU:LightRail:NSW:LM' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/LM', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '75'])
            
            -- (AU) Shunting Limit
            WHEN "railway:signal:shunting" = 'AU:LightRail:NSW:SL' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/SL', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '85'])
            
            -- (AU) Shunting Zone
            WHEN "railway:signal:shunting" = 'AU:LightRail:NSW:SZ' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/SZ', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '88'])
            
            -- (AU) Shunting Limit
            WHEN "railway:signal:shunting" = 'AU:NSW:shunting_limit' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/shunting_limit', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '136'])
            
            -- (AU) Shunt Signal
            WHEN "railway:signal:shunting" = 'AU:NSW:shunt' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(CASE 
                    WHEN "railway:signal:shunting:shape" = 'vertical' THEN ARRAY['au/nsw/signals/shunt_vertical', NULL, '15', '0', '0']
                    ELSE ARRAY['au/nsw/signals/shunt_box', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '145'])
            
            -- (AU) Intermediate Shunt Signal Signal
            WHEN "railway:signal:shunting" = 'AU:NSW:intermediate' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(CASE 
                    WHEN "railway:signal:shunting:shape" = 'vertical' THEN ARRAY['au/nsw/signals/shunt_vertical_int', NULL, '22.5', '0', '0']
                    ELSE ARRAY['au/nsw/signals/shunt_box_int', NULL, '15', '0', '0']
                  END, ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '146'])
            
            -- (AU) Calling-On / Shunt Ahead
            WHEN "railway:signal:shunting" = 'AU:NSW:subsidiary' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/subsidiary', NULL, '9', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '159'])
            
            -- (AU) Limit of Shunt
            WHEN "railway:signal:shunting" = 'AU:VIC:shunting_limit' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/shunting_limit', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '186'])
            
            -- (AU) 2-position shunt signal
            WHEN "railway:signal:shunting" = 'AU:VIC:shunt_2' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/shunt2', NULL, '12.5', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '221'])
            
            -- (AU) 3-position shunt signal
            WHEN "railway:signal:shunting" = 'AU:VIC:shunt_3' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/shunt3', NULL, '18.5', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '222'])
            
            -- (BE) Petit Signal d'Arrêt (light)
            WHEN "railway:signal:shunting" IN ('BE:PSA', 'BE-SME:small_signal_triangle') AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['be/PSA-light', NULL, '15.326743', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '244'])
            
            -- (BE) Petit Signal d'Arrêt (sign)
            WHEN "railway:signal:shunting" = 'BE:PSA' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['be/PSA-sign', NULL, '14.199162', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '245'])
            
            -- (BE) (BME) Shunting signal, 2 color
            WHEN "railway:signal:shunting" = 'BE-SME:small_signal_two_colour'
              THEN array_cat(ARRAY['be/bme/shunting_twocolour_ny', NULL, '17', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '246'])
            
            -- (CZ) Označník
            WHEN "railway:signal:shunting" = 'CZ-D1:oznacnik' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['cz/oznacnik', NULL, '28', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '310'])
            
            -- (CZ) Posun zakázán
            WHEN "railway:signal:shunting" IN ('CZ', 'CZ-D1:posun_zakazan', 'Cs-D1') AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['cz/posun_zakazan', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '311'])
            
            -- (CZ) Vyčkávací návěstidlo (neproměnné)
            WHEN "railway:signal:shunting" = 'CZ-D1:vyckavaci_navestidlo' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['cz/vyckavaci_navestidlo/sign', NULL, '11.084856', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '312'])
            
            -- (CZ) Vyčkávací návěstidlo (světelné)
            WHEN "railway:signal:shunting" = 'CZ-D1:vyckavaci_navestidlo' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['cz/vyckavaci_navestidlo/light', NULL, '17.760156', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '313'])
            
            -- (CZ) Opakovací seřaďovací návěstidlo
            WHEN "railway:signal:shunting" = 'CZ-D1:seradovaci_navestidlo' AND "railway:signal:shunting:form" = 'light' AND "railway:signal:shunting:repeated"
              THEN array_cat(ARRAY['cz/seradovaci_navestidlo/W-X', NULL, '9', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '314'])
            
            -- (CZ) Seřaďovací návěstidlo
            WHEN "railway:signal:shunting" IN ('CZ', 'CZ-D1:seradovaci_navestidlo', 'Cs-D1', 'Cs-D1:', 'Cs-D1:_', 'Cs-D1:Se', 'Cs-D1:Se_', 'Cs-D1:Se _') AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['cz/seradovaci_navestidlo/WB-B', NULL, '14.25', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '315'])
            
            -- (CZ) Hranice obvodu nákladiště nebo vlečky
            WHEN "railway:signal:shunting" = 'CZ-D1:hranice_obvodu_nakladiste_nebo_vlecky' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['cz/hranice_obvodu_nakladiste_nebo_vlecky', NULL, '10.5', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '316'])
            
            -- (CZ) Návěstidlo výkolejky
            WHEN "railway:signal:shunting" = 'CZ-D1:navestidlo_vykolejky' AND "railway:signal:shunting:form" = 'semaphore'
              THEN array_cat(ARRAY['cz/navestidlo_vykolejky', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '317'])
            
            -- (DE) shunting stop sign Ra 10
            WHEN "railway:signal:shunting" = 'DE-ESO:ra10' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['de/ra10', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '344'])
            
            -- (DE) main signal invalid for shunting trains Zs 103 (sign)
            WHEN "railway:signal:shunting" = 'DE-ESO:zs103' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['de/zs103', NULL, '23', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '345'])
            
            -- (DE) shunting signal Ra 11 without Sh 1
            WHEN "railway:signal:shunting" = 'DE-ESO:ra11' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['de/ra11-sign', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '346'])
            
            -- (DE) shunting signal Ra 11 with Sh 1
            WHEN "railway:signal:shunting" = 'DE-ESO:ra11' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['de/ra11-sh1', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '347'])
            
            -- (DE) shunting signal Ra 11b (without Sh 1)
            WHEN "railway:signal:shunting" = 'DE-ESO:ra11b' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['de/ra11b', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '348'])
            
            -- (FI) shunting light signals type Ro (new)
            WHEN "railway:signal:shunting" = 'FI:Ro' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['fi/ro0-new', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '564'])
            
            -- (FI) Shunting signal type Yo
            WHEN "railway:signal:shunting" = 'FI:Yo' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['fi/yo-shunting', NULL, '36', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '565'])
            
            -- (FR) Shunting marker
            WHEN "railway:signal:shunting" IN ('FR:JAL_MAN', 'FR:jalon_de_manoeuvre_TVM') AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:position" = 'right' THEN ARRAY['fr/JAL_MAN-left', NULL, '18', '0', '0']
                    ELSE ARRAY['fr/JAL_MAN-right', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '642'])
            
            -- (FR) Shunting to garage
            WHEN "railway:signal:shunting" = 'FR:G' AND "railway:signal:shunting:form" IN ('sign', 'light')
              THEN array_cat(ARRAY['fr/G', NULL, '16.16', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '666'])
            
            -- (FR) Shunting to depot
            WHEN "railway:signal:shunting" = 'FR:D' AND "railway:signal:shunting:form" IN ('sign', 'light')
              THEN array_cat(ARRAY['fr/D', NULL, '16.16', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '667'])
            
            -- (GB) Shunting
            WHEN "railway:signal:shunting" = 'GB-NR:shunting' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['gb/shunting', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '686'])
            
            -- (GB) Shunting limit
            WHEN "railway:signal:shunting" = 'GB-NR:limit' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['gb/limit-shunt', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '687'])
            
            -- (IT) Marmotte
            WHEN "railway:signal:shunting" = 'IT:MAR' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['it/marmotte', NULL, '12.39226', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '717'])
            
            -- (IT) Segnali alti di manovra
            WHEN "railway:signal:shunting" = 'IT:MAN' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['it/MAN', NULL, '14.013781', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '718'])
            
            -- (IT) Picchetto limite di manovra
            WHEN "railway:signal:shunting" = 'IT:PLIM' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['it/PLIM', NULL, '18.269035', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '719'])
            
            -- (JP) Shunting signal
            WHEN "railway:signal:shunting" = 'JP:入換信号機' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['jp/shunting', NULL, '13.133429', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '726'])
            
            -- (NL) dwarf shunting signals
            WHEN "railway:signal:main" = 'NL' AND "railway:signal:main:form" = 'light' AND "railway:signal:main:height" = 'dwarf' AND "railway:signal:shunting" = 'NL' AND "railway:signal:shunting:form" = 'light'
              THEN NULL
            
            -- (NL) main shunting light
            WHEN "railway:signal:main" = 'NL' AND "railway:signal:main:form" = 'light' AND "railway:signal:shunting" = 'NL' AND "railway:signal:shunting:form" = 'light'
              THEN NULL
            
            -- (NL) block marker light
            WHEN "railway:signal:shunting" IN ('NL:227', 'NL') AND "railway:signal:shunting:form" = 'light' AND ARRAY['NL:227a', 'NL:227c'] <@ "railway:signal:shunting:states"
              THEN array_cat(ARRAY['nl/227a', NULL, '10.000002', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '743'])
            
            -- (NZ) Shunting Limit
            WHEN "railway:signal:shunting" = 'NZ:shunting_limit' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['nz/shunting_limit', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '813'])
            
            -- (NZ) Shunt Signal (3-position)
            WHEN "railway:signal:shunting" = 'NZ:shunt' AND "railway:signal:shunting:form" = 'light' AND 'RYG' = ANY("railway:signal:shunting:states")
              THEN array_cat(ARRAY['nz/shunt3', NULL, '18.5', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '814'])
            
            -- (NZ) Shunt Signal (2-position)
            WHEN "railway:signal:shunting" = 'NZ:shunt' AND "railway:signal:shunting:form" = 'light' AND 'RY' = ANY("railway:signal:shunting:states")
              THEN array_cat(ARRAY['nz/shunt2', NULL, '12.5', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '815'])
            
            -- (PL) Tarcza manewrowa kształtowa (Tm)
            WHEN "railway:signal:shunting" = 'PL-PKP:m' AND "railway:signal:shunting:form" IN ('semaphore', 'sign')
              THEN array_cat(CASE 
                    WHEN "railway:signal:shunting:form" = 'semaphore' THEN ARRAY['pl/m-semaphore', NULL, '18', '0', '0']
                    ELSE ARRAY['pl/m-sign', NULL, '14.23', '0', '0']
                  END, ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '851'])
            
            -- (PL) Tarcza manewrowa świetlna (Tm)
            WHEN "railway:signal:shunting" = 'PL-PKP:ms' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'PL-PKP:ms2' = ANY("railway:signal:shunting:states") THEN ARRAY['pl/ms-2', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/ms-1', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '852'])
            
            -- (PL) Wskaźnik przetaczania (W5)
            WHEN "railway:signal:shunting" = 'PL-PKP:w5' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['pl/w5', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '861'])
            
            -- (SE) Växlingsdvärgsignal
            WHEN "railway:signal:shunting" = 'SE:Växlingsdvärgsignal' AND "railway:signal:shunting:form" = 'light'
              THEN array_cat(ARRAY['se/shunting', NULL, '16.773959', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '928'])
            
            -- (SE) Skyddsstopplykta
            WHEN "railway:signal:shunting" = 'SE:Skyddsstopplykta' AND "railway:signal:shunting:form" = 'sign'
              THEN array_cat(ARRAY['se/skyddsstopplykta', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:shunting:deactivated"::text, 'signals', '929'])
            
            -- Unknown signal (shunting)
            ELSE
              ARRAY['general/signal-unknown-shunting', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_shunting,
      CASE 
        WHEN "railway:signal:shunting_route" IS NOT NULL THEN
          CASE 
            -- (AU) Shunt Route Indicator
            WHEN "railway:signal:shunting_route" = 'AU:NSW:stencil' AND "railway:signal:shunting_route:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/stencil', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:shunting_route:deactivated"::text, 'signals', '160'])
            
            -- Unknown signal (shunting_route)
            ELSE
              ARRAY['general/signal-unknown-shunting_route', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_shunting_route,
      CASE 
        WHEN "railway:signal:radio" IS NOT NULL THEN
          CASE 
            -- (DE) radio channel notice
            WHEN "railway:signal:radio" = 'DE-ESO:zugfunk-kanalhinweis' AND "railway:signal:radio:form" = 'sign'
              THEN array_cat(ARRAY['de/zugfunk', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:radio:deactivated"::text, 'signals', '510'])
            
            -- (NZ) Entering Radio Channel Area
            WHEN "railway:signal:radio" = 'NZ:channel_area' AND "railway:signal:radio:form" = 'sign'
              THEN array_cat(ARRAY['nz/channel_area', NULL, '8', '0', '0'], ARRAY[NULL, "railway:signal:radio:deactivated"::text, 'signals', '805'])
            
            -- (PL) Wskaźnik kanału radiowego (W28)
            WHEN "railway:signal:radio" = 'PL-PKP:w28' AND "railway:signal:radio:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:radio:frequency" ~ '^(R[1-8]|S5)$' THEN ARRAY[CONCAT('pl/w28-{', regexp_substr("railway:signal:radio:frequency", '^(R[1-8]|S5)$', 1, 1, '', 1), '}'), regexp_substr("railway:signal:radio:frequency", '^(R[1-8]|S5)$', 1, 1, '', 1), '16', '0', '0']
                    ELSE ARRAY['pl/w28-{R1}', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:radio:deactivated"::text, 'signals', '872'])
            
            -- (PL) Wskaźnik nawiązania łączności (W29)
            WHEN "railway:signal:radio" = 'PL-PKP:w29' AND "railway:signal:radio:form" = 'sign'
              THEN array_cat(ARRAY['pl/w29', NULL, '6', '0', '0'], ARRAY[NULL, "railway:signal:radio:deactivated"::text, 'signals', '873'])
            
            -- (PL) Wskaźnik początku obowiązywania systemu ERTMS/GSM-R (W33)
            WHEN "railway:signal:radio" = 'PL-PKP:w33' AND "railway:signal:radio:form" = 'sign'
              THEN array_cat(ARRAY['pl/w33', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:radio:deactivated"::text, 'signals', '875'])
            
            -- (PL) Wskaźnik końca obowiązywania systemu ERTMS/GSM-R (W34)
            WHEN "railway:signal:radio" = 'PL-PKP:w34' AND "railway:signal:radio:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:radio:frequency" ~ '^R[1-8]$' THEN ARRAY[CONCAT('pl/w34-{', regexp_substr("railway:signal:radio:frequency", '^R[1-8]$', 1, 1, '', 1), '}'), regexp_substr("railway:signal:radio:frequency", '^R[1-8]$', 1, 1, '', 1), '30', '0', '0']
                    ELSE ARRAY['pl/w34', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:radio:deactivated"::text, 'signals', '876'])
            
            -- Unknown signal (radio)
            ELSE
              ARRAY['general/signal-unknown-radio', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_radio,
      CASE 
        WHEN "railway:signal:stop" IS NOT NULL THEN
          CASE 
            -- (AT) Zuglaufmeldestelle (SLB)
            WHEN "railway:signal:stop" = 'AT-SLB:zuglaufmeldestelle' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['at/zuglaufmeldestelle', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '40'])
            
            -- (AT) Haltepunkt
            WHEN "railway:signal:stop" = 'AT-V2:haltepunkt' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['at/haltepunkt', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '42'])
            
            -- (AU) Fixed Red
            WHEN "railway:signal:stop" = 'AU:MNWSW:fixed_red' AND "railway:signal:stop:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/metro/fixed_red', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '68'])
            
            -- (AU) Fixed Red
            WHEN "railway:signal:stop" = 'AU:LightRail:fixed_red' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/fixed_red', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '74'])
            
            -- (AU) Stop
            WHEN "railway:signal:stop" = 'AU:LightRail:NSW:stop' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/stop', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '86'])
            
            -- (AU) Stop with Instruction
            WHEN "railway:signal:stop" = 'AU:LightRail:NSW:SWI' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/SWI', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '87'])
            
            -- (AU) Compulsory Stop Mark
            WHEN "railway:signal:stop" = 'AU:LightRail:VIC:double_yellow' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/double_yellow', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '97'])
            
            -- (AU) Optional Stop Mark
            WHEN "railway:signal:stop" = 'AU:LightRail:VIC:double_yellow_dashed' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/double_yellow_dashed', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '98'])
            
            -- (AU) Check Point Mark
            WHEN "railway:signal:stop" = 'AU:LightRail:VIC:double_yellow_chevron' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/double_yellow_chevron', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '99'])
            
            -- (AU) Shunting Stop Mark (A/Z/W)
            WHEN "railway:signal:stop" = 'AU:LightRail:VIC:single_yellow_half' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/single_yellow_half', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '100'])
            
            -- (AU) Shunting Stop Mark (B/C1/D1)
            WHEN "railway:signal:stop" = 'AU:LightRail:VIC:double_yellow_half' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/double_yellow_half', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '101'])
            
            -- (AU) Shunting Stop Mark (C2/D2/E)
            WHEN "railway:signal:stop" = 'AU:LightRail:VIC:triple_yellow_half' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/triple_yellow_half', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '102'])
            
            -- (AU) Stopping Place Studs
            WHEN "railway:signal:stop" = 'AU:LightRail:VIC:stop_studs_square' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/stop_studs_square', NULL, '7', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '103'])
            
            -- (AU) Stopping Place Studs (Long Trams)
            WHEN "railway:signal:stop" = 'AU:LightRail:VIC:stop_studs_diamond' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/stop_studs_diamond', NULL, '7', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '104'])
            
            -- (AU) Provisional Stop
            WHEN "railway:signal:stop" = 'AU:LightRail:VIC:provisional' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/provisional_stop', NULL, '7', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '105'])
            
            -- (AU) Catch Point
            WHEN "railway:signal:stop" = 'AU:NSW:catch_point' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/catch_point', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '121'])
            
            -- (AU) Derail
            WHEN "railway:signal:stop" = 'AU:NSW:derail' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/derail', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '122'])
            
            -- (AU) Loading Gauge Limit
            WHEN "railway:signal:stop" = 'AU:NSW:loading_gauge' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/loading_gauge', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '132'])
            
            -- (AU) Stop Position
            WHEN "railway:signal:stop" = 'AU:NSW:stop_position' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN ARRAY['X', 'XPT', 'XPL'] && "railway:signal:stop:states" THEN ARRAY['au/nsw/signs/stop_position/X@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'DD' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/DD@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '10' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/10@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '8' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/8@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '8D' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/8D@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '8H' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/8H@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '8V' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/8V@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '6' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/6@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '6V' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/6V@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '4' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/4@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['4H', 'H4'] && "railway:signal:stop:states" THEN ARRAY['au/nsw/signs/stop_position/4H@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '4V' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/4V@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '2' = ANY("railway:signal:stop:states") THEN ARRAY['au/nsw/signs/stop_position/2@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['2C', 'C2'] && "railway:signal:stop:states" THEN ARRAY['au/nsw/signs/stop_position/2C@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN ARRAY['2E', 'E2'] && "railway:signal:stop:states" THEN ARRAY['au/nsw/signs/stop_position/2E@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '138'])
            
            -- (AU) Safety Runoff Area
            WHEN "railway:signal:stop" = 'AU:NSW:safety_overrun' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/safety_overrun', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '139'])
            
            -- (AU) Stop
            WHEN "railway:signal:stop" = 'AU:NSW:stop' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/stop', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '140'])
            
            -- (AU) End of Track
            WHEN "railway:signal:stop" = 'AU:NSW:end_of_track' AND "railway:signal:stop:form" = 'light' AND 'R' = ANY("railway:signal:stop:states")
              THEN array_cat(ARRAY['au/nsw/signals/end_of_track_R', NULL, '7.5', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '150'])
            
            -- (AU) End of Track
            WHEN "railway:signal:stop" = 'AU:NSW:end_of_track' AND "railway:signal:stop:form" = 'light' AND 'WR' = ANY("railway:signal:stop:states")
              THEN array_cat(ARRAY['au/nsw/signals/end_of_track_WR', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '151'])
            
            -- (AU) Baulks
            WHEN "railway:signal:stop" = 'AU:VIC:baulks' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/baulks', NULL, '5.2', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '190'])
            
            -- (AU) End of Track
            WHEN "railway:signal:stop" = 'AU:VIC:end_of_track' AND "railway:signal:stop:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/end_of_track', NULL, '7.5', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '195'])
            
            -- (BE) Buffer stop (sign)
            WHEN "railway:signal:stop" = 'BE:RH' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['be/RH-sign', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '247'])
            
            -- (BE) Buffer stop (light)
            WHEN "railway:signal:stop" = 'BE:RH' AND "railway:signal:stop:form" = 'light'
              THEN array_cat(ARRAY['be/RH-light', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '248'])
            
            -- (BE) Stop position
            WHEN "railway:signal:stop" = 'BE:PMQ' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^(2|3|4|6|8|10|12)$' ~!@# ANY("railway:signal:stop:carriages") THEN ARRAY[CONCAT('be/PMQ-{', (select match from (select regexp_substr(match, '^(2|3|4|6|8|10|12)$') as match from (select unnest("railway:signal:stop:carriages") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^(2|3|4|6|8|10|12)$') as match from (select unnest("railway:signal:stop:carriages") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '14', '0', '0']
                    ELSE ARRAY['be/PMQ-unknown', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '249'])
            
            -- (BE) End of platform
            WHEN "railway:signal:stop" = 'BE:PREQ' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['be/PREQ', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '250'])
            
            -- (CZ) Konec nástupiště
            WHEN "railway:signal:stop" IN ('CZ-D1:konec_nastupiste', 'Cs-D1') AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['cz/konec_nastupiste', NULL, '10.5', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '337'])
            
            -- (CZ) Místo zastavení
            WHEN "railway:signal:stop" = 'CZ-D1:misto_zastaveni' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:stop:caption" = 'Os' THEN ARRAY['cz/misto_zastaveni/os', NULL, '10.5', '0', '0']
                    ELSE ARRAY['cz/misto_zastaveni/blank', NULL, '10.5', '0', '0']
                  END, ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '338'])
            
            -- (CZ) Lichoběžníková tabulka
            WHEN "railway:signal:stop" = 'CZ-D1:lichobeznikova_tabulka' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['cz/lichobeznikova_tabulka', NULL, '10.759342', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '339'])
            
            -- (DE) stop demand post Ne 5 (sign)
            WHEN "railway:signal:stop" = 'DE-ESO:ne5' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['de/ne5-sign', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '369'])
            
            -- (DE) train length stopping marker
            WHEN "railway:signal:stop" = 'DE-ESO:zuglänge' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['de/zuglaenge', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '371'])
            
            -- (DE) stop demand post BOStrab Sh 7 (sign)
            WHEN "railway:signal:stop" = 'DE-BOStrab:sh7' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/sh7', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '372'])
            
            -- (FI) Stopping position (single)
            WHEN "railway:signal:stop" IN ('FI:T-270A', 'FI:T-270B', 'FI:T-270C', 'FI:T-270D') AND "railway:signal:stop:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['fi/t-270', NULL, '24.666666', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop:caption" IN ('1', '2', '3', '4', '5') THEN ARRAY[CONCAT('fi/t-270-{', "railway:signal:stop:caption", '}'), "railway:signal:stop:caption", '24.666668', '0', '0']
                    ELSE ARRAY['fi/t-270-unknown', NULL, '24.666668', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop" = 'FI:T-270B' THEN ARRAY['fi/t-270-right', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-270C' THEN ARRAY['fi/t-270-left', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-270D' THEN ARRAY['fi/t-270-both', NULL, '24.666668', '0', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '556'])
            
            -- (FI) Stopping position (combination)
            WHEN "railway:signal:stop" IN ('FI:T-271A', 'FI:T-271B', 'FI:T-271C', 'FI:T-271D') AND "railway:signal:stop:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['fi/t-270', NULL, '24.666666', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop:caption" ~ '^([1-5]);[^;]+$' THEN ARRAY[CONCAT('fi/t-271-top-{', regexp_substr("railway:signal:stop:caption", '^([1-5]);[^;]+$', 1, 1, '', 1), '}'), regexp_substr("railway:signal:stop:caption", '^([1-5]);[^;]+$', 1, 1, '', 1), '24.666667', '0', '0']
                    WHEN "railway:signal:stop:caption" ~ '^([^;]+);[^;]+$' THEN ARRAY['fi/t-271-top-unknown', NULL, '24.666667', '0', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop:caption" ~ '^[^;]+;(1|2|3|4|5)$' THEN ARRAY[CONCAT('fi/t-271-bottom-{', regexp_substr("railway:signal:stop:caption", '^[^;]+;(1|2|3|4|5)$', 1, 1, '', 1), '}'), regexp_substr("railway:signal:stop:caption", '^[^;]+;(1|2|3|4|5)$', 1, 1, '', 1), '24.666667', '0', '0']
                    WHEN "railway:signal:stop:caption" ~ '^[^;]+;([^;]+)$' THEN ARRAY['fi/t-271-bottom-unknown', NULL, '24.666667', '0', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop" = 'FI:T-271B' THEN ARRAY['fi/t-271-right', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-271C' THEN ARRAY['fi/t-271-left', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-271D' THEN ARRAY['fi/t-271-both', NULL, '24.666668', '0', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '557'])
            
            -- (FI) Stopping position point
            WHEN "railway:signal:stop" IN ('FI:T-272A', 'FI:T-272B', 'FI:T-272C', 'FI:T-272D') AND "railway:signal:stop:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['fi/t-270', NULL, '24.666666', '0', '0'] as icon
                  UNION ALL
                  SELECT ARRAY['fi/t-272', NULL, '24.666667', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop" = 'FI:T-272B' THEN ARRAY['fi/t-270-right', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-272C' THEN ARRAY['fi/t-270-left', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-272D' THEN ARRAY['fi/t-270-both', NULL, '24.666668', '0', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '558'])
            
            -- (FI) Train composition (single)
            WHEN "railway:signal:stop" IN ('FI:T-273A', 'FI:T-273B', 'FI:T-273C', 'FI:T-273D') AND "railway:signal:stop:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['fi/t-273', NULL, '24.666668', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop:caption" IN ('1', '2', '3', '4') THEN ARRAY[CONCAT('fi/t-273-{', "railway:signal:stop:caption", '}'), "railway:signal:stop:caption", '24.666668', '0', '0']
                    ELSE ARRAY['fi/t-273-unknown', NULL, '24.666668', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop" = 'FI:T-273B' THEN ARRAY['fi/t-273-right', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-273C' THEN ARRAY['fi/t-273-left', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-273D' THEN ARRAY['fi/t-273-both', NULL, '24.666668', '0', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '559'])
            
            -- (FI) Train composition (combination)
            WHEN "railway:signal:stop" IN ('FI:T-274A', 'FI:T-274B', 'FI:T-274C', 'FI:T-274D') AND "railway:signal:stop:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['fi/t-273', NULL, '24.666668', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop:caption" ~ '^([1-4]);[^;]+$' THEN ARRAY[CONCAT('fi/t-274-top-{', regexp_substr("railway:signal:stop:caption", '^([1-4]);[^;]+$', 1, 1, '', 1), '}'), regexp_substr("railway:signal:stop:caption", '^([1-4]);[^;]+$', 1, 1, '', 1), '24.666667', '0', '0']
                    WHEN "railway:signal:stop:caption" ~ '^([^;]+);[^;]+$' THEN ARRAY['fi/t-274-top-unknown', NULL, '24.666667', '0', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop:caption" ~ '^[^;]+;(1|2|3|4)$' THEN ARRAY[CONCAT('fi/t-274-bottom-{', regexp_substr("railway:signal:stop:caption", '^[^;]+;(1|2|3|4)$', 1, 1, '', 1), '}'), regexp_substr("railway:signal:stop:caption", '^[^;]+;(1|2|3|4)$', 1, 1, '', 1), '24.666667', '0', '0']
                    WHEN "railway:signal:stop:caption" ~ '^[^;]+;([^;]+)$' THEN ARRAY['fi/t-274-bottom-unknown', NULL, '24.666667', '0', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop" = 'FI:T-274B' THEN ARRAY['fi/t-274-right', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-274C' THEN ARRAY['fi/t-274-left', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-274D' THEN ARRAY['fi/t-274-both', NULL, '24.666668', '0', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '560'])
            
            -- (FI) Train composition point
            WHEN "railway:signal:stop" IN ('FI:T-275A', 'FI:T-275B', 'FI:T-275C', 'FI:T-275D') AND "railway:signal:stop:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['fi/t-273', NULL, '24.666668', '0', '0'] as icon
                  UNION ALL
                  SELECT ARRAY['fi/t-275', NULL, '24.666667', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:stop" = 'FI:T-275B' THEN ARRAY['fi/t-273-right', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-275C' THEN ARRAY['fi/t-273-left', NULL, '24.666668', '0', '0']
                    WHEN "railway:signal:stop" = 'FI:T-275D' THEN ARRAY['fi/t-273-both', NULL, '24.666668', '0', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '561'])
            
            -- (FI) Stop
            WHEN "railway:signal:stop" = 'FI:T-259' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-259', NULL, '26', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '566'])
            
            -- (FI) Seismerkki (old)
            WHEN "railway:signal:stop" = 'FI:T-150' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-150', NULL, '15.710148', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '567'])
            
            -- (FI) Seismerkki (new)
            WHEN "railway:signal:stop" = 'FI:T-150B' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-150B', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '568'])
            
            -- (FI) Seislevy (old)
            WHEN "railway:signal:stop" = 'FI:T-151' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-151', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '569'])
            
            -- (FI) Seislevy (new)
            WHEN "railway:signal:stop" = 'FI:T-151A' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-151A', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '570'])
            
            -- (FI) Liikennöinnin raja
            WHEN "railway:signal:stop" = 'FI:T-152' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-152', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '571'])
            
            -- (FI) Veturin ajokieltomerkki
            WHEN "railway:signal:stop" = 'FI:T-310' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-310', NULL, '14.012489', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '572'])
            
            -- (FR) Stop ARRET
            WHEN "railway:signal:stop" = 'FR:ARRET' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/ARRET', NULL, '9.562063', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '654'])
            
            -- (FR) Stop ATC
            WHEN "railway:signal:stop" = 'FR:ATC' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/ATC', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '655'])
            
            -- (FR) STOP
            WHEN "railway:signal:stop" = 'FR:STOP' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/STOP', NULL, '9.55814', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '657'])
            
            -- (FR) STOP
            WHEN "railway:signal:stop" = 'FR:JAL_ARRET' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/JAL_ARRET', NULL, '15.977813', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '658'])
            
            -- (FR) Stop position for passenger trains
            WHEN "railway:signal:stop" = 'FR:ARRET_TT' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/ARRET_TT', NULL, '16.000005', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '659'])
            
            -- (FR) Stop position front of train
            WHEN "railway:signal:stop" = 'FR:ARRET_TTL' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/ARRET_TTL', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '660'])
            
            -- (FR) Stop position EAS
            WHEN "railway:signal:stop" = 'FR:ARRET_TT_EAS' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/ARRET_TT_EAS', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '661'])
            
            -- (FR) Stop position for carriages
            WHEN "railway:signal:stop" = 'FR:ARRET_V' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/ARRET_V', NULL, '16.000003', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '662'])
            
            -- (FR) Stop for TGV 1
            WHEN "railway:signal:stop" = 'FR:ARRET_TGV1' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/ARRET_TGV1', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '663'])
            
            -- (FR) Stop for TGV 2
            WHEN "railway:signal:stop" = 'FR:ARRET_TGV2' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/ARRET_TGV2', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '664'])
            
            -- (FR) Stop for TGV 1-2
            WHEN "railway:signal:stop" = 'FR:ARRET_TGV1-2' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['fr/ARRET_TGV1-2', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '665'])
            
            -- (GB) Stop board
            WHEN "railway:signal:stop" = 'GB-NR:stop' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['gb/stop-board', NULL, '29.714286', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '692'])
            
            -- (GB) Engineering Stop board
            WHEN "railway:signal:stop" = 'GB-NR:engineer-stop' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['gb/stop-octagon', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '693'])
            
            -- (IT) Halt
            WHEN "railway:signal:stop" = 'IT:HALT' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['it/stop', NULL, '7.575437', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '714'])
            
            -- (NL) stopplaatssein
            WHEN "railway:signal:stop" IN ('NL:303', 'NL:stopplaatssein') AND "railway:signal:stop:form" = 'light'
              THEN array_cat(ARRAY['nl/303', NULL, '19.314327', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '758'])
            
            -- (NL) treinlengtebord
            WHEN "railway:signal:stop" = 'NL:304' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN '^([2-9]|1[0-68])$' ~!@# ANY("railway:signal:stop:carriages") THEN ARRAY[CONCAT('nl/304-{', (select match from (select regexp_substr(match, '^([2-9]|1[0-68])$') as match from (select unnest("railway:signal:stop:carriages") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([2-9]|1[0-68])$') as match from (select unnest("railway:signal:stop:carriages") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '18', '0', '0']
                    ELSE ARRAY['nl/304-empty', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '759'])
            
            -- (NZ) All Trains Stop
            WHEN "railway:signal:stop" = 'NZ:all_trains_stop' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['nz/all_trains_stop', NULL, '17', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '784'])
            
            -- (NZ) Stop Block Entry
            WHEN "railway:signal:stop" = 'NZ:stop_block' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['nz/stop_block_entry', NULL, '17', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '785'])
            
            -- (NZ) Stop Station Entry
            WHEN "railway:signal:stop" = 'NZ:stop_station' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['nz/stop_station_entry', NULL, '17', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '786'])
            
            -- (NZ) Stop Plate
            WHEN "railway:signal:stop" = 'NZ:stop_plate' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['nz/stop_plate', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '787'])
            
            -- (NZ) Stop Disk
            WHEN "railway:signal:stop" = 'NZ:stop_disk' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['nz/stop_disk', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '788'])
            
            -- (NZ) EMU Stop Position
            WHEN "railway:signal:stop" = 'NZ:emu_stop' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN '2' = ANY("railway:signal:stop:states") THEN ARRAY['nz/stop_position/2@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '3' = ANY("railway:signal:stop:states") THEN ARRAY['nz/stop_position/3@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '4' = ANY("railway:signal:stop:states") THEN ARRAY['nz/stop_position/4@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '6' = ANY("railway:signal:stop:states") THEN ARRAY['nz/stop_position/6@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '8' = ANY("railway:signal:stop:states") THEN ARRAY['nz/stop_position/8@bottom', NULL, '0', '15', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '789'])
            
            -- (PL) Wskaźnik zatrzymania (W4)
            WHEN "railway:signal:stop" = 'PL-PKP:w4' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['pl/w4', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '860'])
            
            -- (PL) Wskaźnik czoła pociągu (W32)
            WHEN "railway:signal:stop" = 'PL-PKP:w32' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:stop:caption" ~ '^([568]0|[1-3][50]0)$' THEN ARRAY[CONCAT('pl/w32-{', regexp_substr("railway:signal:stop:caption", '^([568]0|[1-3][50]0)$', 1, 1, '', 1), '}'), regexp_substr("railway:signal:stop:caption", '^([568]0|[1-3][50]0)$', 1, 1, '', 1), '23', '0', '0']
                    ELSE ARRAY['pl/w32-empty', NULL, '23', '0', '0']
                  END, ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '874'])
            
            -- (PL) Miejsce zatrzymania czoła pociągu (Wm4)
            WHEN "railway:signal:stop" = 'PL-metro:wm4' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['pl/metro/wm4', NULL, '4.355872', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '878'])
            
            -- (PL) Blokada zwrotnicy (BT-3)
            WHEN "railway:signal:stop" = 'PL-tram:bt-3' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['pl/tram/bt-3', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '886'])
            
            -- (PL) Stop – zwrotnica eksploatowana jednostronnie (BT-4)
            WHEN "railway:signal:stop" = 'PL-tram:bt-4' AND "railway:signal:stop:form" = 'sign'
              THEN array_cat(ARRAY['pl/tram/bt-4', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '887'])
            
            -- (SE) Slutpunktstopplykta
            WHEN "railway:signal:stop" = 'SE:Slutpunktstopplykta' AND "railway:signal:stop:form" = 'light'
              THEN array_cat(ARRAY['se/slutpunktstopplykta', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:stop:deactivated"::text, 'signals', '936'])
            
            -- Unknown signal (stop)
            ELSE
              ARRAY['general/signal-unknown-stop', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_stop,
      CASE 
        WHEN "railway:signal:stop_distant" IS NOT NULL THEN
          CASE 
            -- (FR) Stop ARRET announcement
            WHEN "railway:signal:stop_distant" = 'FR:ARRET_A' AND "railway:signal:stop_distant:form" = 'sign'
              THEN array_cat(ARRAY['fr/ARRET_A', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop_distant:deactivated"::text, 'signals', '653'])
            
            -- (FR) STOP announcement
            WHEN "railway:signal:stop_distant" = 'FR:STOP_A' AND "railway:signal:stop_distant:form" = 'sign'
              THEN array_cat(ARRAY['fr/STOP_A', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop_distant:deactivated"::text, 'signals', '656'])
            
            -- (IT) Distant Halt (distance 1)
            WHEN "railway:signal:stop_distant" = 'IT:HALT' AND "railway:signal:stop_distant:form" = 'sign' AND "railway:signal:stop_distant:distance" = '1'
              THEN array_cat(ARRAY['it/stop-distant-1', NULL, '12.416786', '0', '0'], ARRAY[NULL, "railway:signal:stop_distant:deactivated"::text, 'signals', '715'])
            
            -- (IT) Distant Halt (distance 2)
            WHEN "railway:signal:stop_distant" = 'IT:HALT' AND "railway:signal:stop_distant:form" = 'sign' AND "railway:signal:stop_distant:distance" = '2'
              THEN array_cat(ARRAY['it/stop-distant-2', NULL, '12.416786', '0', '0'], ARRAY[NULL, "railway:signal:stop_distant:deactivated"::text, 'signals', '716'])
            
            -- Unknown signal (stop_distant)
            ELSE
              ARRAY['general/signal-unknown-stop_distant', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_stop_distant,
      CASE 
        WHEN "railway:signal:stop_demand" IS NOT NULL THEN
          CASE 
            -- (AT) Bedarfshalt
            WHEN "railway:signal:stop_demand" = 'AT:bedarfshalt-signal' AND "railway:signal:stop_demand:form" = 'light'
              THEN array_cat(ARRAY['at/bedarfshalt', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:stop_demand:deactivated"::text, 'signals', '32'])
            
            -- (DE) stop demand post Ne 5 (light)
            WHEN "railway:signal:stop_demand" = 'DE-ESO:ne5' AND "railway:signal:stop_demand:form" = 'light'
              THEN array_cat(ARRAY['de/ne5-light', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:stop_demand:deactivated"::text, 'signals', '368'])
            
            -- (DE) Karlsruhe AVG Stop Demand
            WHEN "railway:signal:stop_demand" = 'DE-AVG:hw1' AND "railway:signal:stop_demand:form" = 'light'
              THEN array_cat(ARRAY['de/avg/hw1', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:stop_demand:deactivated"::text, 'signals', '407'])
            
            -- Unknown signal (stop_demand)
            ELSE
              ARRAY['general/signal-unknown-stop_demand', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_stop_demand,
      CASE 
        WHEN "railway:signal:station_distant" IS NOT NULL THEN
          CASE 
            -- (AT) Haltestellentafel
            WHEN "railway:signal:station_distant" = 'AT-V2:haltestellentafel' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['at/haltestellentafel', NULL, '5', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '33'])
            
            -- (AU) Landmark
            WHEN "railway:signal:station_distant" = 'AU:NSW:landmark' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/landmark', NULL, '16.3', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '131'])
            
            -- (AU) Location
            WHEN "railway:signal:station_distant" IN ('AU:NSW:location', 'AU:VIC:location') AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/location', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '133'])
            
            -- (AU) Yard Limit
            WHEN "railway:signal:station_distant" = 'AU:NSW:YL' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/YL', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '144'])
            
            -- (AU) Station Approach
            WHEN "railway:signal:station_distant" = 'AU:VIC:station' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/station', NULL, '7.5', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '189'])
            
            -- (BE) Station announcement
            WHEN "railway:signal:station_distant" = 'BE:PAPA' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['be/PAPA', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '254'])
            
            -- (CZ) Vlak se blíží k zastávce
            WHEN "railway:signal:station_distant" IN ('CZ-D1:vlak_se_blizi_k_zastavce', 'Cs-D1') AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['cz/vlak_se_blizi_k_zastavce', NULL, '6.870588', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN "railway:signal:station_distant:shortened" THEN ARRAY['cz/shortened@top', NULL, '0', '6.709679', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '306'])
            
            -- (CZ) Hlavní návěstidlo sloučeno s předvěstí
            WHEN "railway:signal:station_distant" = 'CZ-D1:hlavni_navestidlo_slouceno_s_predvesti' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['cz/hlavni_navestidlo_slouceno_s_predvesti', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '307'])
            
            -- (CZ) Stanoviště posledního oddílového návěstidla
            WHEN "railway:signal:station_distant" = 'CZ-D1:stanoviste_posledniho_oddiloveho_navestidla' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['cz/stanoviste_posledniho_oddiloveho_navestidla', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '308'])
            
            -- (CZ) Stanoviště samostatné předvěsti
            WHEN "railway:signal:station_distant" = 'CZ-D1:stanoviste_samostatne_predvesti' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:station_distant:type" = 'station' THEN ARRAY['cz/stanoviste_samostatne_predvesti/station@bottom', NULL, '0', '10.63842', '0']
                    WHEN "railway:signal:station_distant:type" = 'block_or_protection' THEN ARRAY['cz/stanoviste_samostatne_predvesti/block_or_protection@bottom', NULL, '0', '10', '0']
                    ELSE ARRAY['cz/stanoviste_samostatne_predvesti/fallback@bottom', NULL, '0', '10.63842', '0']
                  END, ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '309'])
            
            -- (DE) station distant sign Ne 6
            WHEN "railway:signal:station_distant" = 'DE-ESO:ne6' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['de/ne6', NULL, '5', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '373'])
            
            -- (FI) Liikennepaikan raja -merkki
            WHEN "railway:signal:station_distant" = 'FI:T-164' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-164', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '585'])
            
            -- (FI) Liikennepaikka päättyy
            WHEN "railway:signal:station_distant" = 'FI:T-165' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-165', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '586'])
            
            -- (FI) Matkustajalaiturin ennakkomerkki
            WHEN "railway:signal:station_distant" = 'FI:T-166' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-166', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '587'])
            
            -- (FR) Distant station
            WHEN "railway:signal:station_distant" = 'FR:GARE' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['fr/GARE', NULL, '9.394188', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '649'])
            
            -- (FR) Distant site
            WHEN "railway:signal:station_distant" = 'FR:APPROCHE_ETS_A' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['fr/APPROCHE_ETS_A', NULL, '9', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '650'])
            
            -- (FR) Distant site
            WHEN "railway:signal:station_distant" = 'FR:APPROCHE_ETS' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['fr/APPROCHE_ETS', NULL, '9.313234', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '651'])
            
            -- (FR) Station boundary
            WHEN "railway:signal:station_distant" = 'FR:LIMITE_ETS' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['fr/LIMITE_ETS', NULL, '17.999985', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '652'])
            
            -- (NL) station
            WHEN "railway:signal:station_distant" = 'NL:305' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['nl/305', NULL, '25.094884', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '761'])
            
            -- (NZ) TWC (signalled) Station Warning
            WHEN "railway:signal:station_distant" = 'NZ:TWC_signalled' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['nz/TWC_signalled', NULL, '12.9', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '810'])
            
            -- (NZ) TWC (unsignalled) Station Warning
            WHEN "railway:signal:station_distant" = 'NZ:TWC_unsignalled' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['nz/TWC_unsignalled', NULL, '12.9', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '811'])
            
            -- (PL) Wskaźnik SBL (W18)
            WHEN "railway:signal:station_distant" = 'PL-PKP:w18' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['pl/w18', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '857'])
            
            -- (PL) Wskaźnik przystanku osobowego (W16)
            WHEN "railway:signal:station_distant" = 'PL-PKP:w16' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['pl/w16', NULL, '4.948454', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '867'])
            
            -- (PL) Rozpocząć hamowanie przed peronem (Wm16)
            WHEN "railway:signal:station_distant" = 'PL-metro:wm16' AND "railway:signal:station_distant:form" = 'sign'
              THEN array_cat(ARRAY['pl/metro/wm16', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:station_distant:deactivated"::text, 'signals', '879'])
            
            -- Unknown signal (station_distant)
            ELSE
              ARRAY['general/signal-unknown-station_distant', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_station_distant,
      CASE 
        WHEN "railway:signal:crossing" IS NOT NULL THEN
          CASE 
            -- (AT) Überwachungssignal
            WHEN "railway:signal:crossing" = 'AT-V2:ek_überwachungssignal' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['at/ek_gesichert', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '34'])
            
            -- (CZ) Přejezdník (neproměnný)
            WHEN "railway:signal:crossing" = 'CZ-D1:prejezdnik' AND "railway:signal:crossing:form" = 'sign'
              THEN array_cat(ARRAY['cz/prejezdnik/sign', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '342'])
            
            -- (CZ) Přejezdník (světelný)
            WHEN "railway:signal:crossing" = 'CZ-D1:prejezdnik' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['cz/prejezdnik/light', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '343'])
            
            -- (DE) Bü 0/1 (sign, repeated)
            WHEN "railway:signal:crossing" = 'DE-ESO:bü' AND "railway:signal:crossing:form" = 'sign' AND "railway:signal:crossing:repeated"
              THEN array_cat(ARRAY['de/bue0-ds-repeated', NULL, '21', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '374'])
            
            -- (DE) Bü 0/1 (sign)
            WHEN "railway:signal:crossing" = 'DE-ESO:bü' AND "railway:signal:crossing:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:crossing:shortened" THEN ARRAY['de/bue0-ds-shortened', NULL, '21', '0', '0']
                    ELSE ARRAY['de/bue0-ds', NULL, '21', '0', '0']
                  END, ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '375'])
            
            -- (DE) Bü 0/1 (light, repeated)
            WHEN "railway:signal:crossing" = 'DE-ESO:bü' AND "railway:signal:crossing:repeated"
              THEN array_cat(ARRAY['de/bue1-ds-repeated', NULL, '21', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '376'])
            
            -- (DE) Bü 0/1 (light)
            WHEN "railway:signal:crossing" = 'DE-ESO:bü'
              THEN array_cat(CASE 
                    WHEN "railway:signal:crossing:shortened" THEN ARRAY['de/bue1-ds-shortened', NULL, '21', '0', '0']
                    ELSE ARRAY['de/bue1-ds', NULL, '21', '0', '0']
                  END, ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '377'])
            
            -- (DE) So 16a/b (repeated)
            WHEN "railway:signal:crossing" = 'DE-ESO:so16' AND "railway:signal:crossing:form" = 'light' AND "railway:signal:crossing:repeated"
              THEN array_cat(ARRAY['de/bue1-dv-repeated', NULL, '21', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '378'])
            
            -- (DE) So 16a/b
            WHEN "railway:signal:crossing" = 'DE-ESO:so16' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(CASE 
                    WHEN "railway:signal:crossing:shortened" THEN ARRAY['de/bue1-dv-shortened', NULL, '21', '0', '0']
                    ELSE ARRAY['de/bue1-dv', NULL, '21', '0', '0']
                  END, ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '379'])
            
            -- (DE) tram crossing light Bü
            WHEN "railway:signal:crossing" = 'DE-BOStrab:bü' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['de/bostrab/bü', NULL, '31.95', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '384'])
            
            -- (DE) Karlsruhe AVG crossing signals
            WHEN "railway:signal:crossing" = 'DE-AVG:bü200' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['de/avg/bue201', NULL, '28.814242', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '405'])
            
            -- (DE) tram Fahrsignal
            WHEN "railway:signal:main" IN ('DE-AVG:f', 'DE-BOStrab:f') AND "railway:signal:crossing" = 'DE-DVB:so25' AND "railway:signal:main:form" = 'light' AND ARRAY['DE-BOStrab:f0', 'DE-BOStrab:f1', 'DE-BOStrab:f2', 'DE-BOStrab:f3', 'DE-BOStrab:f4', 'DE-BOStrab:f5', 'DE-AVG:f0', 'DE-AVG:f1', 'DE-AVG:f2', 'DE-AVG:f3', 'DE-AVG:f4', 'DE-AVG:f5'] && "railway:signal:main:states"
              THEN NULL
            
            -- (FI) crossing signal To
            WHEN "railway:signal:crossing" = 'FI:To' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['fi/to1', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '573'])
            
            -- (GB) Crossing
            WHEN "railway:signal:crossing" = 'GB-NR:crossing' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['gb/crossing', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '695'])
            
            -- (IT) Level crossing (light)
            WHEN "railway:signal:crossing" = 'IT:CT' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['it/crossing-light', NULL, '15.000001', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '721'])
            
            -- (IT) Level crossing (sign)
            WHEN "railway:signal:crossing" = 'IT:PL' AND "railway:signal:crossing:form" = 'sign'
              THEN array_cat(ARRAY['it/crossing-sign', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '722'])
            
            -- (NZ) Crossing Indicator
            WHEN "railway:signal:crossing" = 'NZ:XI' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['nz/XI', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '783'])
            
            -- (PL) Tarcze ostrzegawcze przejazdowe (ToP)
            WHEN "railway:signal:crossing" = 'PL-PKP:osp' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['pl/osp', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '850'])
            
            -- (PL) Wskaźnik WKD Wk
            WHEN "railway:signal:crossing" = 'PL-WKD:wk' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['pl/wkd/wk', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '877'])
            
            -- (SE) Vägskyddssignal
            WHEN "railway:signal:crossing" = 'SE:Vägskyddssignal' AND "railway:signal:crossing:form" = 'light'
              THEN array_cat(ARRAY['se/vägskyddssignal', NULL, '28.088914', '0', '0'], ARRAY[NULL, "railway:signal:crossing:deactivated"::text, 'signals', '930'])
            
            -- Unknown signal (crossing)
            ELSE
              ARRAY['general/signal-unknown-crossing', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_crossing,
      CASE 
        WHEN "railway:signal:crossing_distant" IS NOT NULL THEN
          CASE 
            -- (AT) Rautentafel
            WHEN "railway:signal:crossing_distant" = 'AT-V2:rautentafel' AND "railway:signal:crossing_distant:form" = 'sign'
              THEN array_cat(ARRAY['at/rautentafel', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '35'])
            
            -- (DE) crossing distant sign (warning board) So 15 (DV 301)
            WHEN "railway:signal:crossing_distant" = 'DE-ESO:so15' AND "railway:signal:crossing_distant:form" = 'sign'
              THEN array_cat(ARRAY['de/so15', NULL, '26', '0', '0'], ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '380'])
            
            -- (DE) distant crossing So 14
            WHEN "railway:signal:crossing_distant" = 'DE-ESO:so14' AND "railway:signal:crossing_distant:form" = 'sign'
              THEN array_cat(ARRAY['de/so14', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '381'])
            
            -- (DE) crossing distant sign Bü 2
            WHEN "railway:signal:crossing_distant" = 'DE-ESO:bü2' AND "railway:signal:crossing_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:crossing_distant:shortened" THEN ARRAY['de/bue2-ds-reduced-distance', NULL, '28', '0', '0']
                    ELSE ARRAY['de/bue2-ds', NULL, '28', '0', '0']
                  END, ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '382'])
            
            -- (DE) crossing distant sign Bü 3
            WHEN "railway:signal:crossing_distant" = 'DE-ESO:bü3' AND "railway:signal:crossing_distant:form" = 'sign'
              THEN array_cat(ARRAY['de/bue3', NULL, '26', '0', '0'], ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '383'])
            
            -- (DE) tram distant crossing light Bü 2
            WHEN "railway:signal:crossing_distant" = 'DE-BOStrab:bü2' AND "railway:signal:crossing_distant:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/bü2', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '385'])
            
            -- (DE) Karlsruhe AVG distant crossing signals
            WHEN "railway:signal:crossing_distant" = 'DE-AVG:bü200v' AND "railway:signal:crossing_distant:form" = 'light'
              THEN array_cat(ARRAY['de/avg/bue201v', NULL, '26', '0', '0'], ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '406'])
            
            -- (IT) Distant crossing
            WHEN "railway:signal:crossing_distant" IN ('IT:D_CT') AND "railway:signal:crossing_distant:form" = 'light'
              THEN array_cat(ARRAY['it/crossing-distant', NULL, '14.91169', '0', '0'], ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '720'])
            
            -- (NL) distant crossing
            WHEN "railway:signal:crossing_distant" IN ('NL:318a', 'NL:318b') AND "railway:signal:crossing_distant:form" = 'sign'
              THEN array_cat(ARRAY['nl/318a', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '760'])
            
            -- (PL) Wskaźnik przejazdowy (W11p)
            WHEN "railway:signal:crossing_distant" = 'PL-PKP:w11p' AND "railway:signal:crossing_distant:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:crossing:repeated" THEN ARRAY['pl/w11p-2', NULL, '20', '0', '0']
                    ELSE ARRAY['pl/w11p-1', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '864'])
            
            -- (SE) Vägskyddsförsignal
            WHEN "railway:signal:crossing_distant" = 'SE:Vägskyddsförsignal' AND "railway:signal:crossing_distant:form" = 'light'
              THEN array_cat(ARRAY['se/vägskyddsförsignal', NULL, '15.041536', '0', '0'], ARRAY[NULL, "railway:signal:crossing_distant:deactivated"::text, 'signals', '931'])
            
            -- Unknown signal (crossing_distant)
            ELSE
              ARRAY['general/signal-unknown-crossing_distant', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_crossing_distant,
      CASE 
        WHEN "railway:signal:crossing_info" IS NOT NULL THEN
          CASE 
            -- (DE) crossing info sign
            WHEN "railway:signal:crossing_info" = 'DE-ESO:bü-kennzeichentafel' AND "railway:signal:crossing_info:form" = 'sign'
              THEN array_cat(ARRAY['de/bue-crossing-info', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:crossing_info:deactivated"::text, 'signals', '403'])
            
            -- (NZ) Alarms Start Here
            WHEN "railway:signal:crossing_info" = 'NZ:alarms_start_here' AND "railway:signal:crossing_info:form" = 'sign'
              THEN array_cat(ARRAY['nz/alarms_start_here', NULL, '9', '0', '0'], ARRAY[NULL, "railway:signal:crossing_info:deactivated"::text, 'signals', '782'])
            
            -- Unknown signal (crossing_info)
            ELSE
              ARRAY['general/signal-unknown-crossing_info', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_crossing_info,
      CASE 
        WHEN "railway:signal:crossing_hint" IS NOT NULL THEN
          CASE 
            -- (AU) Signalised Level Crossing
            WHEN "railway:signal:crossing_hint" = 'AU:NSW:signalised' AND "railway:signal:crossing_hint:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/signalised', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:crossing_hint:deactivated"::text, 'signals', '137'])
            
            -- (AU) Unsignalised Level Crossing
            WHEN "railway:signal:crossing_hint" = 'AU:NSW:unsignalised' AND "railway:signal:crossing_hint:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/unsignalised', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:crossing_hint:deactivated"::text, 'signals', '142'])
            
            -- (DE) crossing anouncement sign
            WHEN "railway:signal:crossing_hint" = 'DE-ESO:bü-ankündetafel' AND "railway:signal:crossing_hint:form" = 'sign'
              THEN array_cat(ARRAY['de/bue-crossing-hint', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:crossing_hint:deactivated"::text, 'signals', '404'])
            
            -- (NZ) Level Crossing Ahead
            WHEN "railway:signal:crossing_hint" = 'NZ:saltire' AND "railway:signal:crossing_hint:form" = 'sign'
              THEN array_cat(ARRAY['nz/saltire', NULL, '10.2', '0', '0'], ARRAY[NULL, "railway:signal:crossing_hint:deactivated"::text, 'signals', '781'])
            
            -- (PL) Sygnalizacja świetlna wzbudzana (AT-2)
            WHEN "railway:signal:crossing_hint" = 'PL-tram:at-2' AND "railway:signal:crossing_hint:form" = 'sign'
              THEN array_cat(ARRAY['pl/tram/at-2', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:crossing_hint:deactivated"::text, 'signals', '882'])
            
            -- (PL) Ruch kolizyjny (AT-5)
            WHEN "railway:signal:crossing_hint" = 'PL-tram:at-5' AND "railway:signal:crossing_hint:form" = 'sign'
              THEN array_cat(ARRAY['pl/tram/at-5', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:crossing_hint:deactivated"::text, 'signals', '885'])
            
            -- Unknown signal (crossing_hint)
            ELSE
              ARRAY['general/signal-unknown-crossing_hint', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_crossing_hint,
      CASE 
        WHEN "railway:signal:ring" IS NOT NULL THEN
          CASE 
            -- (DE) ring sign Bü 5
            WHEN "railway:signal:ring" = 'DE-ESO:bü5' AND "railway:signal:ring:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:ring:only_transit" THEN ARRAY['de/bue5-only-transit', NULL, '21', '0', '0']
                    ELSE ARRAY['de/bue5', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:ring:deactivated"::text, 'signals', '389'])
            
            -- (DE) start ringing Pl 3
            WHEN "railway:signal:ring" = 'DE-ESO:dr:pl3' AND "railway:signal:ring:form" = 'sign'
              THEN array_cat(ARRAY['de/pl3', NULL, '23.322654', '0', '0'], ARRAY[NULL, "railway:signal:ring:deactivated"::text, 'signals', '390'])
            
            -- (DE) stop ringing Pl 4
            WHEN "railway:signal:ring" = 'DE-ESO:dr:pl4' AND "railway:signal:ring:form" = 'sign'
              THEN array_cat(ARRAY['de/pl4', NULL, '11.716247', '0', '0'], ARRAY[NULL, "railway:signal:ring:deactivated"::text, 'signals', '391'])
            
            -- (DE) start ringing LP 4
            WHEN "railway:signal:ring" = 'DE-ESO:db:lp4' AND "railway:signal:ring:form" = 'sign'
              THEN array_cat(ARRAY['de/lp4', NULL, '23.3', '0', '0'], ARRAY[NULL, "railway:signal:ring:deactivated"::text, 'signals', '392'])
            
            -- (DE) stop ringing LP 5
            WHEN "railway:signal:ring" = 'DE-ESO:db:lp5' AND "railway:signal:ring:form" = 'sign'
              THEN array_cat(ARRAY['de/lp5', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:ring:deactivated"::text, 'signals', '393'])
            
            -- (DE) tram läuten Sh 4
            WHEN "railway:signal:ring" = 'DE-BOStrab:sh4' AND "railway:signal:ring:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/sh4', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:ring:deactivated"::text, 'signals', '398'])
            
            -- Unknown signal (ring)
            ELSE
              ARRAY['general/signal-unknown-ring', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_ring,
      CASE 
        WHEN "railway:signal:whistle" IS NOT NULL THEN
          CASE 
            -- (AT) Pfeifpflock
            WHEN "railway:signal:whistle" = 'AT-V2:pfeifpflock' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['at/pfeifpflock', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '36'])
            
            -- (AT) Gruppenpfeifpflock
            WHEN "railway:signal:whistle" = 'AT-V2:gruppenpfeifpflock' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['at/gruppenpfeifpflock', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '37'])
            
            -- (AT) Endpflock
            WHEN "railway:signal:whistle" = 'AT-V2:endpflock' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['at/endpflock', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '38'])
            
            -- (AT) EK poor sight (GKB)
            WHEN "railway:signal:whistle" = 'AT-GKB:ek_60' AND "railway:signal:whistle:form" = 'sign' AND "railway:signal:speed_limit" = 'AT-GKB:ek_60' AND "railway:signal:speed_limit:form" = 'sign'
              THEN array_cat(ARRAY['at/ek-60', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '41'])
            
            -- (AU) No Whistle
            WHEN "railway:signal:whistle" = 'AU:NSW:no_whistle' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/no_whistle', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '134'])
            
            -- (AU) Whistle
            WHEN "railway:signal:whistle" = 'AU:NSW:whistle' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/whistle', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '143'])
            
            -- (AU) Whistle Post
            WHEN "railway:signal:whistle" = 'AU:VIC:whistle' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['au/vic/signs/whistle', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '187'])
            
            -- (CZ) Pískejte
            WHEN "railway:signal:whistle" IN ('CZ-D1:piskejte', 'Cs-D1') AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['cz/piskejte', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '340'])
            
            -- (DE) Bü 4 Whistle Sign
            WHEN "railway:signal:whistle" = 'DE-ESO:db:bü4' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:whistle:only_transit" THEN ARRAY['de/bue4-ds-only-transit', NULL, '21', '0', '0']
                    ELSE ARRAY['de/bue4-ds', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '386'])
            
            -- (DE) whistle sign Pf 1 (DV 301)
            WHEN "railway:signal:whistle" = 'DE-ESO:dr:pf1' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:whistle:only_transit" THEN ARRAY['de/pf1-dv-only-transit', NULL, '21.330624', '0', '0']
                    ELSE ARRAY['de/pf1-dv', NULL, '15', '0', '0']
                  END, ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '387'])
            
            -- (DE) whistle twice sign Pf 2 (DV 301)
            WHEN "railway:signal:whistle" = 'DE-ESO:dr:pf2' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['de/pf2-dv', NULL, '23.471882', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '388'])
            
            -- (GB) Whistle stencil
            WHEN "railway:signal:whistle" = 'GB-NR:stencil' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['gb/whistle-stencil', NULL, '20.609658', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '668'])
            
            -- (GB) Whistle board
            WHEN "railway:signal:whistle" = 'GB-NR:board' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['gb/whistle-board', NULL, '15.936255', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '669'])
            
            -- (GB) Whistle continuous
            WHEN "railway:signal:whistle" = 'GB-NR:continuous' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['gb/whistle-continuous', NULL, '22.760563', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '670'])
            
            -- (NZ) Whistle
            WHEN "railway:signal:whistle" = 'NZ:whistle' AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(ARRAY['nz/whistle', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '812'])
            
            -- (PL) Wskaźniki ostrzegania (W6, W6a, W6b i W7)
            WHEN "railway:signal:whistle" IN ('PL-PKP:w6', 'PL-PKP:w6a', 'PL-PKP:w6b', 'PL-PKP:w7') AND "railway:signal:whistle:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:whistle" = 'PL-PKP:w6a' THEN ARRAY['pl/w6a', NULL, '16', '0', '0']
                    WHEN "railway:signal:whistle" = 'PL-PKP:w6b' THEN ARRAY['pl/w6b', NULL, '28', '0', '0']
                    WHEN "railway:signal:whistle" = 'PL-PKP:w7' THEN ARRAY['pl/w7', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/w6', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:whistle:deactivated"::text, 'signals', '862'])
            
            -- Unknown signal (whistle)
            ELSE
              ARRAY['general/signal-unknown-whistle', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_whistle,
      CASE 
        WHEN "railway:signal:electricity" IS NOT NULL THEN
          CASE 
            -- (AT) Ankündigung Stromabnehmer tief
            WHEN "railway:signal:electricity" = 'AT-V2:ankündigung_stromabnehmer_tief' AND "railway:signal:electricity:type" = 'pantograph_down_advance' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['at/ankündigung_stromabnehmer_tief', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '52'])
            
            -- (AT) Ankündigung Hauptschalter aus
            WHEN "railway:signal:electricity" = 'AT-V2:ankündigung_hauptschalter_aus' AND "railway:signal:electricity:type" = 'power_off_advance' AND "railway:signal:electricity:form" IN ('sign', 'light')
              THEN array_cat(ARRAY['at/ankündigung_hauptschalter_aus', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '53'])
            
            -- (AT) Halt für Fahrzeuge mit angehobenem Stromabnehmer
            WHEN "railway:signal:electricity" = 'AT-V2:halt_fuer_fahrzeuge_mit_angehobenem_stromabnehmer' AND "railway:signal:electricity:type" = 'end_of_catenary' AND "railway:signal:electricity:form" IN ('sign', 'light', 'semaphore')
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity:turn_direction" = 'left' THEN ARRAY['at/halt_fuer_fahrzeuge_mit_angehobenem_stromabnehmer-left', NULL, '20.616919', '0', '0']
                    WHEN "railway:signal:electricity:turn_direction" = 'through' THEN ARRAY['at/halt_fuer_fahrzeuge_mit_angehobenem_stromabnehmer-through', NULL, '28.140527', '0', '0']
                    WHEN "railway:signal:electricity:turn_direction" = 'right' THEN ARRAY['at/halt_fuer_fahrzeuge_mit_angehobenem_stromabnehmer-right', NULL, '20.555578', '0', '0']
                    ELSE ARRAY['at/halt_fuer_fahrzeuge_mit_angehobenem_stromabnehmer', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '54'])
            
            -- (AT) Hauptschalter ein
            WHEN "railway:signal:electricity" = 'AT-V2:hauptschalter_ein' AND "railway:signal:electricity:type" = 'power_on' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['at/hauptschalter_ein', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '55'])
            
            -- (AT) Stromabnehmer hoch
            WHEN "railway:signal:electricity" = 'AT-V2:stromabnehmer_hoch' AND "railway:signal:electricity:type" = 'pantograph_up' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['at/stromabnehmer_hoch', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '56'])
            
            -- (AT) Hauptschalter aus
            WHEN "railway:signal:electricity" = 'AT-V2:hauptschalter_aus' AND "railway:signal:electricity:type" = 'power_off' AND "railway:signal:electricity:form" IN ('sign', 'light')
              THEN array_cat(ARRAY['at/hauptschalter_aus', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '57'])
            
            -- (AT) Stromabnehmer tief
            WHEN "railway:signal:electricity" = 'AT-V2:stromabnehmer_tief' AND "railway:signal:electricity:type" = 'pantograph_down' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['at/stromabnehmer_tief', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '58'])
            
            -- (AT) Bahnhof Streckentrennung anfang
            WHEN "railway:signal:electricity" = 'AT-V2:bahnhof-streckentrennung_anfang' AND "railway:signal:electricity:type" = 'pantograph_down' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['at/bahnhof-streckentrennung_anfang', NULL, '21.547124', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '59'])
            
            -- (AT) Bahnhof Streckentrennung ende
            WHEN "railway:signal:electricity" = 'AT-V2:bahnhof-streckentrennung_ende' AND "railway:signal:electricity:type" = 'pantograph_up' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['at/bahnhof-streckentrennung_ende', NULL, '21.547124', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '60'])
            
            -- (AT) Schaltzeiger
            WHEN "railway:signal:electricity" = 'AT-V2:schaltzeiger' AND "railway:signal:electricity:type" = 'power_indicator' AND "railway:signal:electricity:form" = 'semaphore'
              THEN array_cat(ARRAY['at/schaltzeiger', NULL, '20.007782', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '61'])
            
            -- (AU) Coast Off
            WHEN "railway:signal:electricity" = 'AU:LightRail:coast_off' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/coast_off', NULL, '8.75', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '70'])
            
            -- (AU) Coast On
            WHEN "railway:signal:electricity" = 'AU:LightRail:coast_on' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/coast_on', NULL, '8.75', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '71'])
            
            -- (AU) Lower APS
            WHEN "railway:signal:electricity" = 'AU:LightRail:NSW:lower_APS' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/lower_APS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '76'])
            
            -- (AU) Lower OESS
            WHEN "railway:signal:electricity" = 'AU:LightRail:NSW:lower_OESS' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/lower_OESS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '77'])
            
            -- (AU) Lower OHW
            WHEN "railway:signal:electricity" = 'AU:LightRail:NSW:lower_OHW' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/lower_OHW', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '78'])
            
            -- (AU) Raise APS
            WHEN "railway:signal:electricity" = 'AU:LightRail:NSW:raise_APS' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/raise_APS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '79'])
            
            -- (AU) Raise OESS
            WHEN "railway:signal:electricity" = 'AU:LightRail:NSW:raise_OESS' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/raise_OESS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '80'])
            
            -- (AU) Raise OHW
            WHEN "railway:signal:electricity" = 'AU:LightRail:NSW:raise_OHW' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/raise_OHW', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '81'])
            
            -- (AU) Cut Off
            WHEN "railway:signal:electricity" = 'AU:LightRail:VIC:cut_off' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/cut_off', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '89'])
            
            -- (AU) 5th Isolate Mark
            WHEN "railway:signal:electricity" = 'AU:LightRail:VIC:isolate_5' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/isolate_5', NULL, '7.5', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '90'])
            
            -- (AU) 4th Isolate Mark
            WHEN "railway:signal:electricity" = 'AU:LightRail:VIC:isolate_4' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/isolate_4', NULL, '7.5', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '91'])
            
            -- (AU) 3rd Isolate Mark
            WHEN "railway:signal:electricity" = 'AU:LightRail:VIC:isolate_3' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/isolate_3', NULL, '7.5', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '92'])
            
            -- (AU) 2nd Isolate Mark
            WHEN "railway:signal:electricity" = 'AU:LightRail:VIC:isolate_2' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/isolate_2', NULL, '7.5', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '93'])
            
            -- (AU) 1st Isolate Mark
            WHEN "railway:signal:electricity" = 'AU:LightRail:VIC:isolate_1' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/isolate_1', NULL, '7.5', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '94'])
            
            -- (AU) Block Join
            WHEN "railway:signal:electricity" = 'AU:NSW:block_join' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/block_join', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '120'])
            
            -- (AU) Electric Train Stop
            WHEN "railway:signal:electricity" = 'AU:NSW:electric_limit' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/electric_limit', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '123'])
            
            -- (AU) Unelectrified Turnout
            WHEN "railway:signal:electricity" = 'AU:NSW:turnout' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/turnout', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '141'])
            
            -- (BE) Panto distant
            WHEN "railway:signal:electricity" = 'BE:PBA' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down_advance'
              THEN array_cat(ARRAY['be/PBA', NULL, '16.56', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '255'])
            
            -- (BE) Panto down
            WHEN "railway:signal:electricity" = 'BE:PBE' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down'
              THEN array_cat(ARRAY['be/PBE', NULL, '6.975611', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '256'])
            
            -- (BE) Panto up
            WHEN "railway:signal:electricity" = 'BE:PRL' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_up'
              THEN array_cat(ARRAY['be/PRL', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '257'])
            
            -- (BE) End of contact line
            WHEN "railway:signal:electricity" = 'BE:FLC' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'end_of_catenary'
              THEN array_cat(ARRAY['be/FLC', NULL, '19.999998', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '258'])
            
            -- (BE) Contact line segmentation
            WHEN "railway:signal:electricity" = 'BE:SLC' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['be/SLC', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '259'])
            
            -- (CH) Vorsignal zum Senksignal
            WHEN "railway:signal:electricity" = 'CH-FDV:703' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down_advance'
              THEN array_cat(ARRAY['ch/fdv-703', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '285'])
            
            -- (CH) Senksignal
            WHEN "railway:signal:electricity" = 'CH-FDV:704' AND "railway:signal:electricity:form" IN ('sign', 'semaphore') AND "railway:signal:electricity:type" = 'pantograph_down'
              THEN array_cat(ARRAY['ch/fdv-704', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '286'])
            
            -- (CH) Endsignal zum Senksignal
            WHEN "railway:signal:electricity" IN ('CH-FDV:705', 'CH-FDV:706') AND "railway:signal:electricity:form" IN ('sign', 'light') AND "railway:signal:electricity:type" = 'pantograph_up'
              THEN array_cat(ARRAY['ch/fdv-705', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '287'])
            
            -- (CH) Aufhebungssignal zum Senksignal
            WHEN "railway:signal:electricity" = 'CH-FDV:707' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_up'
              THEN array_cat(ARRAY['ch/fdv-707', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '288'])
            
            -- (CH) Vorsignal zum Ausschaltsignal (sign)
            WHEN "railway:signal:electricity" = 'CH-FDV:708' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off_advance'
              THEN array_cat(ARRAY['ch/fdv-708', NULL, '15.657013', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '289'])
            
            -- (CH) Vorsignal zum Ausschaltsignal (light)
            WHEN "railway:signal:electricity" = 'CH-FDV:709' AND "railway:signal:electricity:form" = 'light' AND "railway:signal:electricity:type" = 'power_off_advance'
              THEN array_cat(ARRAY['ch/fdv-709', NULL, '16.587582', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '290'])
            
            -- (CH) Ausschaltsignal (sign)
            WHEN "railway:signal:electricity" = 'CH-FDV:710' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(ARRAY['ch/fdv-710', NULL, '15.657013', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '291'])
            
            -- (CH) Ausschaltsignal (light)
            WHEN "railway:signal:electricity" = 'CH-FDV:711' AND "railway:signal:electricity:form" = 'light' AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(ARRAY['ch/fdv-711', NULL, '16.587582', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '292'])
            
            -- (CH) Einschaltsignal (sign)
            WHEN "railway:signal:electricity" = 'CH-FDV:712' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(ARRAY['ch/fdv-712', NULL, '15.657013', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '293'])
            
            -- (CH) Einschaltsignal (light)
            WHEN "railway:signal:electricity" = 'CH-FDV:713' AND "railway:signal:electricity:form" = 'light' AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(ARRAY['ch/fdv-713', NULL, '16.587582', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '294'])
            
            -- (CH) Streckentrennung
            WHEN "railway:signal:electricity" = 'CH-FDV:714' AND "railway:signal:electricity:form" IN ('sign', 'light') AND "railway:signal:electricity:type" = 'joint'
              THEN array_cat(ARRAY['ch/fdv-714', NULL, '22.260063', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '295'])
            
            -- (CH) Zonen-Schutzstreckensignal
            WHEN "railway:signal:electricity" = 'CH-FDV:715' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'main_switch_off'
              THEN array_cat(ARRAY['ch/fdv-715', NULL, '23.047256', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '296'])
            
            -- (CH) Zonensignal
            WHEN "railway:signal:electricity" = 'CH-FDV:716' AND "railway:signal:electricity:form" = 'light' AND "railway:signal:electricity:type" = 'system_changeable'
              THEN array_cat(ARRAY['ch/fdv-716', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '297'])
            
            -- (CH) Vorsignal zum Umschaltsignal
            WHEN "railway:signal:electricity" IN ('CH-FDV:719', 'CH-SBB:719') AND "railway:signal:electricity:form" = 'light' AND "railway:signal:electricity:type" = 'system_change_advance'
              THEN array_cat(ARRAY['ch/fdv-719', NULL, '15.475022', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '298'])
            
            -- (CH) Umschaltsignal anfang (sign)
            WHEN "railway:signal:electricity" = 'CH-FDV:717' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'system_change_start'
              THEN array_cat(ARRAY['ch/fdv-717', NULL, '22.660539', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '299'])
            
            -- (CH) Umschaltsignal anfang (light)
            WHEN "railway:signal:electricity" = 'CH-FDV:717.1' AND "railway:signal:electricity:form" = 'light' AND "railway:signal:electricity:type" = 'system_change_start'
              THEN array_cat(ARRAY['ch/fdv-717.1', NULL, '22.66054', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '300'])
            
            -- (CH) Umschaltsignal ende (sign)
            WHEN "railway:signal:electricity" = 'CH-FDV:718' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'system_change_end'
              THEN array_cat(ARRAY['ch/fdv-718', NULL, '22.660539', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '301'])
            
            -- (CH) Umschaltsignal ende (light)
            WHEN "railway:signal:electricity" = 'CH-FDV:718.1' AND "railway:signal:electricity:form" = 'light' AND "railway:signal:electricity:type" = 'system_change_end'
              THEN array_cat(ARRAY['ch/fdv-718.1', NULL, '22.66054', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '302'])
            
            -- (DE) power off advance sign El 1v
            WHEN "railway:signal:electricity:type" = 'power_off_advance' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" = 'DE-ESO:el1v'
              THEN array_cat(ARRAY['de/el1v', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '488'])
            
            -- (DE) power off sign El 1
            WHEN "railway:signal:electricity:type" = 'power_off' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" IN ('DE-ESO:el1', 'DE-BOStrab:st3', 'DE-HHA:s1')
              THEN array_cat(ARRAY['de/el1', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '489'])
            
            -- (DE) power on sign El 2
            WHEN "railway:signal:electricity:type" = 'power_on' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" IN ('DE-ESO:el2', 'DE-BOStrab:st4', 'DE-HHA:s2')
              THEN array_cat(ARRAY['de/el2', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '490'])
            
            -- (DE) pantograph down advance El 3
            WHEN "railway:signal:electricity:type" = 'pantograph_down_advance' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" = 'DE-ESO:el3'
              THEN array_cat(ARRAY['de/el3', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '491'])
            
            -- (DE) pantograph down El 4
            WHEN "railway:signal:electricity:type" = 'pantograph_down' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" IN ('DE-ESO:el4', 'DE-BOStrab:st5')
              THEN array_cat(ARRAY['de/el4', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '492'])
            
            -- (DE) pantograph up El 5
            WHEN "railway:signal:electricity:type" = 'pantograph_up' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" IN ('DE-ESO:el5', 'DE-BOStrab:st6')
              THEN array_cat(ARRAY['de/el5', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '493'])
            
            -- (DE) end of catenary sign El 6
            WHEN "railway:signal:electricity:type" = 'end_of_catenary' AND "railway:signal:electricity:form" IN ('sign', 'light', 'semaphore') AND "railway:signal:electricity" IN ('DE-ESO:el6', 'DE-BOStrab:st8')
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity:turn_direction" = 'left' THEN ARRAY['de/el6-left', NULL, '20.616919', '0', '0']
                    WHEN "railway:signal:electricity:turn_direction" = 'through' THEN ARRAY['de/el6-through', NULL, '28.140527', '0', '0']
                    WHEN "railway:signal:electricity:turn_direction" = 'right' THEN ARRAY['de/el6-right', NULL, '20.555578', '0', '0']
                    ELSE ARRAY['de/el6', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '494'])
            
            -- (DE) power off shortly sign El 7 (S-Bahn Berlin)
            WHEN "railway:signal:electricity:type" = 'power_off_shortly' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" = 'DE-ESO:el7'
              THEN array_cat(ARRAY['de/el7', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '495'])
            
            -- (DE) tram power off shortly signal (St 7)
            WHEN "railway:signal:electricity:type" = 'power_off_shortly' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" IN ('DE-BOStrab:st7', 'DE-AVG:st7')
              THEN array_cat(ARRAY['de/bostrab/st7', NULL, '17.545021', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '496'])
            
            -- (DE) power off shortly
            WHEN "railway:signal:electricity:type" = 'power_off_shortly' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" IN ('DE-ESO:el1;DE-ESO:el2', 'DE-ESO:el2:DE-ESO:el1')
              THEN array_cat(ARRAY['de/el1-el2', NULL, '32.023975', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '497'])
            
            -- (DE) tram sign power off shortly El 1
            WHEN "railway:signal:electricity:type" = 'power_off_shortly' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" = 'DE-AVG:el1'
              THEN array_cat(ARRAY['de/avg/el1', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '498'])
            
            -- (DE) Streckentrennung (anfang)
            WHEN "railway:signal:electricity" = 'DE-ESO:streckentrennung' AND "railway:signal:electricity:type" = 'begin_of_isolated_overlap' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['de/streckentrennung-anfang', NULL, '21.547124', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '499'])
            
            -- (DE) Streckentrennung (ende)
            WHEN "railway:signal:electricity" = 'DE-ESO:streckentrennung' AND "railway:signal:electricity:type" = 'end_of_isolated_overlap' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['de/streckentrennung-ende', NULL, '21.547124', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '500'])
            
            -- (DE) ICE-Schaltmerkhilfe
            WHEN "railway:signal:electricity" = 'DE-ESO:ice-schaltmerkhilfe' AND "railway:signal:electricity:type" = 'power_on_for_long_trains' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['de/ice-schaltmerkhilfe', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '501'])
            
            -- (DE) VGF st9
            WHEN "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" = 'DE-VGF:st9'
              THEN array_cat(ARRAY['de/vgf/st9', NULL, '15.970531', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '502'])
            
            -- (DE) VGF st10
            WHEN "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" = 'DE-VGF:st10'
              THEN array_cat(ARRAY['de/vgf/st10', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '503'])
            
            -- (DE) VGF st9 & st10
            WHEN "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity" = 'DE-VGF:st9;DE-VGF:st10'
              THEN array_cat(ARRAY['de/vgf/st9-st10', NULL, '31.96875', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '504'])
            
            -- (ES) end of catenary
            WHEN "railway:signal:electricity" IN ('ES-RCF:FI14A', 'ES-RCF:FI14B') AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'end_of_catenaxy'
              THEN array_cat(ARRAY['es/FI14A', NULL, '16.016659', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '520'])
            
            -- (ES) power off shortly
            WHEN "railway:signal:electricity" = 'ES-RCF:FI14C' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off_shortly'
              THEN array_cat(ARRAY['es/FI14C', NULL, '24.073775', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '521'])
            
            -- (ES) power off shortly (full)
            WHEN "railway:signal:electricity" = 'ES-RCF:FI14D' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off_shortly'
              THEN array_cat(ARRAY['es/FI14D', NULL, '24.241883', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '522'])
            
            -- (ES) pantograph down
            WHEN "railway:signal:electricity" = 'ES-RCF:FI14E' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down'
              THEN array_cat(ARRAY['es/FI14E', NULL, '16.017369', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '523'])
            
            -- (ES) pantograph up
            WHEN "railway:signal:electricity" = 'ES-RCF:FI14F' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_up'
              THEN array_cat(ARRAY['es/FI14F', NULL, '16.01755', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '524'])
            
            -- (ES) pantograph down announcement
            WHEN "railway:signal:electricity" = 'ES-RCF:FI14G' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down_advance'
              THEN array_cat(ARRAY['es/FI14G', NULL, '16.017593', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '525'])
            
            -- (ES) power off announcement
            WHEN "railway:signal:electricity" = 'ES-RCF:FI14H' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off_advance'
              THEN array_cat(ARRAY['es/FI14H', NULL, '15.995985', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '526'])
            
            -- (ES) power off
            WHEN "railway:signal:electricity" = 'ES-RCF:FI14I' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(ARRAY['es/FI14I', NULL, '24.280648', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '527'])
            
            -- (ES) power on
            WHEN "railway:signal:electricity" = 'ES-RCF:FI14J' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_on'
              THEN array_cat(ARRAY['es/FI14J', NULL, '24.280404', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '528'])
            
            -- Distant begin of neutral section
            WHEN "railway:signal:electricity" = 'ETCS:power_off_advance' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off_advance'
              THEN array_cat(ARRAY['etcs/power_off_advance', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '532'])
            
            -- Begin of neutral section
            WHEN "railway:signal:electricity" = 'ETCS:power_off' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(ARRAY['etcs/power_off', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '533'])
            
            -- End of Neutral section
            WHEN "railway:signal:electricity" = 'ETCS:power_on' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_on'
              THEN array_cat(ARRAY['etcs/power_on', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '534'])
            
            -- Distant Lower pantograph
            WHEN "railway:signal:electricity" = 'ETCS:pantograph_down_advance' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down_advance'
              THEN array_cat(ARRAY['etcs/pantograph_down_advance', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '535'])
            
            -- Lower pantograph
            WHEN "railway:signal:electricity" = 'ETCS:pantograph_down' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down'
              THEN array_cat(ARRAY['etcs/pantograph_down', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '536'])
            
            -- Raise pantograph
            WHEN "railway:signal:electricity" = 'ETCS:pantograph_up' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_up'
              THEN array_cat(ARRAY['etcs/pantograph_up', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '537'])
            
            -- Distant end of catenary
            WHEN "railway:signal:electricity" = 'ETCS:end_of_catenary_advance' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'end_of_catenary_advance'
              THEN array_cat(ARRAY['etcs/end_of_catenary_advance', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '538'])
            
            -- End of catenary
            WHEN "railway:signal:electricity" = 'ETCS:end_of_catenary' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'end_of_catenary'
              THEN array_cat(ARRAY['etcs/end_of_catenary', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '539'])
            
            -- (FI) Erotusjakson etumerkki
            WHEN "railway:signal:electricity" = 'FI:T-120' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-120', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '578'])
            
            -- (FI) Erotusjakso alkaa
            WHEN "railway:signal:electricity" = 'FI:T-122' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-122', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '579'])
            
            -- (FI) Erotusjakso päättyy
            WHEN "railway:signal:electricity" = 'FI:T-123' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-123', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '580'])
            
            -- (FI) Ajojohdin päättyy
            WHEN "railway:signal:electricity" = 'FI:T-121' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-121', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '581'])
            
            -- (FI) Laske virroitin
            WHEN "railway:signal:electricity" = 'FI:T-124A' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-124A', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '582'])
            
            -- (FI) Laske virroitin -etumerkki
            WHEN "railway:signal:electricity" = 'FI:T-133' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-133', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '583'])
            
            -- (FI) Nosta virroitin
            WHEN "railway:signal:electricity" = 'FI:T-125' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-125', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '584'])
            
            -- (FR) Neutral Zone Announcement
            WHEN "railway:signal:electricity" = 'FR:SECT' AND "railway:signal:electricity:form" IN ('sign', 'light') AND "railway:signal:electricity:type" = 'power_off_advance'
              THEN array_cat(ARRAY['fr/SECT', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '625'])
            
            -- (FR) Start of Neutral Zone
            WHEN "railway:signal:electricity" = 'FR:CC_EXE' AND "railway:signal:electricity:form" IN ('sign', 'light') AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(ARRAY['fr/CC_EXE', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '626'])
            
            -- (FR) End of Neutral Zone
            WHEN "railway:signal:electricity" = 'FR:CC_FIN' AND "railway:signal:electricity:form" IN ('sign', 'light') AND "railway:signal:electricity:type" = 'power_on'
              THEN array_cat(ARRAY['fr/CC_FIN', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '627'])
            
            -- (FR) End of Neutral Zone (reversible trains)
            WHEN "railway:signal:electricity" = 'FR:REV' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_on'
              THEN array_cat(ARRAY['fr/REV', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '628'])
            
            -- (FR) Pantograph Down Announcement
            WHEN "railway:signal:electricity" = 'FR:BP_DIS' AND "railway:signal:electricity:form" IN ('sign', 'light') AND "railway:signal:electricity:type" = 'pantograph_down_advance'
              THEN array_cat(ARRAY['fr/BP_DIS', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '629'])
            
            -- (FR) Start of Pantograph Down
            WHEN "railway:signal:electricity" = 'FR:BP_EXE' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down'
              THEN array_cat(ARRAY['fr/BP_EXE', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '630'])
            
            -- (FR) End of Pantograph Down
            WHEN "railway:signal:electricity" = 'FR:BP_FIN' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_up'
              THEN array_cat(ARRAY['fr/BP_FIN', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '631'])
            
            -- (FR) Dual-Mode Traffic
            WHEN "railway:signal:electricity" IN ('FR:BIMODE', 'FR:BIMODE_A') AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['fr/BIMODE', NULL, '9.625', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '632'])
            
            -- (FR) End of Catenaries
            WHEN "railway:signal:electricity" = 'FR:FIN_CAT' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'end_of_catenary'
              THEN array_cat(ARRAY['fr/FIN_CAT', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '633'])
            
            -- (FR) Stop Markers
            WHEN "railway:signal:electricity" = 'FR:JALON_ARRET' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['fr/JALON_ARRET', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '634'])
            
            -- (FR) Frost Board
            WHEN "railway:signal:electricity" = 'FR:GIVRE' AND "railway:signal:electricity:form" IN ('sign', 'light')
              THEN array_cat(ARRAY['fr/GIVRE', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '635'])
            
            -- (LU) ESFA
            WHEN "railway:signal:electricity" = 'LU-CFL:ESFA' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'end_of_catenary'
              THEN array_cat(ARRAY['lu/ESFA', NULL, '8.447201', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '729'])
            
            -- (LU) ESFAp/TA
            WHEN "railway:signal:electricity" = 'LU-CFL:ESFAp/TA' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down_advance'
              THEN array_cat(ARRAY['lu/ESFAp_TA', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '730'])
            
            -- (LU) ESFAp/TE
            WHEN "railway:signal:electricity" = 'LU-CFL:ESFAp/TE' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down'
              THEN array_cat(ARRAY['lu/ESFAp_TE', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '731'])
            
            -- (LU) ESFAp/TR
            WHEN "railway:signal:electricity" = 'LU-CFL:ESFAp/TR' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_up'
              THEN array_cat(ARRAY['lu/ESFAp_TR', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '732'])
            
            -- (LU) ESFCC/A
            WHEN "railway:signal:electricity" = 'LU-CFL:ESFCC/A' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off_advance'
              THEN array_cat(ARRAY['lu/ESFCC_A', NULL, '24', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '733'])
            
            -- (LU) ESFCC/E
            WHEN "railway:signal:electricity" = 'LU-CFL:ESFCC/E' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(ARRAY['lu/ESFCC_E', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '734'])
            
            -- (LU) ESFCC/F
            WHEN "railway:signal:electricity" = 'LU-CFL:ESFCC/F' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_on'
              THEN array_cat(ARRAY['lu/ESFCC_F', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '735'])
            
            -- (NL) power off
            WHEN "railway:signal:electricity" = 'NL:306' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(ARRAY['nl/306a', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '774'])
            
            -- (NL) power on
            WHEN "railway:signal:electricity" = 'NL:307' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_on'
              THEN array_cat(ARRAY['nl/307a', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '775'])
            
            -- (NL) announcement pantograph down
            WHEN "railway:signal:electricity" = 'NL:308' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down_advance'
              THEN array_cat(ARRAY['nl/308a', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '776'])
            
            -- (NL) pantograph down
            WHEN "railway:signal:electricity" = 'NL:309' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down'
              THEN array_cat(ARRAY['nl/309a', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '777'])
            
            -- (NL) pantograph up
            WHEN "railway:signal:electricity" = 'NL:310' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_up'
              THEN array_cat(ARRAY['nl/310a', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '778'])
            
            -- (NL) end of catenary
            WHEN "railway:signal:electricity" = 'NL:311' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'end_of_catenary'
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity:turn_direction" = 'right' THEN ARRAY['nl/311-right', NULL, '19.248409', '0', '0']
                    WHEN "railway:signal:electricity:turn_direction" = 'left' THEN ARRAY['nl/311-left', NULL, '19.248409', '0', '0']
                    ELSE ARRAY['nl/311', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '779'])
            
            -- (NL) voltage change
            WHEN "railway:signal:electricity" = 'NL:320' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'voltage_change'
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity:voltage" = '1500' THEN ARRAY['nl/320-1500', NULL, '20', '0', '0']
                    WHEN "railway:signal:electricity:voltage" = '25000' THEN ARRAY['nl/320-25000', NULL, '20', '0', '0']
                    ELSE ARRAY['nl/320-unknown', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '780'])
            
            -- (NZ) Electric Services Limit
            WHEN "railway:signal:electricity" = 'NZ:electric_limit' AND "railway:signal:electricity:form" = 'sign'
              THEN array_cat(ARRAY['nz/electric_limit', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '804'])
            
            -- (PL) Wskaźniki uprzedzające o opuszczeniu pantografu (We1)
            WHEN "railway:signal:electricity" IN ('PL-PKP:we1a', 'PL-PKP:we1b', 'PL-PKP:we1c') AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down_advance'
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity:turn_direction" = 'right' THEN ARRAY['pl/we1b', NULL, '23.3033', '0', '0']
                    WHEN "railway:signal:electricity:turn_direction" = 'left' THEN ARRAY['pl/we1c', NULL, '23.3033', '0', '0']
                    ELSE ARRAY['pl/we1a', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '907'])
            
            -- (PL) Wskaźniki opuszczenia pantografu (We2)
            WHEN "railway:signal:electricity" IN ('PL-PKP:we2a', 'PL-PKP:we2b', 'PL-PKP:we2c') AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_down'
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity:turn_direction" = 'right' THEN ARRAY['pl/we2b', NULL, '23.3033', '0', '0']
                    WHEN "railway:signal:electricity:turn_direction" = 'left' THEN ARRAY['pl/we2c', NULL, '23.3033', '0', '0']
                    ELSE ARRAY['pl/we2a', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '908'])
            
            -- (PL) Wskaźniki podniesienia pantografu (We3)
            WHEN "railway:signal:electricity" IN ('PL-PKP:we3a', 'PL-PKP:we3b', 'PL-PKP:we3c') AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'pantograph_up'
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity" = 'PL-PKP:we3b' THEN ARRAY['pl/we3b', NULL, '23.3033', '0', '0']
                    WHEN "railway:signal:electricity" = 'PL-PKP:we3c' THEN ARRAY['pl/we3c', NULL, '23', '0', '0']
                    ELSE ARRAY['pl/we3a', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '909'])
            
            -- (PL) Wskaźniki zakazu wjazdu elektrycznych pojazdów trakcyjnych (We4)
            WHEN "railway:signal:electricity" IN ('PL-PKP:we4a', 'PL-PKP:we4b', 'PL-PKP:we4c') AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'end_of_catenary'
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity:turn_direction" = 'right' THEN ARRAY['pl/we4b', NULL, '23.3033', '0', '0']
                    WHEN "railway:signal:electricity:turn_direction" = 'left' THEN ARRAY['pl/we4c', NULL, '23.3033', '0', '0']
                    ELSE ARRAY['pl/we4a', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '910'])
            
            -- (PL) Wskaźniki jazdy bezprądowej (We8)
            WHEN "railway:signal:electricity" IN ('PL-PKP:we8a', 'PL-PKP:we8b', 'PL-PKP:we8c') AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_off'
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity:turn_direction" = 'right' THEN ARRAY['pl/we8b', NULL, '23.3033', '0', '0']
                    WHEN "railway:signal:electricity:turn_direction" = 'left' THEN ARRAY['pl/we8c', NULL, '23.3033', '0', '0']
                    ELSE ARRAY['pl/we8a', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '911'])
            
            -- (PL) Wskaźniki jazdy pod prądem (We9)
            WHEN "railway:signal:electricity" IN ('PL-PKP:we9a', 'PL-PKP:we9b', 'PL-PKP:we9c') AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_on'
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity" = 'PL-PKP:we9b' THEN ARRAY['pl/we9b', NULL, '23.3033', '0', '0']
                    WHEN "railway:signal:electricity" = 'PL-PKP:we9c' THEN ARRAY['pl/we9c', NULL, '23', '0', '0']
                    ELSE ARRAY['pl/we9a', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '912'])
            
            -- (PL) Wskaźniki zmiany systemu zasilania (We10)
            WHEN "railway:signal:electricity" IN ('PL-PKP:we10a', 'PL-PKP:we10b', 'PL-PKP:we10c', 'PL-PKP:we10d', 'PL-PKP:we10e', 'PL-PKP:we10f') AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_change'
              THEN array_cat(CASE 
                    WHEN "railway:signal:electricity" = 'PL-PKP:we10b' THEN ARRAY['pl/we10b', NULL, '18', '0', '0']
                    WHEN "railway:signal:electricity" = 'PL-PKP:we10c' THEN ARRAY['pl/we10c', NULL, '18', '0', '0']
                    WHEN "railway:signal:electricity" = 'PL-PKP:we10d' THEN ARRAY['pl/we10d', NULL, '18', '0', '0']
                    WHEN "railway:signal:electricity" = 'PL-PKP:we10e' THEN ARRAY['pl/we10e', NULL, '18', '0', '0']
                    WHEN "railway:signal:electricity" = 'PL-PKP:we10f' THEN ARRAY['pl/we10f', NULL, '18', '0', '0']
                    ELSE ARRAY['pl/we10a', NULL, '18', '0', '0']
                  END, ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '913'])
            
            -- (PL) Granica zasilania wraz z izolatorem sekcyjnym (CT-1 i CT-2)
            WHEN "railway:signal:electricity" = 'PL-tram:ct-1;PL-tram:ct-2' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'isolation;power_limit'
              THEN array_cat(ARRAY['pl/ct-1-2', NULL, '16.002', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '914'])
            
            -- (PL) Izolator sekcyjny (CT-1)
            WHEN "railway:signal:electricity" = 'PL-tram:ct-1' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'isolation'
              THEN array_cat(ARRAY['pl/ct-1', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '915'])
            
            -- (PL) Granica zasilania (CT-2)
            WHEN "railway:signal:electricity" = 'PL-tram:ct-2' AND "railway:signal:electricity:form" = 'sign' AND "railway:signal:electricity:type" = 'power_limit'
              THEN array_cat(ARRAY['pl/ct-2', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:electricity:deactivated"::text, 'electrification', '916'])
            
            -- Unknown signal (electricity)
            ELSE
              ARRAY['general/signal-unknown-electricity', NULL, '17.1', '0', '0', NULL, 'false', 'electrification', NULL]
        END
      END as feature_electricity,
      CASE 
        WHEN "railway:signal:departure" IS NOT NULL THEN
          CASE 
            -- (AT) Hauptsignal (abfahrt)
            WHEN "railway:signal:main" = 'AT-V2:hauptsignal' AND "railway:signal:main:form" = 'light' AND "railway:signal:departure" = 'AT-V2:abfahrt' AND "railway:signal:departure:form" = 'light'
              THEN NULL
            
            -- (AT) Schutzsignal (abfahrt)
            WHEN "railway:signal:minor" = 'AT-V2:schutzsignal' AND "railway:signal:minor:form" = 'light' AND "railway:signal:departure" = 'AT-V2:abfahrt' AND "railway:signal:departure:form" = 'light'
              THEN NULL
            
            -- (AT) Abfahrt
            WHEN "railway:signal:departure" = 'AT-V2:abfahrt' AND "railway:signal:departure:form" = 'light'
              THEN array_cat(ARRAY['at/abfahrt', NULL, '8', '0', '0'], ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '43'])
            
            -- (AT) Fahrerlaubnissignal
            WHEN "railway:signal:departure" = 'AT-V2:fahrerlaubnissignal' AND "railway:signal:departure:form" = 'light'
              THEN array_cat(ARRAY['at/fahrerlaubnis', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '44'])
            
            -- (AU) Ready to Start
            WHEN "railway:signal:departure" = 'AU:LightRail:NSW:RTS' AND "railway:signal:departure:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/RTS', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '82'])
            
            -- (AU) End Yard Limit
            WHEN "railway:signal:departure" = 'AU:NSW:EYL' AND "railway:signal:departure:form" = 'sign'
              THEN array_cat(ARRAY['au/nsw/signs/EYL', NULL, '8', '0', '0'], ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '130'])
            
            -- (DE) Zp 9 (departure order) or Zp 10 (close doors)
            WHEN "railway:signal:departure" = 'DE-ESO:zp' AND "railway:signal:departure:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-ESO:zp10' = ANY("railway:signal:departure:states") THEN ARRAY['de/zp10-db', NULL, '16', '0', '0']
                    ELSE ARRAY['de/zp9-db', NULL, '15.441175', '0', '0']
                  END, ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '401'])
            
            -- (DE) tram departure signal
            WHEN "railway:signal:departure" IN ('DE-BOStrab:a', 'DE-BOStrab:a1', 'DE-BOStrab:a2') AND "railway:signal:departure:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN 'DE-BOStrab:a1' = ANY("railway:signal:departure:states") THEN ARRAY['de/bostrab/a1@bottom', NULL, '0', '10.135228', '0']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'DE-BOStrab:a2' = ANY("railway:signal:departure:states") THEN ARRAY['de/bostrab/a2@bottom', NULL, '0', '10.135228', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '402'])
            
            -- (GB) Departure
            WHEN "railway:signal:departure" = 'GB-NR:RA' AND "railway:signal:departure:form" = 'light'
              THEN array_cat(ARRAY['gb/departure-RA', NULL, '12.355966', '0', '0'], ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '691'])
            
            -- (IT) Indicatori di partenza (Avvio)
            WHEN "railway:signal:departure" = 'IT:PAR' AND "railway:signal:departure:form" = 'light' AND 'IT:AVV' = ANY("railway:signal:departure:substitute_signal")
              THEN array_cat(ARRAY['it/PAR-AVV', NULL, '19.072918', '0', '0'], ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '699'])
            
            -- (IT) Indicatori di partenza
            WHEN "railway:signal:departure" = 'IT:PAR' AND "railway:signal:departure:form" = 'light'
              THEN array_cat(ARRAY['it/PAR', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '700'])
            
            -- (NL) departure signal
            WHEN "railway:signal:departure" IN ('NL', 'NL:VL') AND "railway:signal:departure:form" = 'light'
              THEN array_cat(ARRAY['nl/departure', NULL, '21.632778', '0', '0'], ARRAY[NULL, "railway:signal:departure:deactivated"::text, 'signals', '756'])
            
            -- Unknown signal (departure)
            ELSE
              ARRAY['general/signal-unknown-departure', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_departure,
      CASE 
        WHEN "railway:signal:switch" IS NOT NULL THEN
          CASE 
            -- (AU) Facing Points Indicator
            WHEN "railway:signal:switch" = 'AU:NSW:facing_points' AND "railway:signal:switch:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/points_indicator_facing', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '147'])
            
            -- (AU) Trailing Points Indicator
            WHEN "railway:signal:switch" = 'AU:NSW:trailing_points' AND "railway:signal:switch:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/points_indicator_trailing', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '148'])
            
            -- (AU) Turnout Route
            WHEN "railway:signal:switch" = 'AU:NSW:turnout_route' AND "railway:signal:switch:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['right', 'left'] <@ "railway:signal:switch:states" THEN ARRAY['au/nsw/signals/turnout_both', NULL, '10', '0', '0']
                    WHEN 'right' = ANY("railway:signal:switch:states") THEN ARRAY['au/nsw/signals/turnout_right', NULL, '10', '0', '0']
                    WHEN 'left' = ANY("railway:signal:switch:states") THEN ARRAY['au/nsw/signals/turnout_left', NULL, '10', '0', '0']
                    ELSE ARRAY['au/nsw/signals/turnout_off', NULL, '10', '0', '0']
                  END, ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '163'])
            
            -- (AU) Mainline Indicator – Turnout
            WHEN "railway:signal:switch" = 'AU:NSW:MLI_turnout' AND "railway:signal:switch:form" = 'light'
              THEN array_cat(CASE 
                    WHEN ARRAY['right', 'left'] <@ "railway:signal:switch:states" THEN ARRAY['au/nsw/signals/MLI/turnout_both', NULL, '10', '0', '0']
                    WHEN 'right' = ANY("railway:signal:switch:states") THEN ARRAY['au/nsw/signals/MLI/turnout_right', NULL, '10', '0', '0']
                    WHEN 'left' = ANY("railway:signal:switch:states") THEN ARRAY['au/nsw/signals/MLI/turnout_left', NULL, '10', '0', '0']
                    ELSE ARRAY['au/nsw/signals/MLI/turnout_off', NULL, '10', '0', '0']
                  END, ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '164'])
            
            -- (AU) Gauge Indicator
            WHEN "railway:signal:switch" = 'AU:VIC:gauge_indicator' AND "railway:signal:switch:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/route/gauge', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '196'])
            
            -- (DE) local operated area
            WHEN "railway:signal:switch" = 'DE-DB:beginn_ortsstellbereich' AND "railway:signal:switch:form" = 'sign'
              THEN array_cat(ARRAY['de/ortsstellbereich', NULL, '13', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '370'])
            
            -- (DE) tram no trailing-point movement W 14 (sign)
            WHEN "railway:signal:switch" = 'DE-BOStrab:w' AND "railway:signal:switch:form" = 'sign' AND 'DE-BOStrab:w14' = ANY("railway:signal:switch:states")
              THEN array_cat(ARRAY['de/bostrab/w14-sign', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '482'])
            
            -- (DE) tram switch signal
            WHEN "railway:signal:switch" = 'DE-BOStrab:w' AND "railway:signal:switch:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-BOStrab:w14' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w14', NULL, '20', '0', '0']
                    WHEN 'DE-BOStrab:w13' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w13', NULL, '20', '0', '0']
                    WHEN 'DE-BOStrab:w3' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w3', NULL, '20', '0', '0']
                    WHEN 'DE-BOStrab:w12' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w12', NULL, '20', '0', '0']
                    WHEN 'DE-BOStrab:w2' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w2', NULL, '20', '0', '0']
                    WHEN 'DE-BOStrab:w11' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w11', NULL, '20', '0', '0']
                    WHEN 'DE-BOStrab:w1' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w1', NULL, '20', '0', '0']
                    WHEN 'DE-BOStrab:w0' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w0', NULL, '20', '0', '0']
                    ELSE ARRAY['de/bostrab/w-unknown', NULL, '20', '0', '0']
                  END, ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '483'])
            
            -- (DE) Karlsruhe tram switch signal
            WHEN "railway:signal:switch" = 'DE-VBK:w' AND "railway:signal:switch:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'DE-VBK:w15' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w14-yellow', NULL, '20', '0', '0']
                    WHEN 'DE-VBK:w13' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w13-yellow', NULL, '20', '0', '0']
                    WHEN 'DE-VBK:w3' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w3-yellow', NULL, '20', '0', '0']
                    WHEN 'DE-VBK:w12' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w12-yellow', NULL, '20', '0', '0']
                    WHEN 'DE-VBK:w2' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w2-yellow', NULL, '20', '0', '0']
                    WHEN 'DE-VBK:w11' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w11-yellow', NULL, '20', '0', '0']
                    WHEN 'DE-VBK:w1' = ANY("railway:signal:switch:states") THEN ARRAY['de/bostrab/w1-yellow', NULL, '20', '0', '0']
                    WHEN 'DE-VBK:w0' = ANY("railway:signal:switch:states") THEN ARRAY['de/vbk/w0', NULL, '20', '0', '0']
                    ELSE ARRAY['de/vbk/w5', NULL, '10', '0', '0']
                  END, ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '484'])
            
            -- (DE) Karlsruhe tram switch distant signal
            WHEN "railway:signal:switch" = 'DE-VBK:wv' AND "railway:signal:switch:form" = 'light'
              THEN array_cat(ARRAY['de/vbk/wv1', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '485'])
            
            -- (DE) tram signal contact St 1
            WHEN "railway:signal:switch" = 'DE-BOStrab:st1' AND "railway:signal:switch:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/st1', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '486'])
            
            -- (DE) tram switch contact St 2
            WHEN "railway:signal:switch" = 'DE-BOStrab:st2' AND "railway:signal:switch:form" = 'sign'
              THEN array_cat(ARRAY['de/bostrab/st2', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '487'])
            
            -- (NZ) Arrow Indicator
            WHEN "railway:signal:switch" = 'NZ:AI' AND "railway:signal:switch:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT ARRAY['nz/AI_unknown', NULL, '8', '0', '0'] as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'left' = ANY("railway:signal:switch:states") THEN ARRAY['nz/AI_L', NULL, '13.33', '0', '0']
                    WHEN 'right' = ANY("railway:signal:switch:states") THEN ARRAY['nz/AI_R', NULL, '13.33', '0', '0']
                    WHEN ARRAY['left', 'right'] <@ "railway:signal:switch:states" THEN ARRAY['nz/AI_LR', NULL, '8', '0', '0']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '790'])
            
            -- (PL) Zwrotnica elektryczna lewoskrętna (DT-1)
            WHEN "railway:signal:switch" = 'PL-tram:dt-1' AND "railway:signal:switch:form" = 'sign'
              THEN array_cat(ARRAY['pl/tram/dt-1', NULL, '4.233', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '888'])
            
            -- (PL) Zwrotnica elektryczna lewoskrętna (DT-2)
            WHEN "railway:signal:switch" = 'PL-tram:dt-2' AND "railway:signal:switch:form" = 'sign'
              THEN array_cat(ARRAY['pl/tram/dt-2', NULL, '4.233', '0', '0'], ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '889'])
            
            -- (PL) Znaki sterowania zwrotnicy
            WHEN "railway:signal:switch" IN ('PL-tram:switch_olsztyn', 'PL-tram:switch_poznan', 'PL-tram:switch_wroclaw', 'PL-tram:switch_warszawa') AND "railway:signal:switch:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:switch" = 'PL-tram:switch_olsztyn' THEN ARRAY['pl/tram/switch_olsztyn', NULL, '16', '0', '0']
                    WHEN "railway:signal:switch" = 'PL-tram:switch_poznan' THEN ARRAY['pl/tram/switch_poznan', NULL, '16', '0', '0']
                    WHEN "railway:signal:switch" = 'PL-tram:switch_wroclaw' THEN ARRAY['pl/tram/switch_wroclaw', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/tram/switch_warszawa', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:switch:deactivated"::text, 'signals', '890'])
            
            -- Unknown signal (switch)
            ELSE
              ARRAY['general/signal-unknown-switch', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_switch,
      CASE 
        WHEN "railway:signal:resetting_switch" IS NOT NULL THEN
          CASE 
            -- (AT) Weichenüberwachungssignal (PLB)
            WHEN "railway:signal:resetting_switch" = 'AT:weichenüberwachungssignal_plb' AND "railway:signal:resetting_switch:form" = 'light'
              THEN array_cat(ARRAY['at/weichenüberwachungssignal_plb', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:resetting_switch:deactivated"::text, 'signals', '39'])
            
            -- (CZ) Návěstidlo výhybky se samovratným přestavníkem
            WHEN "railway:signal:resetting_switch" = 'CZ-D1:navestidlo_vyhybky_se_samovratnym_prestavnikem' AND "railway:signal:resetting_switch:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'CZ-D1:jizda_nezajistena' = ANY("railway:signal:resetting_switch:states") THEN ARRAY['cz/navestidlo_vyhybky_se_samovratnym_prestavnikem/RW-W', NULL, '16.25', '0', '0']
                    ELSE ARRAY['cz/navestidlo_vyhybky_se_samovratnym_prestavnikem/W-W', NULL, '11', '0', '0']
                  END, ARRAY[NULL, "railway:signal:resetting_switch:deactivated"::text, 'signals', '341'])
            
            -- (DE) Ne13 resetting switch signal
            WHEN "railway:signal:resetting_switch" = 'DE-ESO:ne13' AND "railway:signal:resetting_switch:form" = 'light'
              THEN array_cat(ARRAY['de/ne13a', NULL, '9', '0', '0'], ARRAY[NULL, "railway:signal:resetting_switch:deactivated"::text, 'signals', '395'])
            
            -- Unknown signal (resetting_switch)
            ELSE
              ARRAY['general/signal-unknown-resetting_switch', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_resetting_switch,
      CASE 
        WHEN "railway:signal:resetting_switch_distant" IS NOT NULL THEN
          CASE 
            -- (DE) Ne12 resetting switch distant signal
            WHEN "railway:signal:resetting_switch_distant" = 'DE-ESO:ne12' AND "railway:signal:resetting_switch_distant:form" = 'sign'
              THEN array_cat(ARRAY['de/ne12', NULL, '22', '0', '0'], ARRAY[NULL, "railway:signal:resetting_switch_distant:deactivated"::text, 'signals', '396'])
            
            -- Unknown signal (resetting_switch_distant)
            ELSE
              ARRAY['general/signal-unknown-resetting_switch_distant', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_resetting_switch_distant,
      CASE 
        WHEN "railway:signal:humping" IS NOT NULL THEN
          CASE 
            -- (AT) Abdrucksignal
            WHEN "railway:signal:humping" = 'AT-V2:abdrucksignal' AND "railway:signal:humping:form" = 'light'
              THEN array_cat(ARRAY['at/abdrucksignal', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:humping:deactivated"::text, 'signals', '65'])
            
            -- (DE) humping signal Ra 6-9
            WHEN "railway:signal:humping" = 'DE-ESO:ra'
              THEN array_cat(CASE 
                    WHEN "railway:signal:humping:form" = 'semaphore' THEN ARRAY['de/ra7-semaphore', NULL, '16', '0', '0']
                    ELSE ARRAY['de/ra7', NULL, '15', '0', '0']
                  END, ARRAY[NULL, "railway:signal:humping:deactivated"::text, 'signals', '397'])
            
            -- (FI) Järjestelyopastin
            WHEN "railway:signal:humping" = 'FI:Jo' AND "railway:signal:humping:form" = 'light'
              THEN array_cat(ARRAY['fi/jo4', NULL, '15.627906', '0', '0'], ARRAY[NULL, "railway:signal:humping:deactivated"::text, 'signals', '588'])
            
            -- (NL) Humping ("heuvelen")
            WHEN "railway:signal:humping" = 'NL:270' AND "railway:signal:humping:form" = 'light'
              THEN array_cat(ARRAY['nl/270a', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:humping:deactivated"::text, 'signals', '757'])
            
            -- (PL) Tarcze rozrządowe (Tr, kształtowa i świetlna)
            WHEN "railway:signal:humping" = 'PL-PKP:rt' AND "railway:signal:humping:form" IN ('light', 'semaphore')
              THEN array_cat(CASE 
                    WHEN "railway:signal:humping:form" = 'light' THEN ARRAY['pl/rt3-light', NULL, '16', '0', '0']
                    ELSE ARRAY['pl/rt3-semaphore', NULL, '16', '0', '0']
                  END, ARRAY[NULL, "railway:signal:humping:deactivated"::text, 'signals', '854'])
            
            -- Unknown signal (humping)
            ELSE
              ARRAY['general/signal-unknown-humping', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_humping,
      CASE 
        WHEN "railway:signal:snowplow" IS NOT NULL THEN
          CASE 
            -- (AT) Räumarbeit aufnehmen
            WHEN "railway:signal:snowplow" = 'AT-V2:räumarbeit_aufnehmen' AND "railway:signal:snowplow:type" = 'down' AND "railway:signal:snowplow:form" = 'sign'
              THEN array_cat(ARRAY['at/räumarbeit-aufnehmen', NULL, '16.52713', '0', '0'], ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '62'])
            
            -- (AT) Mittelräumer heben
            WHEN "railway:signal:snowplow" = 'AT-V2:mittelräumer_heben' AND "railway:signal:snowplow:type" = 'up' AND "railway:signal:snowplow:form" = 'sign'
              THEN array_cat(ARRAY['at/mittelräumer-heben', NULL, '23.050322', '0', '0'], ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '63'])
            
            -- (AT) Räumarbeit einstellen
            WHEN "railway:signal:snowplow" = 'AT-V2:räumarbeit_einstellen' AND "railway:signal:snowplow:type" = 'up' AND "railway:signal:snowplow:form" = 'sign'
              THEN array_cat(ARRAY['at/räumarbeit-einstellen', NULL, '23.050322', '0', '0'], ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '64'])
            
            -- (DE) Lift / Fold snowplow Ne 7 (sign)
            WHEN "railway:signal:snowplow" = 'DE-ESO:ne7' AND "railway:signal:snowplow:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:snowplow:type" = 'down' THEN ARRAY['de/ne7-yellow-down', NULL, '15', '0', '0']
                    ELSE ARRAY['de/ne7-yellow-up', NULL, '15', '0', '0']
                  END, ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '394'])
            
            -- (FI) Raise snowplow blades (point)
            WHEN "railway:signal:snowplow" IN ('FI:T-170A', 'FI:T-171') AND "railway:signal:snowplow:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-171', NULL, '15.338637', '0', '0'], ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '589'])
            
            -- (FI) Raise snowplow blades (area)
            WHEN "railway:signal:snowplow" IN ('FI:T-170B', 'FI:T-171A') AND "railway:signal:snowplow:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-171A', NULL, '15.338637', '0', '0'], ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '590'])
            
            -- (FI) Raise snowplow blades (old)
            WHEN "railway:signal:snowplow" = 'FI:T-170-v' AND "railway:signal:snowplow:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-170-v', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '591'])
            
            -- (FI) Lower snowplow blades
            WHEN "railway:signal:snowplow" = 'FI:T-171B' AND "railway:signal:snowplow:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-171B', NULL, '15.338637', '0', '0'], ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '592'])
            
            -- (FI) Lower snowplow blades (old)
            WHEN "railway:signal:snowplow" = 'FI:T-171-v' AND "railway:signal:snowplow:form" = 'sign'
              THEN array_cat(ARRAY['fi/t-171-v', NULL, '18', '0', '0'], ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '593'])
            
            -- (PL) Wskaźnik torowy (W13)
            WHEN "railway:signal:snowplow" = 'PL-PKP:w13' AND "railway:signal:snowplow:form" = 'sign' AND "railway:signal:snowplow:type" = 'up'
              THEN array_cat(ARRAY['pl/w13', NULL, '20', '0', '0'], ARRAY[NULL, "railway:signal:snowplow:deactivated"::text, 'signals', '866'])
            
            -- Unknown signal (snowplow)
            ELSE
              ARRAY['general/signal-unknown-snowplow', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_snowplow,
      CASE 
        WHEN "railway:signal:wrong_road" IS NOT NULL THEN
          CASE 
            -- (DE) wrong road signal Zs 6 (DB) (sign)
            WHEN "railway:signal:wrong_road" = 'DE-ESO:db:zs6' AND "railway:signal:wrong_road:form" = 'sign'
              THEN array_cat(ARRAY['de/zs6-sign', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:wrong_road:deactivated"::text, 'signals', '409'])
            
            -- (DE) wrong road signal Zs 6 (DB) (light)
            WHEN "railway:signal:wrong_road" = 'DE-ESO:db:zs6' AND "railway:signal:wrong_road:form" = 'light'
              THEN array_cat(ARRAY['de/zs6-db-light', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:wrong_road:deactivated"::text, 'signals', '410'])
            
            -- (DE) wrong road signal Zs 7 (DR) (light)
            WHEN "railway:signal:wrong_road" = 'DE-ESO:dr:zs7' AND "railway:signal:wrong_road:form" = 'light'
              THEN array_cat(ARRAY['de/zs7-dr-light', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:wrong_road:deactivated"::text, 'signals', '411'])
            
            -- (FR) Wrong route (entry)
            WHEN "railway:signal:wrong_road" = 'FR:TECS' AND "railway:signal:wrong_road:form" IN ('sign', 'light')
              THEN array_cat(ARRAY['fr/TECS', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:wrong_road:deactivated"::text, 'signals', '647'])
            
            -- (FR) Wrong route (exit)
            WHEN "railway:signal:wrong_road" = 'FR:TSCS' AND "railway:signal:wrong_road:form" IN ('sign', 'light')
              THEN array_cat(ARRAY['fr/TSCS', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:wrong_road:deactivated"::text, 'signals', '648'])
            
            -- (PL) Wskaźnik kierunku przeciwnego (W24)
            WHEN "railway:signal:wrong_road" = 'PL-PKP:w24' AND "railway:signal:wrong_road:form" = 'light'
              THEN array_cat(ARRAY['pl/w24', NULL, '11', '0', '0'], ARRAY[NULL, "railway:signal:wrong_road:deactivated"::text, 'signals', '870'])
            
            -- Unknown signal (wrong_road)
            ELSE
              ARRAY['general/signal-unknown-wrong_road', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_wrong_road,
      CASE 
        WHEN "railway:signal:short_route" IS NOT NULL THEN
          CASE 
            -- (AU) Dead End Siding (Right)
            WHEN "railway:signal:short_route" = 'AU:NSW:dead_end' AND "railway:signal:short_route:form" = 'light' AND "railway:signal:short_route:shape" = 'right'
              THEN array_cat(ARRAY['au/nsw/signals/dead_end_right', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:short_route:deactivated"::text, 'signals', '157'])
            
            -- (AU) Dead End Siding (Left)
            WHEN "railway:signal:short_route" = 'AU:NSW:dead_end' AND "railway:signal:short_route:form" = 'light' AND "railway:signal:short_route:shape" = 'left'
              THEN array_cat(ARRAY['au/nsw/signals/dead_end_left', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:short_route:deactivated"::text, 'signals', '158'])
            
            -- (AU) Low Speed
            WHEN "railway:signal:short_route" = 'AU:VIC:low_speed' AND "railway:signal:short_route:form" = 'light' AND "railway:signal:main:height" = 'dwarf'
              THEN array_cat(ARRAY['au/vic/signals/low_speed_dwarf', NULL, '5', '0', '0'], ARRAY[NULL, "railway:signal:short_route:deactivated"::text, 'signals', '202'])
            
            -- (AU) Low Speed
            WHEN "railway:signal:short_route" = 'AU:VIC:low_speed' AND "railway:signal:short_route:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/low_speed', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:short_route:deactivated"::text, 'signals', '203'])
            
            -- (DE) entry into dead-end / early stop marker Zs 13 / Zs 6 (DR) (sign)
            WHEN "railway:signal:short_route" IN ('DE-ESO:zs13', 'DE-ESO:dr:zs6') AND "railway:signal:short_route:form" = 'sign'
              THEN array_cat(ARRAY['de/zs13-sign', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:short_route:deactivated"::text, 'signals', '412'])
            
            -- (DE) entry into dead-end / early stop marker Zs 13 / Zs 6 (DR) (light)
            WHEN "railway:signal:short_route" IN ('DE-ESO:zs13', 'DE-ESO:dr:zs6') AND "railway:signal:short_route:form" = 'light'
              THEN array_cat(ARRAY['de/zs13-light', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:short_route:deactivated"::text, 'signals', '413'])
            
            -- (PL) Wskaźniki braku drogi hamowania (W19 i W20)
            WHEN "railway:signal:short_route" IN ('PL-PKP:w19', 'PL-PKP:w20', 'PL-PKP:w19;PL-PKP:w20') AND "railway:signal:short_route:form" IN ('sign', 'light')
              THEN array_cat(CASE 
                    WHEN "railway:signal:short_route" = 'PL-PKP:w20' THEN ARRAY['pl/w20', NULL, '10', '0', '0']
                    WHEN "railway:signal:short_route" = 'PL-PKP:w19;PL-PKP:w20' THEN ARRAY['pl/w19-20', NULL, '20', '0', '0']
                    ELSE ARRAY['pl/w19', NULL, '10', '0', '0']
                  END, ARRAY[NULL, "railway:signal:short_route:deactivated"::text, 'signals', '869'])
            
            -- Unknown signal (short_route)
            ELSE
              ARRAY['general/signal-unknown-short_route', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_short_route,
      CASE 
        WHEN "railway:signal:route" IS NOT NULL THEN
          CASE 
            -- (AU) Set Route
            WHEN "railway:signal:route" IN ('AU:LightRail:ACT:set_route', 'AU:LightRail:QLD:set_route') AND "railway:signal:route:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/set_route_ACT', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '83'])
            
            -- (AU) Set Route
            WHEN "railway:signal:route" = 'AU:LightRail:NSW:set_route' AND "railway:signal:route:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/set_route_NSW', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '84'])
            
            -- (AU) 2nd Command Stud
            WHEN "railway:signal:route" = 'AU:LightRail:VIC:command_stud_2' AND "railway:signal:route:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/command_stud_2', NULL, '7', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '106'])
            
            -- (AU) 1st Command Stud
            WHEN "railway:signal:route" = 'AU:LightRail:VIC:command_stud_1' AND "railway:signal:route:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/command_stud_1', NULL, '7', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '107'])
            
            -- (AU) 1st Command Stud (Signal Operated Points)
            WHEN "railway:signal:route" = 'AU:LightRail:VIC:command_stud_1SPI' AND "railway:signal:route:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/command_stud_1SPI', NULL, '7', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '108'])
            
            -- (AU) Route Indicator (Illuminated Arrows)
            WHEN "railway:signal:route" = 'AU:VIC:points_direction' AND "railway:signal:route:form" = 'light'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN 'left' = ANY("railway:signal:route:states") THEN ARRAY['au/vic/signals/route/arrows/left@right', NULL, '0', '0', '10']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'straight' = ANY("railway:signal:route:states") THEN ARRAY['au/vic/signals/route/arrows/straight@right', NULL, '0', '0', '10']
                    
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN 'right' = ANY("railway:signal:route:states") THEN ARRAY['au/vic/signals/route/arrows/right@right', NULL, '0', '0', '10']
                    
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '197'])
            
            -- (AU) Route Indicator (Painted Arrows)
            WHEN "railway:signal:route" = 'AU:VIC:painted_arrow' AND "railway:signal:route:form" = 'sign' AND 'LR' = ANY("railway:signal:route:states")
              THEN array_cat(ARRAY['au/vic/signals/route/arrow_LR', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '198'])
            
            -- (AU) Route Indicator (Painted Arrows)
            WHEN "railway:signal:route" = 'AU:VIC:painted_arrow' AND "railway:signal:route:form" = 'sign' AND 'RL' = ANY("railway:signal:route:states")
              THEN array_cat(ARRAY['au/vic/signals/route/arrow_RL', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '199'])
            
            -- (AU) Route Indicator (Stencil Light)
            WHEN "railway:signal:route" = 'AU:VIC:stencil' AND "railway:signal:route:form" = 'light'
              THEN array_cat(ARRAY['au/vic/signals/route/stencil', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '200'])
            
            -- (AU) Route Indicator
            WHEN "railway:signal:route" IN ('AU:MNWSW:route_indicator', 'AU:NSW:theatre_box', 'AU:VIC:theatre_box', 'AU:VIC:lamp', 'AU:VIC:sign', 'AU:LightRail:route_indicator', 'NZ:route_indicator') AND "railway:signal:route:form" IN ('light', 'sign')
              THEN array_cat(CASE 
                    WHEN '^([A-Z1-4])$' ~!@# ANY("railway:signal:route:states") THEN ARRAY[CONCAT('au/route_indicator/{', (select match from (select regexp_substr(match, '^([A-Z1-4])$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([A-Z1-4])$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '12', '0', '0']
                    ELSE ARRAY['au/route_indicator/unknown', NULL, '14.000002', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '223'])
            
            -- (BE) Main signal indicator
            WHEN "railway:signal:route" = 'BE:ECS' AND "railway:signal:route:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'BE:ECS-V' = ANY("railway:signal:route:states") THEN ARRAY['be/ECS-V', NULL, '13.333333', '0', '0']
                    WHEN 'BE:ECS-U' = ANY("railway:signal:route:states") THEN ARRAY['be/ECS-U', NULL, '13.333333', '0', '0']
                    WHEN 'BE:ECS-CAB' = ANY("railway:signal:route:states") THEN ARRAY['be/ECS-CAB', NULL, '12', '0', '0']
                    ELSE ARRAY['be/ECS-unknown', NULL, '13.333333', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '251'])
            
            -- (DE) Richtungsanzeiger (Zs 2)
            WHEN "railway:signal:route" = 'DE-ESO:zs2' AND "railway:signal:route:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^([A-ZÄÖÜẞ])$' ~!@# ANY("railway:signal:route:states") THEN ARRAY[CONCAT('de/zs2-{', (select match from (select regexp_substr(match, '^([A-ZÄÖÜẞ])$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([A-ZÄÖÜẞ])$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '12', '0', '0']
                    ELSE ARRAY['de/zs2-unknown', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '481'])
            
            -- (FR) Route indicator
            WHEN "railway:signal:route" = 'FR:ID' AND "railway:signal:route:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'FR:ID5' = ANY("railway:signal:main:states") THEN ARRAY['fr/ID5', NULL, '9.344', '0', '0']
                    WHEN 'FR:ID4' = ANY("railway:signal:main:states") THEN ARRAY['fr/ID4', NULL, '9.344', '0', '0']
                    WHEN 'FR:ID3' = ANY("railway:signal:main:states") THEN ARRAY['fr/ID3', NULL, '7.385', '0', '0']
                    WHEN 'FR:ID2' = ANY("railway:signal:main:states") THEN ARRAY['fr/ID2', NULL, '7.385', '0', '0']
                    ELSE ARRAY['fr/ID3', NULL, '7.385', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '646'])
            
            -- (GB) Junction signals (feather & theatre)
            WHEN "railway:signal:route" = 'GB-NR:junction' AND "railway:signal:route:form" = 'light' AND "railway:signal:route:design" = 'feather;theatre'
              THEN array_cat((
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text, SUM(icon[4]::numeric)::text, MAX(icon[5]::numeric)::text]
                FROM (
                  SELECT CASE 
                    WHEN ARRAY['position_1', 'position_2', 'position_3', 'position_4'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-1234', NULL, '32.974034', '0', '0']
                    WHEN ARRAY['position_1', 'position_4', 'position_5', 'position_6'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-1456', NULL, '32.974034', '0', '0']
                    WHEN ARRAY['position_1', 'position_4', 'position_5'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-145', NULL, '20.175108', '0', '0']
                    WHEN ARRAY['position_4', 'position_5', 'position_6'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-456', NULL, '33.654872', '0', '0']
                    WHEN ARRAY['position_1', 'position_2', 'position_3'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-123', NULL, '33.654872', '0', '0']
                    WHEN ARRAY['position_1', 'position_2', 'position_4'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-124', NULL, '20.175108', '0', '0']
                    WHEN ARRAY['position_4', 'position_5'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-45', NULL, '20.607268', '0', '0']
                    WHEN ARRAY['position_1', 'position_4'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-14', NULL, '15.032361', '0', '0']
                    WHEN ARRAY['position_1', 'position_2'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-12', NULL, '20.607268', '0', '0']
                    WHEN 'position_4' = ANY("railway:signal:route:states") THEN ARRAY['gb/route-feather-4', NULL, '15.026616', '0', '0']
                    WHEN 'position_1' = ANY("railway:signal:route:states") THEN ARRAY['gb/route-feather-1', NULL, '15.026616', '0', '0']
                    ELSE ARRAY['gb/route-feather-unknown', NULL, '19.781178', '0', '0']
                  END as icon
                  UNION ALL
                  SELECT CASE 
                    WHEN '^[CFSU]$' ~!@# ANY("railway:signal:route:states") THEN ARRAY[CONCAT('gb/route-theatre-{', (select match from (select regexp_substr(match, '^[CFSU]$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}@bottom'), (select match from (select regexp_substr(match, '^[CFSU]$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '0', '12', '0']
                    ELSE ARRAY['gb/route-theatre-unknown@bottom', NULL, '0', '12.000001', '0']
                  END as icon
                ) icons
                WHERE icon[1] IS NOT NULL
              ), ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '688'])
            
            -- (GB) Junction signals (feather)
            WHEN "railway:signal:route" = 'GB-NR:junction' AND "railway:signal:route:form" = 'light' AND "railway:signal:route:design" = 'feather'
              THEN array_cat(CASE 
                    WHEN ARRAY['position_1', 'position_2', 'position_3', 'position_4'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-1234', NULL, '32.974034', '0', '0']
                    WHEN ARRAY['position_1', 'position_4', 'position_5', 'position_6'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-1456', NULL, '32.974034', '0', '0']
                    WHEN ARRAY['position_1', 'position_4', 'position_5'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-145', NULL, '20.175108', '0', '0']
                    WHEN ARRAY['position_4', 'position_5', 'position_6'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-456', NULL, '33.654872', '0', '0']
                    WHEN ARRAY['position_1', 'position_2', 'position_3'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-123', NULL, '33.654872', '0', '0']
                    WHEN ARRAY['position_1', 'position_2', 'position_4'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-124', NULL, '20.175108', '0', '0']
                    WHEN ARRAY['position_4', 'position_5'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-45', NULL, '20.607268', '0', '0']
                    WHEN ARRAY['position_1', 'position_4'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-14', NULL, '15.032361', '0', '0']
                    WHEN ARRAY['position_1', 'position_2'] <@ "railway:signal:route:states" THEN ARRAY['gb/route-feather-12', NULL, '20.607268', '0', '0']
                    WHEN 'position_4' = ANY("railway:signal:route:states") THEN ARRAY['gb/route-feather-4', NULL, '15.026616', '0', '0']
                    WHEN 'position_1' = ANY("railway:signal:route:states") THEN ARRAY['gb/route-feather-1', NULL, '15.026616', '0', '0']
                    ELSE ARRAY['gb/route-feather-unknown', NULL, '19.781178', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '689'])
            
            -- (GB) Junction signals (theatre)
            WHEN "railway:signal:route" = 'GB-NR:junction' AND "railway:signal:route:form" = 'light' AND "railway:signal:route:design" = 'theatre'
              THEN array_cat(CASE 
                    WHEN '^[CFSU]$' ~!@# ANY("railway:signal:route:states") THEN ARRAY[CONCAT('gb/route-theatre-{', (select match from (select regexp_substr(match, '^[CFSU]$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[CFSU]$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '12', '0', '0']
                    ELSE ARRAY['gb/route-theatre-unknown', NULL, '12.000001', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '690'])
            
            -- (IT) Route
            WHEN "railway:signal:route" = 'IT:ROUTE' AND "railway:signal:route:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^[1-4]$' ~!@# ANY("railway:signal:route:states") THEN ARRAY[CONCAT('it/route-{', (select match from (select regexp_substr(match, '^[1-4]$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[1-4]$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '14.000002', '0', '0']
                    ELSE ARRAY['it/route-unknown', NULL, '14.000002', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '698'])
            
            -- (NZ) Loop Light
            WHEN "railway:signal:route" = 'NZ:L' AND "railway:signal:route:form" = 'light'
              THEN array_cat(ARRAY['nz/L', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '793'])
            
            -- (NZ) Electrified Route Light
            WHEN "railway:signal:route" = 'NZ:E' AND "railway:signal:route:form" = 'light'
              THEN array_cat(ARRAY['nz/E', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '794'])
            
            -- (PL) Wskaźniki kierunku jazdy (W2, W26a,  W26b)
            WHEN "railway:signal:route" IN ('PL-PKP:w2', 'PL-PKP:w26a', 'PL-PKP:w26b') AND "railway:signal:route:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^[A-ZŁ]$' ~!@# ANY("railway:signal:route:states") THEN ARRAY[CONCAT('pl/w2-{', (select match from (select regexp_substr(match, '^[A-ZŁ]$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^[A-ZŁ]$') as match from (select unnest("railway:signal:route:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '12', '0', '0']
                    ELSE ARRAY['pl/w2-{K}', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route:deactivated"::text, 'signals', '858'])
            
            -- Unknown signal (route)
            ELSE
              ARRAY['general/signal-unknown-route', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_route,
      CASE 
        WHEN "railway:signal:route_distant" IS NOT NULL THEN
          CASE 
            -- (AU) Turnout Repeater
            WHEN "railway:signal:route_distant" = 'AU:NSW:turnout_repeater' AND "railway:signal:route_distant:form" = 'light' AND "railway:signal:route_distant:shape" = 'theatre_box'
              THEN array_cat(ARRAY['au/nsw/signals/route_distant_theatre_box', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:route_distant:deactivated"::text, 'signals', '172'])
            
            -- (AU) Turnout Repeater (feather-style)
            WHEN "railway:signal:route_distant" = 'AU:NSW:turnout_repeater' AND "railway:signal:route_distant:form" = 'light' AND "railway:signal:route_distant:shape" = 'feather'
              THEN array_cat(ARRAY['au/nsw/signals/route_distant_feather', NULL, '12', '0', '0'], ARRAY[NULL, "railway:signal:route_distant:deactivated"::text, 'signals', '173'])
            
            -- (DE) Richtungsvoranzeiger (Zs 2v)
            WHEN "railway:signal:route_distant" = 'DE-ESO:zs2v' AND "railway:signal:route_distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN '^([A-ZÄÖÜẞ])$' ~!@# ANY("railway:signal:route_distant:states") THEN ARRAY[CONCAT('de/zs2v-{', (select match from (select regexp_substr(match, '^([A-ZÄÖÜẞ])$') as match from (select unnest("railway:signal:route_distant:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '}'), (select match from (select regexp_substr(match, '^([A-ZÄÖÜẞ])$') as match from (select unnest("railway:signal:route_distant:states") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1), '12', '0', '0']
                    ELSE ARRAY['de/zs2v-unknown', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route_distant:deactivated"::text, 'signals', '414'])
            
            -- (FR) Distant route indicator
            WHEN "railway:signal:route_distant" = 'FR:TIDD' AND "railway:signal:route_distant:form" = 'light'
              THEN array_cat(CASE 
                    WHEN 'right' = ANY("railway:signal:route_distant:states") THEN ARRAY['fr/TIDD-right', NULL, '14.90625', '0', '0']
                    WHEN 'left' = ANY("railway:signal:route_distant:states") THEN ARRAY['fr/TIDD-left', NULL, '14.90625', '0', '0']
                    ELSE ARRAY['fr/TIDD-off', NULL, '14.90625', '0', '0']
                  END, ARRAY[NULL, "railway:signal:route_distant:deactivated"::text, 'signals', '643'])
            
            -- (FR) Branch line
            WHEN "railway:signal:route_distant" = 'FR:BIF' AND "railway:signal:route_distant:form" = 'sign'
              THEN array_cat(ARRAY['fr/BIF', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:route_distant:deactivated"::text, 'signals', '644'])
            
            -- (FR) Switch junction
            WHEN "railway:signal:route_distant" = 'FR:Y' AND "railway:signal:route_distant:form" = 'sign'
              THEN array_cat(ARRAY['fr/Y', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:route_distant:deactivated"::text, 'signals', '645'])
            
            -- (GB) Preliminary Route Indicator
            WHEN "railway:signal:route_distant" = 'GB-NR:PRI' AND "railway:signal:route_distant:form" = 'light'
              THEN array_cat(ARRAY['gb/preliminary-route-indicator', NULL, '15.47541', '0', '0'], ARRAY[NULL, "railway:signal:route_distant:deactivated"::text, 'signals', '685'])
            
            -- Unknown signal (route_distant)
            ELSE
              ARRAY['general/signal-unknown-route_distant', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_route_distant,
      CASE 
        WHEN "railway:signal:brake_test" IS NOT NULL THEN
          CASE 
            -- (DE) brake test signal Zp 6-8
            WHEN "railway:signal:brake_test" = 'DE-ESO:zp' AND "railway:signal:brake_test:form" = 'light'
              THEN array_cat(ARRAY['de/zp8', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:brake_test:deactivated"::text, 'signals', '400'])
            
            -- Unknown signal (brake_test)
            ELSE
              ARRAY['general/signal-unknown-brake_test', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_brake_test,
      CASE 
        WHEN "railway:signal:helper_engine" IS NOT NULL THEN
          CASE 
            -- (AU) Tonnage Light
            WHEN "railway:signal:helper_engine" = 'AU:NSW:tonnage' AND "railway:signal:helper_engine:form" = 'light'
              THEN array_cat(ARRAY['au/nsw/signals/tonnage', NULL, '10', '0', '0'], ARRAY[NULL, "railway:signal:helper_engine:deactivated"::text, 'signals', '155'])
            
            -- (DE) helper engine signal Ts
            WHEN "railway:signal:helper_engine" = 'DE-ESO:ts' AND "railway:signal:helper_engine:form" = 'sign'
              THEN array_cat(ARRAY['de/ts1', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:helper_engine:deactivated"::text, 'signals', '399'])
            
            -- (PL) Wskaźniki odcinka z popychaniem (W10a i W10b)
            WHEN "railway:signal:helper_engine" IN ('PL-PKP:w10a', 'PL-PKP:w10b') AND "railway:signal:helper_engine:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:helper_engine" = 'PL-PKP:w10b' THEN ARRAY['pl/w10b', NULL, '14', '0', '0']
                    ELSE ARRAY['pl/w10a', NULL, '14', '0', '0']
                  END, ARRAY[NULL, "railway:signal:helper_engine:deactivated"::text, 'signals', '863'])
            
            -- Unknown signal (helper_engine)
            ELSE
              ARRAY['general/signal-unknown-helper_engine', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_helper_engine,
      CASE 
        WHEN "railway:signal:steam_locomotive" IS NOT NULL THEN
          CASE 
            -- (PL) Wskaźnik parowozowy (W12)
            WHEN "railway:signal:steam_locomotive" = 'PL-PKP:w12' AND "railway:signal:steam_locomotive:form" = 'sign'
              THEN array_cat(ARRAY['pl/w12', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:steam_locomotive:deactivated"::text, 'signals', '865'])
            
            -- Unknown signal (steam_locomotive)
            ELSE
              ARRAY['general/signal-unknown-steam_locomotive', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_steam_locomotive,
      CASE 
        WHEN "railway:signal:fouling_point" IS NOT NULL THEN
          CASE 
            -- (AU) Points Cleared
            WHEN "railway:signal:fouling_point" = 'AU:MNWSW:points_cleared'
              THEN array_cat(ARRAY['au/nsw/metro/points_cleared', NULL, '10.4', '0', '0'], ARRAY[NULL, "railway:signal:fouling_point:deactivated"::text, 'signals', '69'])
            
            -- (AU) 50/50
            WHEN "railway:signal:fouling_point" = 'AU:LightRail:VIC:50/50' AND "railway:signal:fouling_point:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/5050', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:fouling_point:deactivated"::text, 'signals', '95'])
            
            -- (AU) Fouling Mark
            WHEN "railway:signal:fouling_point" = 'AU:LightRail:VIC:single_yellow' AND "railway:signal:fouling_point:form" = 'sign'
              THEN array_cat(ARRAY['au/LightRail/signs/vic/single_yellow', NULL, '15', '0', '0'], ARRAY[NULL, "railway:signal:fouling_point:deactivated"::text, 'signals', '96'])
            
            -- (AU) Points Cleared
            WHEN "railway:signal:fouling_point" = 'AU:NSW:points_cleared'
              THEN array_cat(ARRAY['au/nsw/signs/points_cleared', NULL, '10.4', '0', '0'], ARRAY[NULL, "railway:signal:fouling_point:deactivated"::text, 'signals', '135'])
            
            -- (BE) Balise marker
            WHEN "railway:signal:fouling_point" = 'BE:PRB'
              THEN array_cat(ARRAY['be/PRB', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:fouling_point:deactivated"::text, 'signals', '253'])
            
            -- (GB) Rear Clear marker
            WHEN "railway:signal:fouling_point" = 'GB-NR:rear_clear' AND "railway:signal:fouling_point:form" = 'sign'
              THEN array_cat(ARRAY['gb/rear-clear', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:fouling_point:deactivated"::text, 'signals', '694'])
            
            -- (PL) Wskaźnik ukresu (W17)
            WHEN "railway:signal:fouling_point" = 'PL-PKP:w17'
              THEN array_cat(ARRAY['pl/w17', NULL, '10.000001', '0', '0'], ARRAY[NULL, "railway:signal:fouling_point:deactivated"::text, 'signals', '868'])
            
            -- (PL) Wskaźnik ukresu (Wm17)
            WHEN "railway:signal:fouling_point" = 'PL-metro:wm17'
              THEN array_cat(ARRAY['pl/metro/wm17', NULL, '2', '0', '0'], ARRAY[NULL, "railway:signal:fouling_point:deactivated"::text, 'signals', '880'])
            
            -- Unknown signal (fouling_point)
            ELSE
              ARRAY['general/signal-unknown-fouling_point', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_fouling_point,
      CASE 
        WHEN "railway:signal:preheating" IS NOT NULL THEN
          CASE 
            -- (PL) Wskaźnik ogrzewania (W25)
            WHEN "railway:signal:preheating" = 'PL-PKP:w25' AND "railway:signal:preheating:form" = 'light'
              THEN array_cat(ARRAY['pl/w25', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:preheating:deactivated"::text, 'signals', '871'])
            
            -- Unknown signal (preheating)
            ELSE
              ARRAY['general/signal-unknown-preheating', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_preheating,
      CASE 
        WHEN "railway:signal:slope" IS NOT NULL THEN
          CASE 
            -- (BE) Gradient >=12‰ <18‰
            WHEN "railway:signal:slope" = 'BE:i12' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['be/i12', NULL, '12.78261', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '224'])
            
            -- (BE) Gradient >=18‰
            WHEN "railway:signal:slope" = 'BE:i18' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['be/i18', NULL, '12.782604', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '225'])
            
            -- (CH) Beginn oder Änderung der Steigung
            WHEN "railway:signal:slope" = 'CH-FDV:269' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['ch/fdv-269', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '303'])
            
            -- (CH) Beginn oder Änderung des Gefälles
            WHEN "railway:signal:slope" = 'CH-FDV:270' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['ch/fdv-270', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '304'])
            
            -- (CH) Beginn der Horizontalen
            WHEN "railway:signal:slope" = 'CH-FDV:271' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['ch/fdv-271', NULL, '14', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '305'])
            
            -- (ES) flecha ascendente
            WHEN "railway:signal:slope" = 'ES-RCF:FI11A' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['es/FI11A', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '513'])
            
            -- (ES) línea horizontal
            WHEN "railway:signal:slope" = 'ES-RCF:FI11B' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['es/FI11B', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '514'])
            
            -- (ES) flecha descendente
            WHEN "railway:signal:slope" = 'ES-RCF:FI11C' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['es/FI11C', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '515'])
            
            -- (ES) rampa media ascendente entre 9 y 15 mm/m
            WHEN "railway:signal:slope" = 'ES-RCF:FI12A' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['es/FI12A', NULL, '13.714286', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '516'])
            
            -- (ES) rampa media ascendente entre 16 y 25 mm/m
            WHEN "railway:signal:slope" = 'ES-RCF:FI12B' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['es/FI12B', NULL, '13.714286', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '517'])
            
            -- (ES) rampa media descendente entre 9 y 15 mm/m
            WHEN "railway:signal:slope" = 'ES-RCF:FI12C' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['es/FI12C', NULL, '13.714286', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '518'])
            
            -- (ES) rampa media descendente entre 16 y 25 mm/m
            WHEN "railway:signal:slope" = 'ES-RCF:FI12D' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['es/FI12D', NULL, '13.714286', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '519'])
            
            -- (GB) Gradient post
            WHEN "railway:signal:slope" = 'GB-NR:gradient' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(CASE 
                    WHEN "railway:signal:slope:shape" = 'board' THEN ARRAY['gb/gradient-board', NULL, '10', '0', '0']
                    ELSE ARRAY['gb/gradient-arms', NULL, '12', '0', '0']
                  END, ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '697'])
            
            -- (PL) Niebezpieczny zjazd (AT-3)
            WHEN "railway:signal:slope" = 'PL-tram:at-3' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['pl/tram/at-3', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '883'])
            
            -- (PL) Stromy podjazd (AT-4)
            WHEN "railway:signal:slope" = 'PL-tram:at-4' AND "railway:signal:slope:form" = 'sign'
              THEN array_cat(ARRAY['pl/tram/at-4', NULL, '16', '0', '0'], ARRAY[NULL, "railway:signal:slope:deactivated"::text, 'signals', '884'])
            
            -- Unknown signal (slope)
            ELSE
              ARRAY['general/signal-unknown-slope', NULL, '17.1', '0', '0', NULL, 'false', 'signals', NULL]
        END
      END as feature_slope
    FROM signals s
    WHERE
      (railway IN ('signal', 'buffer_stop') AND signal_direction IS NOT NULL)
        OR railway IN ('derail', 'vacancy_detection')
  ),
  -- Output a feature row for every feature
  signals_with_features_1 AS (
    
    SELECT
      signal_id,
      feature_main[1] as feature,
      feature_main[2] as feature_variable,
      GREATEST(feature_main[3]::REAL + feature_main[4]::REAL, feature_main[5]::REAL) as icon_height,
      feature_main[6] as type,
      feature_main[7]::boolean as deactivated,
      feature_main[8]::signal_layer as layer,
      feature_main[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_main IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_combined[1] as feature,
      feature_combined[2] as feature_variable,
      GREATEST(feature_combined[3]::REAL + feature_combined[4]::REAL, feature_combined[5]::REAL) as icon_height,
      feature_combined[6] as type,
      feature_combined[7]::boolean as deactivated,
      feature_combined[8]::signal_layer as layer,
      feature_combined[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_combined IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_distant[1] as feature,
      feature_distant[2] as feature_variable,
      GREATEST(feature_distant[3]::REAL + feature_distant[4]::REAL, feature_distant[5]::REAL) as icon_height,
      feature_distant[6] as type,
      feature_distant[7]::boolean as deactivated,
      feature_distant[8]::signal_layer as layer,
      feature_distant[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_distant IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_train_protection[1] as feature,
      feature_train_protection[2] as feature_variable,
      GREATEST(feature_train_protection[3]::REAL + feature_train_protection[4]::REAL, feature_train_protection[5]::REAL) as icon_height,
      feature_train_protection[6] as type,
      feature_train_protection[7]::boolean as deactivated,
      feature_train_protection[8]::signal_layer as layer,
      feature_train_protection[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_train_protection IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_main_repeated[1] as feature,
      feature_main_repeated[2] as feature_variable,
      GREATEST(feature_main_repeated[3]::REAL + feature_main_repeated[4]::REAL, feature_main_repeated[5]::REAL) as icon_height,
      feature_main_repeated[6] as type,
      feature_main_repeated[7]::boolean as deactivated,
      feature_main_repeated[8]::signal_layer as layer,
      feature_main_repeated[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_main_repeated IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_speed_limit[1] as feature,
      feature_speed_limit[2] as feature_variable,
      GREATEST(feature_speed_limit[3]::REAL + feature_speed_limit[4]::REAL, feature_speed_limit[5]::REAL) as icon_height,
      feature_speed_limit[6] as type,
      feature_speed_limit[7]::boolean as deactivated,
      feature_speed_limit[8]::signal_layer as layer,
      feature_speed_limit[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_speed_limit IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_speed_limit_distant[1] as feature,
      feature_speed_limit_distant[2] as feature_variable,
      GREATEST(feature_speed_limit_distant[3]::REAL + feature_speed_limit_distant[4]::REAL, feature_speed_limit_distant[5]::REAL) as icon_height,
      feature_speed_limit_distant[6] as type,
      feature_speed_limit_distant[7]::boolean as deactivated,
      feature_speed_limit_distant[8]::signal_layer as layer,
      feature_speed_limit_distant[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_speed_limit_distant IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_minor[1] as feature,
      feature_minor[2] as feature_variable,
      GREATEST(feature_minor[3]::REAL + feature_minor[4]::REAL, feature_minor[5]::REAL) as icon_height,
      feature_minor[6] as type,
      feature_minor[7]::boolean as deactivated,
      feature_minor[8]::signal_layer as layer,
      feature_minor[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_minor IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_minor_distant[1] as feature,
      feature_minor_distant[2] as feature_variable,
      GREATEST(feature_minor_distant[3]::REAL + feature_minor_distant[4]::REAL, feature_minor_distant[5]::REAL) as icon_height,
      feature_minor_distant[6] as type,
      feature_minor_distant[7]::boolean as deactivated,
      feature_minor_distant[8]::signal_layer as layer,
      feature_minor_distant[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_minor_distant IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_passing[1] as feature,
      feature_passing[2] as feature_variable,
      GREATEST(feature_passing[3]::REAL + feature_passing[4]::REAL, feature_passing[5]::REAL) as icon_height,
      feature_passing[6] as type,
      feature_passing[7]::boolean as deactivated,
      feature_passing[8]::signal_layer as layer,
      feature_passing[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_passing IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_shunting[1] as feature,
      feature_shunting[2] as feature_variable,
      GREATEST(feature_shunting[3]::REAL + feature_shunting[4]::REAL, feature_shunting[5]::REAL) as icon_height,
      feature_shunting[6] as type,
      feature_shunting[7]::boolean as deactivated,
      feature_shunting[8]::signal_layer as layer,
      feature_shunting[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_shunting IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_shunting_route[1] as feature,
      feature_shunting_route[2] as feature_variable,
      GREATEST(feature_shunting_route[3]::REAL + feature_shunting_route[4]::REAL, feature_shunting_route[5]::REAL) as icon_height,
      feature_shunting_route[6] as type,
      feature_shunting_route[7]::boolean as deactivated,
      feature_shunting_route[8]::signal_layer as layer,
      feature_shunting_route[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_shunting_route IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_radio[1] as feature,
      feature_radio[2] as feature_variable,
      GREATEST(feature_radio[3]::REAL + feature_radio[4]::REAL, feature_radio[5]::REAL) as icon_height,
      feature_radio[6] as type,
      feature_radio[7]::boolean as deactivated,
      feature_radio[8]::signal_layer as layer,
      feature_radio[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_radio IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_stop[1] as feature,
      feature_stop[2] as feature_variable,
      GREATEST(feature_stop[3]::REAL + feature_stop[4]::REAL, feature_stop[5]::REAL) as icon_height,
      feature_stop[6] as type,
      feature_stop[7]::boolean as deactivated,
      feature_stop[8]::signal_layer as layer,
      feature_stop[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_stop IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_stop_distant[1] as feature,
      feature_stop_distant[2] as feature_variable,
      GREATEST(feature_stop_distant[3]::REAL + feature_stop_distant[4]::REAL, feature_stop_distant[5]::REAL) as icon_height,
      feature_stop_distant[6] as type,
      feature_stop_distant[7]::boolean as deactivated,
      feature_stop_distant[8]::signal_layer as layer,
      feature_stop_distant[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_stop_distant IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_stop_demand[1] as feature,
      feature_stop_demand[2] as feature_variable,
      GREATEST(feature_stop_demand[3]::REAL + feature_stop_demand[4]::REAL, feature_stop_demand[5]::REAL) as icon_height,
      feature_stop_demand[6] as type,
      feature_stop_demand[7]::boolean as deactivated,
      feature_stop_demand[8]::signal_layer as layer,
      feature_stop_demand[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_stop_demand IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_station_distant[1] as feature,
      feature_station_distant[2] as feature_variable,
      GREATEST(feature_station_distant[3]::REAL + feature_station_distant[4]::REAL, feature_station_distant[5]::REAL) as icon_height,
      feature_station_distant[6] as type,
      feature_station_distant[7]::boolean as deactivated,
      feature_station_distant[8]::signal_layer as layer,
      feature_station_distant[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_station_distant IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_crossing[1] as feature,
      feature_crossing[2] as feature_variable,
      GREATEST(feature_crossing[3]::REAL + feature_crossing[4]::REAL, feature_crossing[5]::REAL) as icon_height,
      feature_crossing[6] as type,
      feature_crossing[7]::boolean as deactivated,
      feature_crossing[8]::signal_layer as layer,
      feature_crossing[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_crossing IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_crossing_distant[1] as feature,
      feature_crossing_distant[2] as feature_variable,
      GREATEST(feature_crossing_distant[3]::REAL + feature_crossing_distant[4]::REAL, feature_crossing_distant[5]::REAL) as icon_height,
      feature_crossing_distant[6] as type,
      feature_crossing_distant[7]::boolean as deactivated,
      feature_crossing_distant[8]::signal_layer as layer,
      feature_crossing_distant[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_crossing_distant IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_crossing_info[1] as feature,
      feature_crossing_info[2] as feature_variable,
      GREATEST(feature_crossing_info[3]::REAL + feature_crossing_info[4]::REAL, feature_crossing_info[5]::REAL) as icon_height,
      feature_crossing_info[6] as type,
      feature_crossing_info[7]::boolean as deactivated,
      feature_crossing_info[8]::signal_layer as layer,
      feature_crossing_info[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_crossing_info IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_crossing_hint[1] as feature,
      feature_crossing_hint[2] as feature_variable,
      GREATEST(feature_crossing_hint[3]::REAL + feature_crossing_hint[4]::REAL, feature_crossing_hint[5]::REAL) as icon_height,
      feature_crossing_hint[6] as type,
      feature_crossing_hint[7]::boolean as deactivated,
      feature_crossing_hint[8]::signal_layer as layer,
      feature_crossing_hint[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_crossing_hint IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_ring[1] as feature,
      feature_ring[2] as feature_variable,
      GREATEST(feature_ring[3]::REAL + feature_ring[4]::REAL, feature_ring[5]::REAL) as icon_height,
      feature_ring[6] as type,
      feature_ring[7]::boolean as deactivated,
      feature_ring[8]::signal_layer as layer,
      feature_ring[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_ring IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_whistle[1] as feature,
      feature_whistle[2] as feature_variable,
      GREATEST(feature_whistle[3]::REAL + feature_whistle[4]::REAL, feature_whistle[5]::REAL) as icon_height,
      feature_whistle[6] as type,
      feature_whistle[7]::boolean as deactivated,
      feature_whistle[8]::signal_layer as layer,
      feature_whistle[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_whistle IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_electricity[1] as feature,
      feature_electricity[2] as feature_variable,
      GREATEST(feature_electricity[3]::REAL + feature_electricity[4]::REAL, feature_electricity[5]::REAL) as icon_height,
      feature_electricity[6] as type,
      feature_electricity[7]::boolean as deactivated,
      feature_electricity[8]::signal_layer as layer,
      feature_electricity[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_electricity IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_departure[1] as feature,
      feature_departure[2] as feature_variable,
      GREATEST(feature_departure[3]::REAL + feature_departure[4]::REAL, feature_departure[5]::REAL) as icon_height,
      feature_departure[6] as type,
      feature_departure[7]::boolean as deactivated,
      feature_departure[8]::signal_layer as layer,
      feature_departure[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_departure IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_switch[1] as feature,
      feature_switch[2] as feature_variable,
      GREATEST(feature_switch[3]::REAL + feature_switch[4]::REAL, feature_switch[5]::REAL) as icon_height,
      feature_switch[6] as type,
      feature_switch[7]::boolean as deactivated,
      feature_switch[8]::signal_layer as layer,
      feature_switch[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_switch IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_resetting_switch[1] as feature,
      feature_resetting_switch[2] as feature_variable,
      GREATEST(feature_resetting_switch[3]::REAL + feature_resetting_switch[4]::REAL, feature_resetting_switch[5]::REAL) as icon_height,
      feature_resetting_switch[6] as type,
      feature_resetting_switch[7]::boolean as deactivated,
      feature_resetting_switch[8]::signal_layer as layer,
      feature_resetting_switch[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_resetting_switch IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_resetting_switch_distant[1] as feature,
      feature_resetting_switch_distant[2] as feature_variable,
      GREATEST(feature_resetting_switch_distant[3]::REAL + feature_resetting_switch_distant[4]::REAL, feature_resetting_switch_distant[5]::REAL) as icon_height,
      feature_resetting_switch_distant[6] as type,
      feature_resetting_switch_distant[7]::boolean as deactivated,
      feature_resetting_switch_distant[8]::signal_layer as layer,
      feature_resetting_switch_distant[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_resetting_switch_distant IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_humping[1] as feature,
      feature_humping[2] as feature_variable,
      GREATEST(feature_humping[3]::REAL + feature_humping[4]::REAL, feature_humping[5]::REAL) as icon_height,
      feature_humping[6] as type,
      feature_humping[7]::boolean as deactivated,
      feature_humping[8]::signal_layer as layer,
      feature_humping[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_humping IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_snowplow[1] as feature,
      feature_snowplow[2] as feature_variable,
      GREATEST(feature_snowplow[3]::REAL + feature_snowplow[4]::REAL, feature_snowplow[5]::REAL) as icon_height,
      feature_snowplow[6] as type,
      feature_snowplow[7]::boolean as deactivated,
      feature_snowplow[8]::signal_layer as layer,
      feature_snowplow[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_snowplow IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_wrong_road[1] as feature,
      feature_wrong_road[2] as feature_variable,
      GREATEST(feature_wrong_road[3]::REAL + feature_wrong_road[4]::REAL, feature_wrong_road[5]::REAL) as icon_height,
      feature_wrong_road[6] as type,
      feature_wrong_road[7]::boolean as deactivated,
      feature_wrong_road[8]::signal_layer as layer,
      feature_wrong_road[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_wrong_road IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_short_route[1] as feature,
      feature_short_route[2] as feature_variable,
      GREATEST(feature_short_route[3]::REAL + feature_short_route[4]::REAL, feature_short_route[5]::REAL) as icon_height,
      feature_short_route[6] as type,
      feature_short_route[7]::boolean as deactivated,
      feature_short_route[8]::signal_layer as layer,
      feature_short_route[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_short_route IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_route[1] as feature,
      feature_route[2] as feature_variable,
      GREATEST(feature_route[3]::REAL + feature_route[4]::REAL, feature_route[5]::REAL) as icon_height,
      feature_route[6] as type,
      feature_route[7]::boolean as deactivated,
      feature_route[8]::signal_layer as layer,
      feature_route[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_route IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_route_distant[1] as feature,
      feature_route_distant[2] as feature_variable,
      GREATEST(feature_route_distant[3]::REAL + feature_route_distant[4]::REAL, feature_route_distant[5]::REAL) as icon_height,
      feature_route_distant[6] as type,
      feature_route_distant[7]::boolean as deactivated,
      feature_route_distant[8]::signal_layer as layer,
      feature_route_distant[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_route_distant IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_brake_test[1] as feature,
      feature_brake_test[2] as feature_variable,
      GREATEST(feature_brake_test[3]::REAL + feature_brake_test[4]::REAL, feature_brake_test[5]::REAL) as icon_height,
      feature_brake_test[6] as type,
      feature_brake_test[7]::boolean as deactivated,
      feature_brake_test[8]::signal_layer as layer,
      feature_brake_test[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_brake_test IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_helper_engine[1] as feature,
      feature_helper_engine[2] as feature_variable,
      GREATEST(feature_helper_engine[3]::REAL + feature_helper_engine[4]::REAL, feature_helper_engine[5]::REAL) as icon_height,
      feature_helper_engine[6] as type,
      feature_helper_engine[7]::boolean as deactivated,
      feature_helper_engine[8]::signal_layer as layer,
      feature_helper_engine[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_helper_engine IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_steam_locomotive[1] as feature,
      feature_steam_locomotive[2] as feature_variable,
      GREATEST(feature_steam_locomotive[3]::REAL + feature_steam_locomotive[4]::REAL, feature_steam_locomotive[5]::REAL) as icon_height,
      feature_steam_locomotive[6] as type,
      feature_steam_locomotive[7]::boolean as deactivated,
      feature_steam_locomotive[8]::signal_layer as layer,
      feature_steam_locomotive[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_steam_locomotive IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_fouling_point[1] as feature,
      feature_fouling_point[2] as feature_variable,
      GREATEST(feature_fouling_point[3]::REAL + feature_fouling_point[4]::REAL, feature_fouling_point[5]::REAL) as icon_height,
      feature_fouling_point[6] as type,
      feature_fouling_point[7]::boolean as deactivated,
      feature_fouling_point[8]::signal_layer as layer,
      feature_fouling_point[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_fouling_point IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_preheating[1] as feature,
      feature_preheating[2] as feature_variable,
      GREATEST(feature_preheating[3]::REAL + feature_preheating[4]::REAL, feature_preheating[5]::REAL) as icon_height,
      feature_preheating[6] as type,
      feature_preheating[7]::boolean as deactivated,
      feature_preheating[8]::signal_layer as layer,
      feature_preheating[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_preheating IS NOT NULL
  
    UNION ALL
  
    SELECT
      signal_id,
      feature_slope[1] as feature,
      feature_slope[2] as feature_variable,
      GREATEST(feature_slope[3]::REAL + feature_slope[4]::REAL, feature_slope[5]::REAL) as icon_height,
      feature_slope[6] as type,
      feature_slope[7]::boolean as deactivated,
      feature_slope[8]::signal_layer as layer,
      feature_slope[9]::INT as rank
    FROM signals_with_features_0
    WHERE feature_slope IS NOT NULL
  
    UNION ALL
    SELECT
      signal_id,
      'general/signal-unknown' as feature,
      NULL as feature_variable,
      17.1 as icon_height,
      NULL as type,
      false as deactivated,
      'signals' as layer,
      NULL as rank
    FROM signals_with_features_0
    WHERE railway = 'signal'
      AND feature_main IS NULL AND feature_combined IS NULL AND feature_distant IS NULL AND feature_train_protection IS NULL AND feature_main_repeated IS NULL AND feature_speed_limit IS NULL AND feature_speed_limit_distant IS NULL AND feature_minor IS NULL AND feature_minor_distant IS NULL AND feature_passing IS NULL AND feature_shunting IS NULL AND feature_shunting_route IS NULL AND feature_radio IS NULL AND feature_stop IS NULL AND feature_stop_distant IS NULL AND feature_stop_demand IS NULL AND feature_station_distant IS NULL AND feature_crossing IS NULL AND feature_crossing_distant IS NULL AND feature_crossing_info IS NULL AND feature_crossing_hint IS NULL AND feature_ring IS NULL AND feature_whistle IS NULL AND feature_electricity IS NULL AND feature_departure IS NULL AND feature_switch IS NULL AND feature_resetting_switch IS NULL AND feature_resetting_switch_distant IS NULL AND feature_humping IS NULL AND feature_snowplow IS NULL AND feature_wrong_road IS NULL AND feature_short_route IS NULL AND feature_route IS NULL AND feature_route_distant IS NULL AND feature_brake_test IS NULL AND feature_helper_engine IS NULL AND feature_steam_locomotive IS NULL AND feature_fouling_point IS NULL AND feature_preheating IS NULL AND feature_slope IS NULL
  )
  -- Group features by signal, and aggregate the results
  SELECT
    signal_id,
    any_value(type) as type,
    layer,
    array_agg(feature ORDER BY rank ASC NULLS LAST) as features,
    array_agg(deactivated ORDER BY rank ASC NULLS LAST) as deactivated,
    array_agg(icon_height ORDER BY rank ASC NULLS LAST) as icon_height,
    MAX(rank) as rank
  FROM signals_with_features_1 sf
  GROUP BY signal_id, layer;

-- Use the view directly such that the query in the view can be updated
CREATE MATERIALIZED VIEW IF NOT EXISTS signal_features AS
  SELECT
    *
  FROM
    signal_features_view;

CREATE INDEX IF NOT EXISTS signal_features_signal_id_index
  ON signal_features
    USING btree(signal_id);

CLUSTER signal_features
  USING signal_features_signal_id_index;
  
CREATE OR REPLACE VIEW signals_railway_signals_view AS
  SELECT
    osm_id as id,
    way,
    osm_id,
    'N' as osm_type,
    rank,
    railway,
    sd.direction_both,
    ref,
    caption,
    position,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description,
    sd.azimuth,
    "railway:signal:brake_test",
    "railway:signal:brake_test:form",
    "railway:signal:brake_test:deactivated",
    "railway:signal:combined",
    "railway:signal:combined:form",
    "railway:signal:combined:states",
    "railway:signal:combined:shape",
    "railway:signal:combined:type",
    "railway:signal:combined:shortened",
    "railway:signal:combined:substitute_signal",
    "railway:signal:combined:height",
    "railway:signal:combined:function",
    "railway:signal:combined:deactivated",
    "railway:signal:crossing",
    "railway:signal:crossing:form",
    "railway:signal:crossing:repeated",
    "railway:signal:crossing:shortened",
    "railway:signal:crossing:deactivated",
    "railway:signal:crossing_distant",
    "railway:signal:crossing_distant:states",
    "railway:signal:crossing_distant:shortened",
    "railway:signal:crossing_distant:form",
    "railway:signal:crossing_distant:deactivated",
    "railway:signal:crossing_hint",
    "railway:signal:crossing_hint:form",
    "railway:signal:crossing_hint:deactivated",
    "railway:signal:crossing_info",
    "railway:signal:crossing_info:form",
    "railway:signal:crossing_info:deactivated",
    "railway:signal:departure",
    "railway:signal:departure:form",
    "railway:signal:departure:states",
    "railway:signal:departure:substitute_signal",
    "railway:signal:departure:deactivated",
    "railway:signal:danger",
    "railway:signal:danger:form",
    "railway:signal:distant",
    "railway:signal:distant:form",
    "railway:signal:distant:repeated",
    "railway:signal:distant:shortened",
    "railway:signal:distant:states",
    "railway:signal:distant:height",
    "railway:signal:distant:type",
    "railway:signal:distant:distance",
    "railway:signal:distant:deactivated",
    "railway:signal:distant:shape",
    "railway:signal:distant:function",
    "railway:signal:electricity",
    "railway:signal:electricity:type",
    "railway:signal:electricity:form",
    "railway:signal:electricity:for",
    "railway:signal:electricity:turn_direction",
    "railway:signal:electricity:voltage",
    "railway:signal:electricity:frequency",
    "railway:signal:electricity:deactivated",
    "railway:signal:fouling_point",
    "railway:signal:fouling_point:form",
    "railway:signal:fouling_point:deactivated",
    "railway:signal:helper_engine",
    "railway:signal:helper_engine:form",
    "railway:signal:helper_engine:deactivated",
    "railway:signal:humping",
    "railway:signal:humping:form",
    "railway:signal:humping:deactivated",
    "railway:signal:main",
    "railway:signal:main:design",
    "railway:signal:main:form",
    "railway:signal:main:height",
    "railway:signal:main:shape",
    "railway:signal:main:lit_letter",
    "railway:signal:main:states",
    "railway:signal:main:substitute_signal",
    "railway:signal:main:PT_priority",
    "railway:signal:main:type",
    "railway:signal:main:function",
    "railway:signal:main:shortened",
    "railway:signal:main:deactivated",
    "railway:signal:main_repeated",
    "railway:signal:main_repeated:form",
    "railway:signal:main_repeated:magnet",
    "railway:signal:main_repeated:states",
    "railway:signal:main_repeated:substitute_signal",
    "railway:signal:main_repeated:shape",
    "railway:signal:main_repeated:deactivated",
    "railway:signal:minor",
    "railway:signal:minor:form",
    "railway:signal:minor:states",
    "railway:signal:minor:height",
    "railway:signal:minor:shape",
    "railway:signal:minor:substitute_signal",
    "railway:signal:minor:function",
    "railway:signal:minor:deactivated",
    "railway:signal:minor_distant",
    "railway:signal:minor_distant:form",
    "railway:signal:minor_distant:states",
    "railway:signal:minor_distant:deactivated",
    "railway:signal:passing",
    "railway:signal:passing:form",
    "railway:signal:passing:type",
    "railway:signal:passing:deactivated",
    "railway:signal:resetting_switch",
    "railway:signal:resetting_switch:form",
    "railway:signal:resetting_switch:states",
    "railway:signal:resetting_switch:deactivated",
    "railway:signal:resetting_switch_distant",
    "railway:signal:resetting_switch_distant:form",
    "railway:signal:resetting_switch_distant:deactivated",
    "railway:signal:preheating",
    "railway:signal:preheating:form",
    "railway:signal:preheating:deactivated",
    "railway:signal:ring",
    "railway:signal:ring:form",
    "railway:signal:ring:only_transit",
    "railway:signal:ring:deactivated",
    "railway:signal:radio",
    "railway:signal:radio:form",
    "railway:signal:radio:frequency",
    "railway:signal:radio:deactivated",
    "railway:signal:route",
    "railway:signal:route:design",
    "railway:signal:route:form",
    "railway:signal:route:states",
    "railway:signal:route:deactivated",
    "railway:signal:route_distant",
    "railway:signal:route_distant:form",
    "railway:signal:route_distant:shape",
    "railway:signal:route_distant:states",
    "railway:signal:route_distant:deactivated",
    "railway:signal:short_route",
    "railway:signal:short_route:form",
    "railway:signal:short_route:shape",
    "railway:signal:short_route:deactivated",
    "railway:signal:shunting",
    "railway:signal:shunting:form",
    "railway:signal:shunting:states",
    "railway:signal:shunting:shape",
    "railway:signal:shunting:height",
    "railway:signal:shunting:deactivated",
    "railway:signal:shunting:repeated",
    "railway:signal:shunting_route",
    "railway:signal:shunting_route:form",
    "railway:signal:shunting_route:states",
    "railway:signal:shunting_route:deactivated",
    "railway:signal:slope",
    "railway:signal:slope:form",
    "railway:signal:slope:type",
    "railway:signal:slope:deactivated",
    "railway:signal:slope:incline",
    "railway:signal:slope:length",
    "railway:signal:slope:shape",
    "railway:signal:slope:distance",
    "railway:signal:snowplow",
    "railway:signal:snowplow:form",
    "railway:signal:snowplow:type",
    "railway:signal:snowplow:deactivated",
    "railway:signal:speed_limit",
    "railway:signal:speed_limit:caption",
    "railway:signal:speed_limit:form",
    "railway:signal:speed_limit:speed",
    "railway:signal:speed_limit:states",
    "railway:signal:speed_limit:pointing",
    "railway:signal:speed_limit:deactivated",
    "railway:signal:speed_limit:turn_direction",
    "railway:signal:speed_limit:type",
    "railway:signal:speed_limit_distant",
    "railway:signal:speed_limit_distant:form",
    "railway:signal:speed_limit_distant:shortened",
    "railway:signal:speed_limit_distant:speed",
    "railway:signal:speed_limit_distant:mobile",
    "railway:signal:speed_limit_distant:deactivated",
    "railway:signal:speed_limit_distant:distance",
    "railway:signal:station_distant",
    "railway:signal:station_distant:form",
    "railway:signal:station_distant:type",
    "railway:signal:station_distant:deactivated",
    "railway:signal:station_distant:shortened",
    "railway:signal:steam_locomotive",
    "railway:signal:steam_locomotive:form",
    "railway:signal:steam_locomotive:deactivated",
    "railway:signal:stop",
    "railway:signal:stop:form",
    "railway:signal:stop:caption",
    "railway:signal:stop:states",
    "railway:signal:stop:carriages",
    "railway:signal:stop:deactivated",
    "railway:signal:stop_distant",
    "railway:signal:stop_distant:form",
    "railway:signal:stop_distant:distance",
    "railway:signal:stop_distant:deactivated",
    "railway:signal:stop_demand",
    "railway:signal:stop_demand:form",
    "railway:signal:stop_demand:deactivated",
    "railway:signal:switch",
    "railway:signal:switch:form",
    "railway:signal:switch:states",
    "railway:signal:switch:deactivated",
    "railway:signal:train_protection",
    "railway:signal:train_protection:block_marker:type",
    "railway:signal:train_protection:form",
    "railway:signal:train_protection:shape",
    "railway:signal:train_protection:type",
    "railway:signal:train_protection:turn_direction",
    "railway:signal:train_protection:deactivated",
    "railway:signal:train_protection:main",
    "railway:signal:train_protection:main:form",
    "railway:signal:train_protection:system_change",
    "railway:signal:train_protection:system_change:form",
    "railway:signal:traversable",
    "railway:signal:traversable:form",
    "railway:signal:traversable:type",
    "railway:signal:whistle",
    "railway:signal:whistle:form",
    "railway:signal:whistle:only_transit",
    "railway:signal:whistle:deactivated",
    "railway:signal:wrong_road",
    "railway:signal:wrong_road:form",
    "railway:signal:wrong_road:deactivated",
    "railway:vacancy_detection",
    "railway:signal:regime",
    "railway:signal:position",
    "railway:signal:location",
    features[1] as feature0,
    features[2] as feature1,
    features[3] as feature2,
    features[4] as feature3,
    features[5] as feature4,
    features[6] as feature5,
    deactivated[1] as deactivated0,
    deactivated[2] as deactivated1,
    deactivated[3] as deactivated2,
    deactivated[4] as deactivated3,
    deactivated[5] as deactivated4,
    deactivated[6] as deactivated5,
    CEIL(icon_height[1] / 2) as offset0,
    CEIL(icon_height[1] / 2 + icon_height[2] / 2) as offset1,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] / 2) as offset2,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] / 2) as offset3,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] + icon_height[5] / 2) as offset4,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] + icon_height[5] + icon_height[6] / 2) as offset5,
    type
  FROM signals s
  JOIN signal_features sf
    ON s.osm_id = sf.signal_id
  JOIN signal_direction sd
    ON s.osm_id = sd.signal_id
  WHERE layer = 'signals';
  
CREATE OR REPLACE VIEW speed_railway_signals_view AS
  SELECT
    osm_id as id,
    way,
    osm_id,
    'N' as osm_type,
    rank,
    railway,
    sd.direction_both,
    ref,
    caption,
    position,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description,
    sd.azimuth,
    "railway:signal:brake_test",
    "railway:signal:brake_test:form",
    "railway:signal:brake_test:deactivated",
    "railway:signal:combined",
    "railway:signal:combined:form",
    "railway:signal:combined:states",
    "railway:signal:combined:shape",
    "railway:signal:combined:type",
    "railway:signal:combined:shortened",
    "railway:signal:combined:substitute_signal",
    "railway:signal:combined:height",
    "railway:signal:combined:function",
    "railway:signal:combined:deactivated",
    "railway:signal:crossing",
    "railway:signal:crossing:form",
    "railway:signal:crossing:repeated",
    "railway:signal:crossing:shortened",
    "railway:signal:crossing:deactivated",
    "railway:signal:crossing_distant",
    "railway:signal:crossing_distant:states",
    "railway:signal:crossing_distant:shortened",
    "railway:signal:crossing_distant:form",
    "railway:signal:crossing_distant:deactivated",
    "railway:signal:crossing_hint",
    "railway:signal:crossing_hint:form",
    "railway:signal:crossing_hint:deactivated",
    "railway:signal:crossing_info",
    "railway:signal:crossing_info:form",
    "railway:signal:crossing_info:deactivated",
    "railway:signal:departure",
    "railway:signal:departure:form",
    "railway:signal:departure:states",
    "railway:signal:departure:substitute_signal",
    "railway:signal:departure:deactivated",
    "railway:signal:danger",
    "railway:signal:danger:form",
    "railway:signal:distant",
    "railway:signal:distant:form",
    "railway:signal:distant:repeated",
    "railway:signal:distant:shortened",
    "railway:signal:distant:states",
    "railway:signal:distant:height",
    "railway:signal:distant:type",
    "railway:signal:distant:distance",
    "railway:signal:distant:deactivated",
    "railway:signal:distant:shape",
    "railway:signal:distant:function",
    "railway:signal:electricity",
    "railway:signal:electricity:type",
    "railway:signal:electricity:form",
    "railway:signal:electricity:for",
    "railway:signal:electricity:turn_direction",
    "railway:signal:electricity:voltage",
    "railway:signal:electricity:frequency",
    "railway:signal:electricity:deactivated",
    "railway:signal:fouling_point",
    "railway:signal:fouling_point:form",
    "railway:signal:fouling_point:deactivated",
    "railway:signal:helper_engine",
    "railway:signal:helper_engine:form",
    "railway:signal:helper_engine:deactivated",
    "railway:signal:humping",
    "railway:signal:humping:form",
    "railway:signal:humping:deactivated",
    "railway:signal:main",
    "railway:signal:main:design",
    "railway:signal:main:form",
    "railway:signal:main:height",
    "railway:signal:main:shape",
    "railway:signal:main:lit_letter",
    "railway:signal:main:states",
    "railway:signal:main:substitute_signal",
    "railway:signal:main:PT_priority",
    "railway:signal:main:type",
    "railway:signal:main:function",
    "railway:signal:main:shortened",
    "railway:signal:main:deactivated",
    "railway:signal:main_repeated",
    "railway:signal:main_repeated:form",
    "railway:signal:main_repeated:magnet",
    "railway:signal:main_repeated:states",
    "railway:signal:main_repeated:substitute_signal",
    "railway:signal:main_repeated:shape",
    "railway:signal:main_repeated:deactivated",
    "railway:signal:minor",
    "railway:signal:minor:form",
    "railway:signal:minor:states",
    "railway:signal:minor:height",
    "railway:signal:minor:shape",
    "railway:signal:minor:substitute_signal",
    "railway:signal:minor:function",
    "railway:signal:minor:deactivated",
    "railway:signal:minor_distant",
    "railway:signal:minor_distant:form",
    "railway:signal:minor_distant:states",
    "railway:signal:minor_distant:deactivated",
    "railway:signal:passing",
    "railway:signal:passing:form",
    "railway:signal:passing:type",
    "railway:signal:passing:deactivated",
    "railway:signal:resetting_switch",
    "railway:signal:resetting_switch:form",
    "railway:signal:resetting_switch:states",
    "railway:signal:resetting_switch:deactivated",
    "railway:signal:resetting_switch_distant",
    "railway:signal:resetting_switch_distant:form",
    "railway:signal:resetting_switch_distant:deactivated",
    "railway:signal:preheating",
    "railway:signal:preheating:form",
    "railway:signal:preheating:deactivated",
    "railway:signal:ring",
    "railway:signal:ring:form",
    "railway:signal:ring:only_transit",
    "railway:signal:ring:deactivated",
    "railway:signal:radio",
    "railway:signal:radio:form",
    "railway:signal:radio:frequency",
    "railway:signal:radio:deactivated",
    "railway:signal:route",
    "railway:signal:route:design",
    "railway:signal:route:form",
    "railway:signal:route:states",
    "railway:signal:route:deactivated",
    "railway:signal:route_distant",
    "railway:signal:route_distant:form",
    "railway:signal:route_distant:shape",
    "railway:signal:route_distant:states",
    "railway:signal:route_distant:deactivated",
    "railway:signal:short_route",
    "railway:signal:short_route:form",
    "railway:signal:short_route:shape",
    "railway:signal:short_route:deactivated",
    "railway:signal:shunting",
    "railway:signal:shunting:form",
    "railway:signal:shunting:states",
    "railway:signal:shunting:shape",
    "railway:signal:shunting:height",
    "railway:signal:shunting:deactivated",
    "railway:signal:shunting:repeated",
    "railway:signal:shunting_route",
    "railway:signal:shunting_route:form",
    "railway:signal:shunting_route:states",
    "railway:signal:shunting_route:deactivated",
    "railway:signal:slope",
    "railway:signal:slope:form",
    "railway:signal:slope:type",
    "railway:signal:slope:deactivated",
    "railway:signal:slope:incline",
    "railway:signal:slope:length",
    "railway:signal:slope:shape",
    "railway:signal:slope:distance",
    "railway:signal:snowplow",
    "railway:signal:snowplow:form",
    "railway:signal:snowplow:type",
    "railway:signal:snowplow:deactivated",
    "railway:signal:speed_limit",
    "railway:signal:speed_limit:caption",
    "railway:signal:speed_limit:form",
    "railway:signal:speed_limit:speed",
    "railway:signal:speed_limit:states",
    "railway:signal:speed_limit:pointing",
    "railway:signal:speed_limit:deactivated",
    "railway:signal:speed_limit:turn_direction",
    "railway:signal:speed_limit:type",
    "railway:signal:speed_limit_distant",
    "railway:signal:speed_limit_distant:form",
    "railway:signal:speed_limit_distant:shortened",
    "railway:signal:speed_limit_distant:speed",
    "railway:signal:speed_limit_distant:mobile",
    "railway:signal:speed_limit_distant:deactivated",
    "railway:signal:speed_limit_distant:distance",
    "railway:signal:station_distant",
    "railway:signal:station_distant:form",
    "railway:signal:station_distant:type",
    "railway:signal:station_distant:deactivated",
    "railway:signal:station_distant:shortened",
    "railway:signal:steam_locomotive",
    "railway:signal:steam_locomotive:form",
    "railway:signal:steam_locomotive:deactivated",
    "railway:signal:stop",
    "railway:signal:stop:form",
    "railway:signal:stop:caption",
    "railway:signal:stop:states",
    "railway:signal:stop:carriages",
    "railway:signal:stop:deactivated",
    "railway:signal:stop_distant",
    "railway:signal:stop_distant:form",
    "railway:signal:stop_distant:distance",
    "railway:signal:stop_distant:deactivated",
    "railway:signal:stop_demand",
    "railway:signal:stop_demand:form",
    "railway:signal:stop_demand:deactivated",
    "railway:signal:switch",
    "railway:signal:switch:form",
    "railway:signal:switch:states",
    "railway:signal:switch:deactivated",
    "railway:signal:train_protection",
    "railway:signal:train_protection:block_marker:type",
    "railway:signal:train_protection:form",
    "railway:signal:train_protection:shape",
    "railway:signal:train_protection:type",
    "railway:signal:train_protection:turn_direction",
    "railway:signal:train_protection:deactivated",
    "railway:signal:train_protection:main",
    "railway:signal:train_protection:main:form",
    "railway:signal:train_protection:system_change",
    "railway:signal:train_protection:system_change:form",
    "railway:signal:traversable",
    "railway:signal:traversable:form",
    "railway:signal:traversable:type",
    "railway:signal:whistle",
    "railway:signal:whistle:form",
    "railway:signal:whistle:only_transit",
    "railway:signal:whistle:deactivated",
    "railway:signal:wrong_road",
    "railway:signal:wrong_road:form",
    "railway:signal:wrong_road:deactivated",
    "railway:vacancy_detection",
    "railway:signal:regime",
    "railway:signal:position",
    "railway:signal:location",
    features[1] as feature0,
    features[2] as feature1,
    features[3] as feature2,
    features[4] as feature3,
    features[5] as feature4,
    features[6] as feature5,
    deactivated[1] as deactivated0,
    deactivated[2] as deactivated1,
    deactivated[3] as deactivated2,
    deactivated[4] as deactivated3,
    deactivated[5] as deactivated4,
    deactivated[6] as deactivated5,
    CEIL(icon_height[1] / 2) as offset0,
    CEIL(icon_height[1] / 2 + icon_height[2] / 2) as offset1,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] / 2) as offset2,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] / 2) as offset3,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] + icon_height[5] / 2) as offset4,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] + icon_height[5] + icon_height[6] / 2) as offset5,
    type
  FROM signals s
  JOIN signal_features sf
    ON s.osm_id = sf.signal_id
  JOIN signal_direction sd
    ON s.osm_id = sd.signal_id
  WHERE layer = 'speed';
  
CREATE OR REPLACE VIEW electrification_signals_view AS
  SELECT
    osm_id as id,
    way,
    osm_id,
    'N' as osm_type,
    rank,
    railway,
    sd.direction_both,
    ref,
    caption,
    position,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description,
    sd.azimuth,
    "railway:signal:brake_test",
    "railway:signal:brake_test:form",
    "railway:signal:brake_test:deactivated",
    "railway:signal:combined",
    "railway:signal:combined:form",
    "railway:signal:combined:states",
    "railway:signal:combined:shape",
    "railway:signal:combined:type",
    "railway:signal:combined:shortened",
    "railway:signal:combined:substitute_signal",
    "railway:signal:combined:height",
    "railway:signal:combined:function",
    "railway:signal:combined:deactivated",
    "railway:signal:crossing",
    "railway:signal:crossing:form",
    "railway:signal:crossing:repeated",
    "railway:signal:crossing:shortened",
    "railway:signal:crossing:deactivated",
    "railway:signal:crossing_distant",
    "railway:signal:crossing_distant:states",
    "railway:signal:crossing_distant:shortened",
    "railway:signal:crossing_distant:form",
    "railway:signal:crossing_distant:deactivated",
    "railway:signal:crossing_hint",
    "railway:signal:crossing_hint:form",
    "railway:signal:crossing_hint:deactivated",
    "railway:signal:crossing_info",
    "railway:signal:crossing_info:form",
    "railway:signal:crossing_info:deactivated",
    "railway:signal:departure",
    "railway:signal:departure:form",
    "railway:signal:departure:states",
    "railway:signal:departure:substitute_signal",
    "railway:signal:departure:deactivated",
    "railway:signal:danger",
    "railway:signal:danger:form",
    "railway:signal:distant",
    "railway:signal:distant:form",
    "railway:signal:distant:repeated",
    "railway:signal:distant:shortened",
    "railway:signal:distant:states",
    "railway:signal:distant:height",
    "railway:signal:distant:type",
    "railway:signal:distant:distance",
    "railway:signal:distant:deactivated",
    "railway:signal:distant:shape",
    "railway:signal:distant:function",
    "railway:signal:electricity",
    "railway:signal:electricity:type",
    "railway:signal:electricity:form",
    "railway:signal:electricity:for",
    "railway:signal:electricity:turn_direction",
    "railway:signal:electricity:voltage",
    "railway:signal:electricity:frequency",
    "railway:signal:electricity:deactivated",
    "railway:signal:fouling_point",
    "railway:signal:fouling_point:form",
    "railway:signal:fouling_point:deactivated",
    "railway:signal:helper_engine",
    "railway:signal:helper_engine:form",
    "railway:signal:helper_engine:deactivated",
    "railway:signal:humping",
    "railway:signal:humping:form",
    "railway:signal:humping:deactivated",
    "railway:signal:main",
    "railway:signal:main:design",
    "railway:signal:main:form",
    "railway:signal:main:height",
    "railway:signal:main:shape",
    "railway:signal:main:lit_letter",
    "railway:signal:main:states",
    "railway:signal:main:substitute_signal",
    "railway:signal:main:PT_priority",
    "railway:signal:main:type",
    "railway:signal:main:function",
    "railway:signal:main:shortened",
    "railway:signal:main:deactivated",
    "railway:signal:main_repeated",
    "railway:signal:main_repeated:form",
    "railway:signal:main_repeated:magnet",
    "railway:signal:main_repeated:states",
    "railway:signal:main_repeated:substitute_signal",
    "railway:signal:main_repeated:shape",
    "railway:signal:main_repeated:deactivated",
    "railway:signal:minor",
    "railway:signal:minor:form",
    "railway:signal:minor:states",
    "railway:signal:minor:height",
    "railway:signal:minor:shape",
    "railway:signal:minor:substitute_signal",
    "railway:signal:minor:function",
    "railway:signal:minor:deactivated",
    "railway:signal:minor_distant",
    "railway:signal:minor_distant:form",
    "railway:signal:minor_distant:states",
    "railway:signal:minor_distant:deactivated",
    "railway:signal:passing",
    "railway:signal:passing:form",
    "railway:signal:passing:type",
    "railway:signal:passing:deactivated",
    "railway:signal:resetting_switch",
    "railway:signal:resetting_switch:form",
    "railway:signal:resetting_switch:states",
    "railway:signal:resetting_switch:deactivated",
    "railway:signal:resetting_switch_distant",
    "railway:signal:resetting_switch_distant:form",
    "railway:signal:resetting_switch_distant:deactivated",
    "railway:signal:preheating",
    "railway:signal:preheating:form",
    "railway:signal:preheating:deactivated",
    "railway:signal:ring",
    "railway:signal:ring:form",
    "railway:signal:ring:only_transit",
    "railway:signal:ring:deactivated",
    "railway:signal:radio",
    "railway:signal:radio:form",
    "railway:signal:radio:frequency",
    "railway:signal:radio:deactivated",
    "railway:signal:route",
    "railway:signal:route:design",
    "railway:signal:route:form",
    "railway:signal:route:states",
    "railway:signal:route:deactivated",
    "railway:signal:route_distant",
    "railway:signal:route_distant:form",
    "railway:signal:route_distant:shape",
    "railway:signal:route_distant:states",
    "railway:signal:route_distant:deactivated",
    "railway:signal:short_route",
    "railway:signal:short_route:form",
    "railway:signal:short_route:shape",
    "railway:signal:short_route:deactivated",
    "railway:signal:shunting",
    "railway:signal:shunting:form",
    "railway:signal:shunting:states",
    "railway:signal:shunting:shape",
    "railway:signal:shunting:height",
    "railway:signal:shunting:deactivated",
    "railway:signal:shunting:repeated",
    "railway:signal:shunting_route",
    "railway:signal:shunting_route:form",
    "railway:signal:shunting_route:states",
    "railway:signal:shunting_route:deactivated",
    "railway:signal:slope",
    "railway:signal:slope:form",
    "railway:signal:slope:type",
    "railway:signal:slope:deactivated",
    "railway:signal:slope:incline",
    "railway:signal:slope:length",
    "railway:signal:slope:shape",
    "railway:signal:slope:distance",
    "railway:signal:snowplow",
    "railway:signal:snowplow:form",
    "railway:signal:snowplow:type",
    "railway:signal:snowplow:deactivated",
    "railway:signal:speed_limit",
    "railway:signal:speed_limit:caption",
    "railway:signal:speed_limit:form",
    "railway:signal:speed_limit:speed",
    "railway:signal:speed_limit:states",
    "railway:signal:speed_limit:pointing",
    "railway:signal:speed_limit:deactivated",
    "railway:signal:speed_limit:turn_direction",
    "railway:signal:speed_limit:type",
    "railway:signal:speed_limit_distant",
    "railway:signal:speed_limit_distant:form",
    "railway:signal:speed_limit_distant:shortened",
    "railway:signal:speed_limit_distant:speed",
    "railway:signal:speed_limit_distant:mobile",
    "railway:signal:speed_limit_distant:deactivated",
    "railway:signal:speed_limit_distant:distance",
    "railway:signal:station_distant",
    "railway:signal:station_distant:form",
    "railway:signal:station_distant:type",
    "railway:signal:station_distant:deactivated",
    "railway:signal:station_distant:shortened",
    "railway:signal:steam_locomotive",
    "railway:signal:steam_locomotive:form",
    "railway:signal:steam_locomotive:deactivated",
    "railway:signal:stop",
    "railway:signal:stop:form",
    "railway:signal:stop:caption",
    "railway:signal:stop:states",
    "railway:signal:stop:carriages",
    "railway:signal:stop:deactivated",
    "railway:signal:stop_distant",
    "railway:signal:stop_distant:form",
    "railway:signal:stop_distant:distance",
    "railway:signal:stop_distant:deactivated",
    "railway:signal:stop_demand",
    "railway:signal:stop_demand:form",
    "railway:signal:stop_demand:deactivated",
    "railway:signal:switch",
    "railway:signal:switch:form",
    "railway:signal:switch:states",
    "railway:signal:switch:deactivated",
    "railway:signal:train_protection",
    "railway:signal:train_protection:block_marker:type",
    "railway:signal:train_protection:form",
    "railway:signal:train_protection:shape",
    "railway:signal:train_protection:type",
    "railway:signal:train_protection:turn_direction",
    "railway:signal:train_protection:deactivated",
    "railway:signal:train_protection:main",
    "railway:signal:train_protection:main:form",
    "railway:signal:train_protection:system_change",
    "railway:signal:train_protection:system_change:form",
    "railway:signal:traversable",
    "railway:signal:traversable:form",
    "railway:signal:traversable:type",
    "railway:signal:whistle",
    "railway:signal:whistle:form",
    "railway:signal:whistle:only_transit",
    "railway:signal:whistle:deactivated",
    "railway:signal:wrong_road",
    "railway:signal:wrong_road:form",
    "railway:signal:wrong_road:deactivated",
    "railway:vacancy_detection",
    "railway:signal:regime",
    "railway:signal:position",
    "railway:signal:location",
    features[1] as feature0,
    features[2] as feature1,
    features[3] as feature2,
    features[4] as feature3,
    features[5] as feature4,
    features[6] as feature5,
    deactivated[1] as deactivated0,
    deactivated[2] as deactivated1,
    deactivated[3] as deactivated2,
    deactivated[4] as deactivated3,
    deactivated[5] as deactivated4,
    deactivated[6] as deactivated5,
    CEIL(icon_height[1] / 2) as offset0,
    CEIL(icon_height[1] / 2 + icon_height[2] / 2) as offset1,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] / 2) as offset2,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] / 2) as offset3,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] + icon_height[5] / 2) as offset4,
    CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] + icon_height[5] + icon_height[6] / 2) as offset5,
    type
  FROM signals s
  JOIN signal_features sf
    ON s.osm_id = sf.signal_id
  JOIN signal_direction sd
    ON s.osm_id = sd.signal_id
  WHERE layer = 'electrification';

--- Speed ---

CREATE OR REPLACE FUNCTION speed_railway_signals(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
  RETURN (
    SELECT
      ST_AsMVT(tile, 'speed_railway_signals', 4096, 'way')
    FROM (
      SELECT
        id,
        ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
        railway,
        ref,
        caption,
        azimuth,
        direction_both,
        feature0,
        feature1,
        deactivated0,
        deactivated1,
        offset0,
        offset1,
        type
      FROM speed_railway_signals_view
      WHERE way && ST_TileEnvelope(z, x, y)
      ORDER BY rank NULLS FIRST
    ) as tile
    WHERE way IS NOT NULL
  );

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION speed_railway_signals IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "speed_railway_signals",
        "fields": {
          "id": "integer",
          "railway": "string",
          "ref": "string",
          "caption": "string",
          "azimuth": "number",
          "direction_both": "boolean",
          "feature0": "string",
          "feature1": "string",
          "deactivated0": "boolean",
          "deactivated1": "boolean",
          "offset0": "number",
          "offset1": "number",
          "type": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Signals ---

CREATE OR REPLACE FUNCTION signals_railway_signals(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
  RETURN (
    SELECT
      ST_AsMVT(tile, 'signals_railway_signals', 4096, 'way')
    FROM (
      SELECT
        id,
        ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
        railway,
        ref,
        caption,
        azimuth,
        direction_both,
        feature0,
        feature1,
        feature2,
        feature3,
        feature4,
        feature5,
        deactivated0,
        deactivated1,
        deactivated2,
        deactivated3,
        deactivated4,
        deactivated5,
        offset0,
        offset1,
        offset2,
        offset3,
        offset4,
        offset5,
        type
      FROM signals_railway_signals_view
      WHERE way && ST_TileEnvelope(z, x, y)
      ORDER BY rank NULLS FIRST
    ) as tile
    WHERE way IS NOT NULL
  );

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION signals_railway_signals IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "signals_railway_signals",
        "fields": {
          "id": "integer",
          "railway": "string",
          "ref": "string",
          "caption": "string",
          "azimuth": "number",
          "direction_both": "boolean",
          "feature0": "string",
          "feature1": "string",
          "feature2": "string",
          "feature3": "string",
          "feature4": "string",
          "feature5": "string",
          "deactivated0": "boolean",
          "deactivated1": "boolean",
          "deactivated2": "boolean",
          "deactivated3": "boolean",
          "deactivated4": "boolean",
          "deactivated5": "boolean",
          "offset0": "number",
          "offset1": "number",
          "offset2": "number",
          "offset3": "number",
          "offset4": "number",
          "offset5": "number",
          "type": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Electrification ---

CREATE OR REPLACE FUNCTION electrification_signals(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
  RETURN (
    SELECT
      ST_AsMVT(tile, 'electrification_signals', 4096, 'way')
    FROM (
      SELECT
        id,
        ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
        railway,
        azimuth,
        direction_both,
        ref,
        caption,
        feature0,
        deactivated0,
        offset0,
        type
      FROM electrification_signals_view
      WHERE way && ST_TileEnvelope(z, x, y)
      ORDER BY rank NULLS FIRST
    ) as tile
    WHERE way IS NOT NULL
  );

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION electrification_signals IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "electrification_signals",
        "fields": {
          "id": "integer",
          "railway": "string",
          "azimuth": "number",
          "direction_both": "boolean",
          "ref": "string",
          "caption": "string",
          "feature": "string",
          "deactivated": "boolean",
          "offset": "number",
          "type": "stirng"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

