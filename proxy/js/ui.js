const searchBackdrop = document.getElementById('search-backdrop');
const searchFacilitiesTab = document.getElementById('search-facilities-tab');
const searchMilestonesTab = document.getElementById('search-milestones-tab');
const searchFacilitiesForm = document.getElementById('search-facilities-form');
const searchMilestonesForm = document.getElementById('search-milestones-form');
const searchFacilityTermField = document.getElementById('facility-term');
const searchMilestoneRefField = document.getElementById('milestone-ref');
const searchResults = document.getElementById('search-results');
const configurationBackdrop = document.getElementById('configuration-backdrop');
const backgroundSaturationControl = document.getElementById('backgroundSaturation');
const backgroundOpacityControl = document.getElementById('backgroundOpacity');
const backgroundRasterUrlControl = document.getElementById('backgroundRasterUrl');
const legend = document.getElementById('legend')
const legendMapContainer = document.getElementById('legend-map')

const icons = {
  railway: {
    station: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5120 5120"><path d="M1215 4784c-46-24-63-43-81-90-13-34-14-52-7-81 6-21 113-204 237-408 125-203 228-374 229-378 1-5-29-18-68-31-219-71-376-206-475-411-89-184-85-115-85-1310 0-1138-2-1097 56-1243 98-248 318-434 584-494 88-19 1822-19 1910 0 309 70 537 293 621 607 18 66 19 126 19 1125 0 1200 4 1131-85 1315-56 116-134 213-223 281-70 53-201 119-274 138-26 7-47 17-46 22s105 178 231 384c134 219 233 391 237 412 5 26 1 49-13 80-45 104-170 129-245 50-15-16-60-82-100-148l-73-119H1556l-73 119c-83 136-105 163-150 182-42 18-81 18-118-2zm2145-629c0-2-42-73-93-157l-94-153H1948l-94 153c-52 84-94 155-94 157 0 3 360 5 800 5s800-2 800-5zm-1512-975c48-30 72-75 72-140 0-100-60-160-160-160s-160 60-160 159c0 63 26 113 74 142 43 26 130 26 174-1zm1600 0c48-30 72-75 72-140 0-100-60-160-160-160s-160 60-160 160 60 160 160 160c37 0 66-6 88-20zm28-797c34-11 67-35 110-77 98-98 94-69 94-706s4-608-94-706c-102-101-26-95-1042-92l-879 3-47 23c-60 30-120 90-150 150l-23 47-3 559c-3 654-7 623 92 722 100 99 23 92 1022 93 788 1 875-1 920-16z"/></svg>',
    halt: '<svg xmlns="http://www.w3.org/2000/svg"  width="auto" height="16" viewBox="0 0 5120 5120"><g><path d="M1835 5111c-76-19-115-67-115-141 0-55 27-102 72-127 29-16 66-18 326-21l292-3V3202l-417-5c-453-5-465-6-582-64-81-40-200-161-238-243-60-129-58-76-58-1290s-2-1161 58-1290c41-89 158-206 247-247 128-60 89-58 1140-58s1012-2 1140 58c89 41 206 158 247 247 60 129 58 76 58 1290s2 1161-58 1290c-39 83-157 205-238 244-119 57-130 58-581 63l-418 5v1617l293 3c259 3 296 5 325 21 96 53 96 201 0 254-31 17-80 18-748 20-393 1-728-2-745-6zm333-2554 37-37 3-110 4-110h696l4 110 3 110 38 37c36 37 40 38 107 38s71-1 107-38l38-37 3-109 4-109 59-4c53-4 64-9 97-41l37-37V845l-27-52c-40-76-79-115-150-154l-63-34H1955l-63 34c-71 39-110 78-150 154l-27 52v1375l37 37c33 32 44 37 97 41l59 4 4 109c3 104 4 109 33 139 41 43 60 50 128 47 52-3 62-7 95-40z"/><path d="M2010 1850v-150h1100v300H2010v-150zM2012 1165c2-175 6-237 16-247 19-19 1045-19 1064 0 10 10 14 72 16 247l3 235H2009l3-235z"/></g></svg>',
    tram_stop: '<svg xmlns="http://www.w3.org/2000/svg"  width="auto" height="16" viewBox="0 0 5120 5120"><g><path d="M1835 5111c-76-19-115-67-115-141 0-55 27-102 72-127 29-16 66-18 326-21l292-3V3202l-417-5c-453-5-465-6-582-64-81-40-200-161-238-243-60-129-58-76-58-1290s-2-1161 58-1290c41-89 158-206 247-247 128-60 89-58 1140-58s1012-2 1140 58c89 41 206 158 247 247 60 129 58 76 58 1290s2 1161-58 1290c-39 83-157 205-238 244-119 57-130 58-581 63l-418 5v1617l293 3c259 3 296 5 325 21 96 53 96 201 0 254-31 17-80 18-748 20-393 1-728-2-745-6zm333-2554 37-37 3-110 4-110h696l4 110 3 110 38 37c36 37 40 38 107 38s71-1 107-38l38-37 3-109 4-109 59-4c53-4 64-9 97-41l37-37V845l-27-52c-40-76-79-115-150-154l-63-34H1955l-63 34c-71 39-110 78-150 154l-27 52v1375l37 37c33 32 44 37 97 41l59 4 4 109c3 104 4 109 33 139 41 43 60 50 128 47 52-3 62-7 95-40z"/><path d="M2010 1850v-150h1100v300H2010v-150zM2012 1165c2-175 6-237 16-247 19-19 1045-19 1064 0 10 10 14 72 16 247l3 235H2009l3-235z"/></g></svg>',
    service_station: '<svg width="auto" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6.12 20.75c-.76 0-1.48-.3-2.03-.84a2.86 2.86 0 0 1 0-4.05l5.51-5.51c-.5-1.94.04-4.03 1.46-5.45a5.667 5.667 0 0 1 5.48-1.46c.26.07.46.27.53.53s0 .53-.19.72l-2.45 2.45.52 1.91 1.91.52 2.45-2.45c.19-.19.47-.26.72-.19.26.07.46.27.53.53.53 1.95-.02 4.05-1.46 5.48-1.42 1.42-3.51 1.96-5.45 1.46l-5.51 5.51c-.54.54-1.26.84-2.02.84Zm8.56-15.98c-.96.08-1.87.5-2.57 1.2-1.14 1.14-1.51 2.81-.96 4.35.1.27.03.58-.18.78l-5.83 5.83c-.53.53-.53 1.4 0 1.93.26.26.6.4.97.4.36 0 .71-.14.96-.4l5.83-5.83c.21-.21.51-.27.78-.18 1.54.54 3.21.18 4.35-.96.7-.7 1.11-1.61 1.2-2.57l-1.63 1.63c-.19.19-.47.26-.73.19l-2.74-.75a.747.747 0 0 1-.53-.53l-.75-2.74c-.07-.26 0-.54.19-.73l1.63-1.63.01.01Z" fill="#000"/></svg>',
    yard: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5120 5120"><g><path d="M770 5109c-99-12-177-51-258-131-99-98-148-249-124-379 52-281 335-446 597-348 31 11 75 36 99 54l44 33 47-34c211-150 507-85 639 140 187 315-73 706-442 664-67-7-155-43-209-84l-33-25-33 25c-86 65-212 98-327 85zm138-309c44-27 72-76 72-127 0-53-11-81-45-115-108-108-296 1-256 149 11 42 51 89 86 104 38 15 109 10 143-11zm602-2c18-13 42-35 53-49 26-36 27-115 1-160-21-37-92-79-133-79-40 0-109 39-131 74-27 44-27 120 0 164 44 71 143 95 210 50zM3626 5108c-133-17-274-120-335-242-46-93-58-191-37-288 70-315 431-459 691-274l47 34 44-33c166-127 416-104 571 51 100 100 148 248 124 383-39 219-219 372-437 372-107 0-190-27-271-88l-33-24-33 25c-87 67-214 99-331 84zm142-308c95-58 98-207 4-262-51-30-101-32-152-6-56 29-84 75-84 140 0 113 134 188 232 128zm614-5c94-70 82-210-22-263-103-53-210 10-218 128-4 64 18 108 70 141 42 26 131 23 170-6z"/><path d="M2130 4653c-26-10-61-47-79-83-10-19-58-142-106-272l-88-238H453l-6 66c-5 70-21 101-70 138-38 28-113 27-155-3-60-42-62-53-62-348 0-251 1-270 20-301 26-43 97-75 144-67 77 15 126 85 126 183v42h160v-852c0-838 0-854 20-886 12-19 38-41 63-52 41-19 89-20 1867-20s1826 1 1867 20c25 11 51 33 63 52 20 32 20 48 20 886v852h160v-42c0-98 48-168 124-182 50-9 119 22 146 66 19 31 20 50 20 301 0 295-2 306-62 348-42 30-117 31-155 3-49-37-65-68-70-138l-6-66H3263l-88 238c-101 270-113 297-150 332l-27 25-426 2c-235 1-434-1-442-4zm760-425c29-79 55-149 57-155 4-10-77-13-387-13s-391 3-387 13c2 6 28 76 57 155l53 142h554l53-142zm-1390-780c26-14 53-37 65-58 19-34 20-52 20-455 0-414 0-420-22-455-35-56-81-76-167-72-19 2-43 16-72 46l-44 43v433c0 426 0 433 22 468 22 36 85 71 128 72 14 0 46-10 70-22zm768-5c14-11 35-32 46-47 20-27 21-39 21-459v-432l-23-33c-64-89-197-85-259 8-23 33-23 34-23 452 0 449 0 447 52 495 12 12 34 27 48 32 35 15 108 7 138-16zm751 0c14-11 36-35 49-53 22-33 22-34 22-455s0-422-23-455c-62-93-195-97-259-8l-23 33-3 405c-2 223 0 419 3 437 7 40 49 91 90 109 39 18 110 12 144-13zm738 7c25-11 51-33 63-52 19-32 20-49 20-467v-434l-44-43c-29-30-53-44-72-46-86-4-132 16-167 72-22 35-22 41-22 455 0 403 1 421 20 455 22 38 93 80 135 80 14 0 44-9 67-20zM85 1331c-43-26-66-55-74-93-11-51 4-99 41-133C98 1063 2510 7 2560 7c25 0 402 161 1255 534 1368 598 1295 560 1295 662 0 45-5 61-26 87-33 38-74 60-114 60-20 0-485-198-1221-520L2560 309 1371 830c-789 345-1201 520-1223 520-18 0-46-8-63-19z"/></g></svg>',
    junction: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 24 24"><path d="m2 2 1.313 8.313 2.343-2.344 2.157 2.125c.6.6 1.074 1.206 1.375 1.906.4-1.2.925-2.406 1.624-3.406-.2-.3-.518-.582-.718-.781L7.969 5.655l2.343-2.343L2 2zm20 0-8.313 1.313 2.063 2.062L14.156 7l-.469.5C11.335 9.854 10 12.989 10 16.313V22h4v-5.688c0-2.276.854-4.353 2.5-6l2.094-2.093 2.093 2.094L22 2z"/></svg>',
    spur_junction: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5.292 5.292"><path style="stroke-width:.264583" d="m99.982 123.214-2.2.347.546.546-.421.43-.125.132a3.29 3.29 0 0 0-.975 2.332v1.504h1.058V127c0-.602.226-1.151.662-1.587l.554-.554.554.554z" transform="translate(-94.69 -123.214)"/><path style="stroke-width:.203772" d="m95.109 123.822.267 1.694.478-.478.44.433c.122.122.218.246.28.389a2.73 2.73 0 0 1 .33-.695c-.04-.06-.105-.118-.146-.159l-.433-.44.478-.477z" transform="translate(-94.69 -123.214)"/></svg>',
    crossover: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 24 24"><path d="M5 19 19 5m0 0v4m0-4h-4M5 5l3.5 3.5.875.875M19 19h-4m4 0v-4m0 4-3.5-3.5-.875-.875" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    site: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5120 5120"><path d="M2494 5100c-31-12-74-58-229-245-546-658-976-1305-1243-1872-269-570-355-995-288-1413 97-592 462-1092 996-1364C2119 8 2576-44 3005 61c650 159 1180 687 1345 1339 123 486 51 941-252 1583-267 567-697 1214-1243 1872-160 192-198 233-232 246-30 11-101 11-129-1zm319-2344c339-100 590-368 663-704 20-93 23-280 5-372-74-381-387-689-764-750-80-13-234-13-314 0-377 61-690 369-764 750-18 92-15 279 5 372 71 328 321 600 643 698 112 34 158 39 303 35 109-2 152-8 223-29z"/></svg>',
    milestone: '<svg s="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5120 5120"><g><path d="M923 4680c-12-5-26-18-32-29-7-13-11-151-11-404v-384l26-24c24-22 34-24 154-27l129-4 4-1086c3-1056 4-1090 24-1182 28-129 66-238 118-342 313-630 1043-923 1695-681 402 149 721 487 839 891 57 195 55 146 59 1319l3 1081 129 4c120 3 130 5 154 27l26 24v388c0 366-1 388-19 410l-19 24-1629 2c-926 1-1637-2-1650-7zm3157-425v-275H1040v550h3040v-275zm-310-1437c0-546-5-1045-10-1108-25-301-141-554-349-761-237-237-517-353-851-353-332 0-618 119-851 353-210 211-324 460-349 761-5 63-10 562-10 1108v992h2420v-992z"/><path d="M1713 3275c-16-7-33-20-37-30-3-9-6-191-6-405 0-364 1-389 19-411 25-31 83-32 114-1 19 20 22 35 25 127 2 58 6 105 9 105s73-56 155-125c83-69 161-128 174-131 48-12 103 48 90 99-4 17-69 78-188 177-101 84-184 157-185 164-1 6 74 74 168 151s179 151 190 164c46 57-1 128-81 122-9 0-85-59-170-130l-155-129-5 102c-3 55-11 111-17 122-18 32-63 45-100 29zM2640 3282c-8-2-25-14-37-25l-23-20v-394c0-378 1-394 20-413 29-29 66-35 94-16 14 8 82 101 153 205 70 105 133 190 138 190 6 0 68-85 138-190 71-104 139-197 153-205 28-19 65-13 94 16 19 19 20 35 20 413v394l-25 23c-31 29-80 29-109 0-20-19-21-34-26-263l-5-242-79 115c-102 150-122 170-161 170-17 0-38-6-47-12-9-7-56-71-104-143l-89-130-5 241c-4 178-8 245-18 257-16 19-62 36-82 29zM2330 2003c-61-22-79-92-34-134 24-23 32-24 184-27l159-3 26-30c35-42 33-89-4-131l-29-33-159-3c-144-3-160-6-180-25-13-11-23-32-23-48 0-77 29-89 215-89h147l29-29c33-33 38-75 15-120-23-44-53-51-212-51-141 0-146-1-169-25-33-32-33-78 0-110 23-24 28-25 179-25 132 0 164 3 210 20 149 56 212 244 128 380-25 39-28 51-17 60 7 6 23 34 35 62 32 74 26 167-16 234-36 59-106 108-174 123-52 11-283 14-310 4z"/></g></svg>',
    level_crossing: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5120 5120"><g><path d="M2270 3875V2630l145-72 145-73 145 73 145 72v2490h-580V3875z"/><path d="M405 3034c-110-42-202-77-203-79-3-3 23-99 104-381l15-52 749-378c412-208 746-382 742-386-4-3-338-174-742-378s-739-375-743-380c-15-14-129-422-120-431 4-4 99-41 209-83l202-75 971 490 971 490 972-490 971-490 201 75c111 42 205 79 209 83 9 8-105 417-120 431-4 5-339 176-743 380s-738 375-742 378c-4 4 330 178 742 386l749 378 16 56c9 31 37 128 62 215s44 160 41 162c-2 3-97 39-210 81l-206 76-971-488-971-489-969 488c-533 268-972 487-977 487-5-1-99-35-209-76z"/><path d="m2413 967-143-72V0h580v895l-144 73c-79 39-145 72-147 71-2 0-68-32-146-72z"/></g></svg>',
    crossing: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5120 5120"><g><path d="M2270 3875V2630l145-72 145-73 145 73 145 72v2490h-580V3875z"/><path d="M405 3034c-110-42-202-77-203-79-3-3 23-99 104-381l15-52 749-378c412-208 746-382 742-386-4-3-338-174-742-378s-739-375-743-380c-15-14-129-422-120-431 4-4 99-41 209-83l202-75 971 490 971 490 972-490 971-490 201 75c111 42 205 79 209 83 9 8-105 417-120 431-4 5-339 176-743 380s-738 375-742 378c-4 4 330 178 742 386l749 378 16 56c9 31 37 128 62 215s44 160 41 162c-2 3-97 39-210 81l-206 76-971-488-971-489-969 488c-533 268-972 487-977 487-5-1-99-35-209-76z"/><path d="m2413 967-143-72V0h580v895l-144 73c-79 39-145 72-147 71-2 0-68-32-146-72z"/></g></svg>',
  },
  edit: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" fill="#007bff" viewBox="0 0 24 24"><path d="M7.127 22.562l-7.127 1.438 1.438-7.128 5.689 5.69zm1.414-1.414l11.228-11.225-5.69-5.692-11.227 11.227 5.689 5.69zm9.768-21.148l-2.816 2.817 5.691 5.691 2.816-2.819-5.691-5.689z"/></svg>',
}

