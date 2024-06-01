-- SPDX-License-Identifier: GPL-2.0-or-later
-- Flush data updates to the materialized views.

REFRESH MATERIALIZED VIEW openrailwaymap_ref;
REFRESH MATERIALIZED VIEW openrailwaymap_facilities_for_search;