function registerLastSearchResults(results) {
  const data = {
    type: 'FeatureCollection',
    features: results.map(result => ({
      type: 'Feature',
      properties: result,
      geometry: {
        type: 'Point',
        coordinates: [result.latitude, result.longitude],
      },
    })),
  };
  map.getSource('search').setData(data);
}

function facilitySearchQuery(type, term) {
  const encoded = encodeURIComponent(term)

  switch (type) {
    case 'name':
      return `name=${encoded}`;
    case 'ref':
      return `ref=${encoded}`;
    case 'uic_ref':
      return `uic_ref=${encoded}`;
    case 'all':
    default:
      return `q=${encoded}`;
  }
}

function searchForFacilities(type, term) {
  if (!term || term.length < 2) {
    hideSearchResults();
  } else {
    const queryString = facilitySearchQuery(type, term)
    fetch(`${location.origin}/api/facility?${queryString}`)
      .then(result => result.json())
      .then(result => result.map(item => ({
        ...item,
        label: item.name,
        icon: icons.railway[item.railway] ?? null,
      })))
      .then(result => {
        console.info('facility search result', result)
        showSearchResults(result)
      })
      .catch(error => {
        hideSearchResults();
        hideSearch();
        console.error(error);
      });
  }
}

function searchForMilestones(ref, position) {
  if (!ref || !position) {
    hideSearchResults();
  } else {
    fetch(`${location.origin}/api/milestone?ref=${encodeURIComponent(ref)}&position=${encodeURIComponent(position)}`)
      .then(result => result.json())
      .then(result => result.map(item => ({
        ...item,
        label: `Line ${item.ref} @ ${item.position}`,
        icon: icons.railway[item.railway] ?? null,
      })))
      .then(result => {
        console.info('milestone search result', result)
        showSearchResults(result)
      })
      .catch(error => {
        hideSearchResults();
        hideSearch();
        console.error(error);
      });
  }
}

function showSearchResults(results) {
  registerLastSearchResults(results);

  const bounds = results.length > 0
    ? JSON.stringify(results.reduce(
      (bounds, result) =>
        bounds.extend({lat: result.longitude, lon: result.latitude}),
      new maplibregl.LngLatBounds({lat: results[0].longitude, lon: results[0].latitude})
    ).toArray())
    : null;

  searchResults.innerHTML = results.length === 0
    ? `
      <div class="mb-1 d-flex align-items-center">
        <span class="flex-grow-1">
          <span class="badge badge-light">0 results</span>
        </span>
      </div>
    `
    : `
      <div class="mb-1 d-flex align-items-center">
        <span class="flex-grow-1">
          <span class="badge badge-light">${results.length} results</span>
        </span>
        <button class="btn btn-sm btn-primary" type="button" style="vertical-align: text-bottom" onclick="viewSearchResultsOnMap(${bounds})">
          <svg width="auto" height="16" viewBox="-4 0 36 36" xmlns="http://www.w3.org/2000/svg"><g fill="none" fill-rule="evenodd"><path d="M14 0c7.732 0 14 5.641 14 12.6C28 23.963 14 36 14 36S0 24.064 0 12.6C0 5.641 6.268 0 14 0Z" fill="white"/><circle fill="var(--primary)" fill-rule="nonzero" cx="14" cy="14" r="7"/></g></svg>
          Show on map
        </button>
      </div>
      <div class="list-group">
        ${results.map(result =>
          `<a class="list-group-item list-group-item-action" href="javascript:hideSearchResults(); map.easeTo({center: [${result.latitude}, ${result.longitude}], zoom: 15}); hideSearch()">
            ${result.icon ? `${result.icon}` : ''}
            ${result.label}
          </a>`
        ).join('')}
      </div>
    `;
  searchResults.style.display = 'block';
}

function hideSearchResults() {
  searchResults.style.display = 'none';
  registerLastSearchResults([]);
}

function showSearch() {
  searchBackdrop.style.display = 'block';
  if (searchFacilitiesForm.style.display !== 'none') {
    searchFacilityTermField.focus();
    searchFacilityTermField.select();
  } else if (searchMilestonesForm.style.display !== 'none') {
    searchMilestoneRefField.focus();
    searchMilestoneRefField.select();
  }
}

function hideSearch() {
  searchBackdrop.style.display = 'none';
}

function searchFacilities() {
  searchFacilitiesTab.classList.add('active')
  searchMilestonesTab.classList.remove('active')
  searchFacilitiesForm.style.display = 'block';
  searchMilestonesForm.style.display = 'none';
  searchFacilityTermField.focus();
  searchFacilityTermField.select();
  hideSearchResults();
}

function searchMilestones() {
  searchFacilitiesTab.classList.remove('active')
  searchMilestonesTab.classList.add('active')
  searchFacilitiesForm.style.display = 'none';
  searchMilestonesForm.style.display = 'block';
  searchMilestoneRefField.focus();
  searchMilestoneRefField.select();
  hideSearchResults();
}

function viewSearchResultsOnMap(bounds) {
  hideSearch();
  map.fitBounds(bounds, {
    padding: 40,
  });
}

function showConfiguration() {
  backgroundSaturationControl.value = configuration.backgroundSaturation ?? defaultConfiguration.backgroundSaturation;
  backgroundOpacityControl.value = configuration.backgroundOpacity ?? defaultConfiguration.backgroundOpacity;
  backgroundRasterUrlControl.value = configuration.backgroundRasterUrl ?? defaultConfiguration.backgroundRasterUrl;
  configurationBackdrop.style.display = 'block';
}

function hideConfiguration() {
  configurationBackdrop.style.display = 'none';
}

function toggleLegend() {
  if (legend.style.display === 'block') {
    legend.style.display = 'none';
  } else {
    legend.style.display = 'block';
  }
}

searchFacilitiesForm.addEventListener('submit', event => {
  event.preventDefault();
  const formData = new FormData(event.target);
  const data = Object.fromEntries(formData);
  searchForFacilities(data.type, data.term)
})
searchMilestonesForm.addEventListener('submit', event => {
  event.preventDefault();
  const formData = new FormData(event.target);
  const data = Object.fromEntries(formData);
  searchForMilestones(data.ref, data.position)
})
searchBackdrop.onclick = event => {
  if (event.target === event.currentTarget) {
    hideSearch();
  }
};
configurationBackdrop.onclick = event => {
  if (event.target === event.currentTarget) {
    hideConfiguration();
  }
};

function createDomElement(tagName, className, container) {
  const el = window.document.createElement(tagName);
  if (className !== undefined) el.className = className;
  if (container) container.appendChild(el);
  return el;
}

function removeDomElement(node) {
  if (node.parentNode) {
    node.parentNode.removeChild(node);
  }
}

const globalMinZoom = 1;
const globalMaxZoom = 18;
const globalMaxBounds = [[-10.0, 35.7], [39.0, 70.0]];

const knownStyles = {
  standard: 'Infrastructure',
  speed: 'Speed',
  signals: 'Train protection',
  electrification: 'Electrification',
  gauge: 'Gauge',
};

function hashToObject(hash) {
  if (!hash) {
    return {};
  } else {
    const strippedHash = hash.replace('#', '');
    const hashEntries = strippedHash
      .split('&')
      .map(item => item.split('=', 2))
    return Object.fromEntries(hashEntries);
  }
}

function determineStyleFromHash(hash) {
  const defaultStyle = Object.keys(knownStyles)[0];
  const hashObject = hashToObject(hash);
  if (hashObject.style && hashObject.style in knownStyles) {
    return hashObject.style
  } else {
    return defaultStyle;
  }
}

function putStyleInHash(hash, style) {
  const hashObject = hashToObject(hash);
  hashObject.style = style;
  return `#${Object.entries(hashObject).map(([key, value]) => `${key}=${value}`).join('&')}`;
}

let selectedStyle = determineStyleFromHash(window.location.hash)

// Configuration //

const localStorageKey = 'openrailwaymap-configuration';

function readConfiguration(localStorage) {
  const rawConfiguration = localStorage.getItem(localStorageKey);
  if (rawConfiguration) {
    try {
      const parsedConfiguration = JSON.parse(rawConfiguration);
      console.info('Found local configuration', parsedConfiguration);
      return parsedConfiguration;
    } catch (exception) {
      console.error('Error parsing local storage value. Deleting from local storage. Value:', rawConfiguration, 'Error:', exception)
      localStorage.removeItem(localStorageKey)
      return {};
    }
  } else {
    return {};
  }
}

function storeConfiguration(localStorage, configuration) {
  localStorage.setItem(localStorageKey, JSON.stringify(configuration));
}

function updateConfiguration(name, value) {
  configuration[name] = value;
  storeConfiguration(localStorage, configuration)
  onStyleChange(selectedStyle);
}

const defaultConfiguration = {
  backgroundSaturation: -1.0,
  backgroundOpacity: 1.0,
  backgroundRasterUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
}
let configuration = readConfiguration(localStorage);

const coordinateFactor = legendZoom => Math.pow(2, 5 - legendZoom);

const legendPointToMapPoint = (zoom, [x, y]) =>
  [x * coordinateFactor(zoom), y * coordinateFactor(zoom)]

const mapStyles = Object.fromEntries(
  Object.keys(knownStyles)
    .map(style => [style, `${location.origin}/style/${style}.json`])
);

const legendStyles = Object.fromEntries(
  Object.keys(knownStyles)
    .map(style => [style, `${location.origin}/style/legend-${style}.json`])
);

const transformMapStyle = (style, configuration) => {
  const backgroundMapLayer = style.layers.find(it => it.id === 'background-map');
  backgroundMapLayer.paint['raster-saturation'] = configuration.backgroundSaturation ?? defaultConfiguration.backgroundSaturation;
  backgroundMapLayer.paint['raster-opacity'] = configuration.backgroundOpacity ?? defaultConfiguration.backgroundOpacity;

  const backgroundMapSource = style.sources.background_map;
  backgroundMapSource.tiles = [configuration.backgroundRasterUrl ?? defaultConfiguration.backgroundRasterUrl];

  return style;
}

const legendMap = new maplibregl.Map({
  container: 'legend-map',
  zoom: 5,
  center: [0, 0],
  attributionControl: false,
  interactive: false,
  // See https://github.com/maplibre/maplibre-gl-js/issues/3503
  maxCanvasSize: [Infinity, Infinity],
});

const map = new maplibregl.Map({
  container: 'map',
  hash: 'view',
  minZoom: globalMinZoom,
  maxZoom: globalMaxZoom,
  minPitch: 0,
  maxPitch: 0,
  maxBounds: globalMaxBounds,
});

const onStyleChange = changedStyle => {
  selectedStyle = changedStyle;

  // Change styles
  map.setStyle(mapStyles[changedStyle], {
    validate: false,
    transformStyle: (previous, next) => {
      return transformMapStyle(next, configuration);
    },
  });
  legendMap.setStyle(legendStyles[changedStyle], {
    validate: false,
    transformStyle: (previous, next) => {
      onStylesheetChange(next);
      return next;
    },
  });

  // Update URL
  const updatedHash = putStyleInHash(window.location.hash, changedStyle);
  const location = window.location.href.replace(/(#.+)?$/, updatedHash);
  window.history.replaceState(window.history.state, null, location);
}

onStyleChange(selectedStyle);

class StyleControl {
  constructor(options) {
    this.options = options
  }

  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group maplibregl-ctrl-style');
    const buttonGroup = createDomElement('div', 'btn-group-vertical btn-group-toggle', this._container);

    Object.entries(knownStyles).forEach(([name, styleLabel]) => {
      const id = `style-${name}`
      const label = createDomElement('label', 'btn btn-light', buttonGroup);
      label.htmlFor = id
      label.innerText = styleLabel
      const radio = createDomElement('input', '', label);
      radio.id = id
      radio.type = 'radio'
      radio.name = 'style'
      radio.value = name
      radio.onclick = () => this.options.onStyleChange(name)
      radio.checked = (this.options.initialSelection === name)
    });

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }
}

class SearchControl {
  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group');
    const button = createDomElement('button', 'maplibregl-ctrl-search', this._container);
    button.type = 'button';
    button.title = 'Search for places'
    button.onclick = _ => showSearch();
    const icon = createDomElement('span', 'maplibregl-ctrl-icon', button);
    const text = createDomElement('span', '', icon);
    text.innerText = 'Search'

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }
}

class EditControl {
  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group');
    const button = createDomElement('button', 'maplibregl-ctrl-edit', this._container);
    button.type = 'button';
    button.title = 'Edit map data'
    button.onclick = _ => window.open(`https://www.openstreetmap.org/edit#map=${Math.round(this._map.getZoom()) + 1}/${this._map.getCenter().lat}/${this._map.getCenter().lng}`, '_blank');
    createDomElement('span', 'maplibregl-ctrl-icon', button);

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }
}

class ConfigurationControl {
  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group');
    const button = createDomElement('button', 'maplibregl-ctrl-configuration', this._container);
    button.type = 'button';
    button.title = 'Configure the map'
    button.onclick = _ => showConfiguration();
    createDomElement('span', 'maplibregl-ctrl-icon', button);

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }
}

class LegendControl {
  constructor(options) {
    this.options = options;
  }

  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group');
    const button = createDomElement('button', 'maplibregl-ctrl-legend', this._container);
    button.type = 'button';
    button.title = 'Show/hide map legend';
    const icon = createDomElement('span', 'maplibregl-ctrl-icon', button);
    const text = createDomElement('span', '', icon);
    text.innerText = 'Legend'

    button.onclick = () => this.options.onLegendToggle()

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }
}

// Cache for the number of items in the legend, per style and zoom level
const legendEntriesCount = Object.fromEntries(Object.keys(knownStyles).map(key => [key, {}]));

map.addControl(new StyleControl({
  initialSelection: selectedStyle,
  onStyleChange,
}));
map.addControl(new maplibregl.NavigationControl({
  showCompass: true,
  visualizePitch: false,
}));
map.addControl(
  new maplibregl.GeolocateControl({
    positionOptions: {
      enableHighAccuracy: true
    },
    trackUserLocation: true,
    showAccuracyCircle: false,
    showUserLocation: true,
  })
);
map.addControl(new maplibregl.FullscreenControl());
map.addControl(new EditControl());
map.addControl(new ConfigurationControl());

map.addControl(new SearchControl(), 'top-left');

map.addControl(new maplibregl.ScaleControl({
  maxWidth: 150,
  unit: 'metric',
}), 'bottom-right');

map.addControl(new LegendControl({
  onLegendToggle: toggleLegend,
}), 'bottom-left');

const onMapZoom = zoom => {
  const legendZoom = Math.floor(zoom);
  const numberOfLegendEntries = legendEntriesCount[selectedStyle][legendZoom] ?? 100;

  legendMap.jumpTo({
    zoom: legendZoom,
    center: legendPointToMapPoint(legendZoom, [1, -((numberOfLegendEntries - 2) / 2) * 0.6]),
  });
  legendMapContainer.style.height = `${numberOfLegendEntries * 30}px`;
}

const onStylesheetChange = styleSheet => {
  const styleName = styleSheet.metadata.name;
  styleSheet.layers.forEach(layer => {
    if (layer.metadata && layer.metadata['legend:zoom'] && layer.metadata['legend:count']) {
      legendEntriesCount[styleName][layer.metadata['legend:zoom']] = layer.metadata['legend:count']
    }
  })
  onMapZoom(map.getZoom());
}

map.on('load', () => onMapZoom(map.getZoom()));
map.on('zoomend', () => onMapZoom(map.getZoom()));

// When a click event occurs on a feature in the places layer, open a popup at the
// location of the feature, with description HTML from its properties.
map.on('click', 'search', (e) => {
  const feature = e.features[0];
  const coordinates = feature.geometry.coordinates.slice();
  const properties = feature.properties;
  const content = `
    <h6>
      ${properties.icon ? `<span title="${properties.railway}">${properties.icon}</span>` : ''}
      <a title="View" href="https://www.openstreetmap.org/node/${properties.osm_id}" target="_blank">${properties.label}</a> 
      <a title="Edit" href="https://www.openstreetmap.org/edit?node=${properties.osm_id}" target="_blank">${icons.edit}</a>
    </h6>
    <h6>
      ${properties.railway_ref ? `<span class="badge badge-pill badge-light">reference: <span class="text-monospace">${properties.railway_ref}</span></span>` : ''} 
      ${properties.ref ? `<span class="badge badge-pill badge-light">reference: <span class="text-monospace">${properties.ref}</span></span>` : ''} 
      ${properties.uic_ref ? `<span class="badge badge-pill badge-light">UIC reference: <span class="text-monospace">${properties.uic_ref}</span></span>` : ''}
      ${properties.position ? `<span class="badge badge-pill badge-light">position: ${properties.position}</span>` : ''}
      ${properties.operator ? `<span class="badge badge-pill badge-light">operator: ${properties.operator}</span>` : ''}
    </h6>
  `;

  new maplibregl.Popup()
    .setLngLat(coordinates)
    .setHTML(content)
    .addTo(map);
});

// Change the cursor to a pointer when the mouse is over the places layer.
map.on('mouseenter', 'search', () => {
  map.getCanvas().style.cursor = 'pointer';
});

// Change it back to a pointer when it leaves.
map.on('mouseleave', 'search', () => {
  map.getCanvas().style.cursor = '';
});
