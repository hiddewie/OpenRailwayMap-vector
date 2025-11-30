// Add support for right-to-left languages like Arabic and Hebrew
maplibregl.setRTLTextPlugin(`${location.origin}/js/mapbox-gl/mapbox-gl-rtl-text.js`, null, true);

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
const backgroundTypeRasterControl = document.getElementById('backgroundTypeRaster');
const backgroundTypeVectorControl = document.getElementById('backgroundTypeVector');
const backgroundUrlControl = document.getElementById('backgroundUrl');
const backgroundHillShadeDisabledControl = document.getElementById('backgroundHillShadeDisabled');
const backgroundHillShadeEnabledControl = document.getElementById('backgroundHillShadeEnabled');
const stationLabelNameControl = document.getElementById('stationLabelName');
const stationLabelReferenceControl = document.getElementById('stationLabelReference');
const themeSystemControl = document.getElementById('themeSystem');
const themeDarkControl = document.getElementById('themeDark');
const themeLightControl = document.getElementById('themeLight');
const editorIDControl =  document.getElementById('editorID');
const editorJOSMControl =  document.getElementById('editorJOSM');
const backgroundMapContainer = document.getElementById('background-map');
const legend = document.getElementById('legend');
const legendMapContainer = document.getElementById('legend-map');
const newsBackdrop = document.getElementById('news-backdrop');
const newsContent = document.getElementById('news-content');
const aboutBackdrop = document.getElementById('about-backdrop');

const MD5 = function(d){var r = M(V(Y(X(d),8*d.length)));return r.toLowerCase()};function M(d){for(var _,m="0123456789ABCDEF",f="",r=0;r<d.length;r++)_=d.charCodeAt(r),f+=m.charAt(_>>>4&15)+m.charAt(15&_);return f}function X(d){for(var _=Array(d.length>>2),m=0;m<_.length;m++)_[m]=0;for(m=0;m<8*d.length;m+=8)_[m>>5]|=(255&d.charCodeAt(m/8))<<m%32;return _}function V(d){for(var _="",m=0;m<32*d.length;m+=8)_+=String.fromCharCode(d[m>>5]>>>m%32&255);return _}function Y(d,_){d[_>>5]|=128<<_%32,d[14+(_+64>>>9<<4)]=_;for(var m=1732584193,f=-271733879,r=-1732584194,i=271733878,n=0;n<d.length;n+=16){var h=m,t=f,g=r,e=i;f=md5_ii(f=md5_ii(f=md5_ii(f=md5_ii(f=md5_hh(f=md5_hh(f=md5_hh(f=md5_hh(f=md5_gg(f=md5_gg(f=md5_gg(f=md5_gg(f=md5_ff(f=md5_ff(f=md5_ff(f=md5_ff(f,r=md5_ff(r,i=md5_ff(i,m=md5_ff(m,f,r,i,d[n+0],7,-680876936),f,r,d[n+1],12,-389564586),m,f,d[n+2],17,606105819),i,m,d[n+3],22,-1044525330),r=md5_ff(r,i=md5_ff(i,m=md5_ff(m,f,r,i,d[n+4],7,-176418897),f,r,d[n+5],12,1200080426),m,f,d[n+6],17,-1473231341),i,m,d[n+7],22,-45705983),r=md5_ff(r,i=md5_ff(i,m=md5_ff(m,f,r,i,d[n+8],7,1770035416),f,r,d[n+9],12,-1958414417),m,f,d[n+10],17,-42063),i,m,d[n+11],22,-1990404162),r=md5_ff(r,i=md5_ff(i,m=md5_ff(m,f,r,i,d[n+12],7,1804603682),f,r,d[n+13],12,-40341101),m,f,d[n+14],17,-1502002290),i,m,d[n+15],22,1236535329),r=md5_gg(r,i=md5_gg(i,m=md5_gg(m,f,r,i,d[n+1],5,-165796510),f,r,d[n+6],9,-1069501632),m,f,d[n+11],14,643717713),i,m,d[n+0],20,-373897302),r=md5_gg(r,i=md5_gg(i,m=md5_gg(m,f,r,i,d[n+5],5,-701558691),f,r,d[n+10],9,38016083),m,f,d[n+15],14,-660478335),i,m,d[n+4],20,-405537848),r=md5_gg(r,i=md5_gg(i,m=md5_gg(m,f,r,i,d[n+9],5,568446438),f,r,d[n+14],9,-1019803690),m,f,d[n+3],14,-187363961),i,m,d[n+8],20,1163531501),r=md5_gg(r,i=md5_gg(i,m=md5_gg(m,f,r,i,d[n+13],5,-1444681467),f,r,d[n+2],9,-51403784),m,f,d[n+7],14,1735328473),i,m,d[n+12],20,-1926607734),r=md5_hh(r,i=md5_hh(i,m=md5_hh(m,f,r,i,d[n+5],4,-378558),f,r,d[n+8],11,-2022574463),m,f,d[n+11],16,1839030562),i,m,d[n+14],23,-35309556),r=md5_hh(r,i=md5_hh(i,m=md5_hh(m,f,r,i,d[n+1],4,-1530992060),f,r,d[n+4],11,1272893353),m,f,d[n+7],16,-155497632),i,m,d[n+10],23,-1094730640),r=md5_hh(r,i=md5_hh(i,m=md5_hh(m,f,r,i,d[n+13],4,681279174),f,r,d[n+0],11,-358537222),m,f,d[n+3],16,-722521979),i,m,d[n+6],23,76029189),r=md5_hh(r,i=md5_hh(i,m=md5_hh(m,f,r,i,d[n+9],4,-640364487),f,r,d[n+12],11,-421815835),m,f,d[n+15],16,530742520),i,m,d[n+2],23,-995338651),r=md5_ii(r,i=md5_ii(i,m=md5_ii(m,f,r,i,d[n+0],6,-198630844),f,r,d[n+7],10,1126891415),m,f,d[n+14],15,-1416354905),i,m,d[n+5],21,-57434055),r=md5_ii(r,i=md5_ii(i,m=md5_ii(m,f,r,i,d[n+12],6,1700485571),f,r,d[n+3],10,-1894986606),m,f,d[n+10],15,-1051523),i,m,d[n+1],21,-2054922799),r=md5_ii(r,i=md5_ii(i,m=md5_ii(m,f,r,i,d[n+8],6,1873313359),f,r,d[n+15],10,-30611744),m,f,d[n+6],15,-1560198380),i,m,d[n+13],21,1309151649),r=md5_ii(r,i=md5_ii(i,m=md5_ii(m,f,r,i,d[n+4],6,-145523070),f,r,d[n+11],10,-1120210379),m,f,d[n+2],15,718787259),i,m,d[n+9],21,-343485551),m=safe_add(m,h),f=safe_add(f,t),r=safe_add(r,g),i=safe_add(i,e)}return Array(m,f,r,i)}function md5_cmn(d,_,m,f,r,i){return safe_add(bit_rol(safe_add(safe_add(_,d),safe_add(f,i)),r),m)}function md5_ff(d,_,m,f,r,i,n){return md5_cmn(_&m|~_&f,d,_,r,i,n)}function md5_gg(d,_,m,f,r,i,n){return md5_cmn(_&f|m&~f,d,_,r,i,n)}function md5_hh(d,_,m,f,r,i,n){return md5_cmn(_^m^f,d,_,r,i,n)}function md5_ii(d,_,m,f,r,i,n){return md5_cmn(m^(_|~f),d,_,r,i,n)}function safe_add(d,_){var m=(65535&d)+(65535&_);return(d>>16)+(_>>16)+(m>>16)<<16|65535&m}function bit_rol(d,_){return d<<_|d>>>32-_};

const flagEmojiTranslations = {
  EN: 'GB',
  JA: 'JP',
  ZH: 'CH',
  FA: 'IR',
  UK: 'UA',
  KA: 'GE',
  HY: 'AM',
  HE: 'IS',
}
function getFlagEmoji(countryCode) {
  const codePoints = (flagEmojiTranslations[countryCode.toUpperCase()] || countryCode.toUpperCase())
    .split('')
    .map(char =>  127397 + char.charCodeAt());
  return String.fromCodePoint(...codePoints);
}

const locale = new Intl.Locale(navigator.language);

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
    milestone: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5120 5120"><path d="M923 4680c-12-5-26-18-32-29-7-13-11-151-11-404v-384l23-21c21-20 34-22 155-22h132V2790c0-684 4-1064 11-1132 65-605 510-1085 1115-1204 133-27 376-24 514 5 496 105 899 474 1039 948 57 196 55 146 59 1326l3 1087h133c194 0 176-43 176 432 0 365-1 387-19 409l-19 24-1629 2c-926 1-1637-2-1650-7zm888-1416c21-23 24-36 27-120 2-52 6-94 9-94 2 0 57 44 121 98 170 142 170 142 213 142 66 0 106-63 78-120-8-15-88-90-179-165s-171-142-178-149c-11-11 19-40 162-160 97-80 183-158 192-172 38-58-25-145-93-129-16 3-93 60-173 127l-145 121-6-94c-7-111-12-125-51-145-36-18-73-12-105 18l-23 21v401c0 397 0 400 22 423 31 33 96 32 129-3zm907 6c12-12 23-22 24-23s5-105 8-230l5-229 79 117c86 126 106 145 149 145 47 0 64-16 150-143l82-122 5 225c6 270 9 280 96 280 24 0 43-8 59-25l25-24v-394c0-378-1-395-20-420-11-13-32-28-46-31-56-14-79 8-211 203-69 102-129 190-133 194s-66-80-140-187c-138-202-160-224-214-210-14 3-35 18-46 31-19 25-20 42-20 418 0 382 1 393 21 419 27 34 94 37 127 6zm-27-1273c55-23 119-86 145-142 38-81 30-188-18-258l-19-27 30-62c70-138 19-298-115-364-58-29-62-29-232-29h-174l-24 28c-32 38-32 90 1 122 23 24 28 25 170 25 154 0 193 9 215 49 16 31 12 77-9 102-18 23-26 24-186 29l-167 5-24 28c-32 38-32 90 1 122 23 24 29 25 165 25 150 0 199 11 219 48 16 29 14 74-4 99-23 33-75 43-223 43-128 0-134 1-157 25-44 43-30 115 28 141 45 20 326 14 378-9z"/></svg>',
    level_crossing: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5120 5120"><g><path d="M2270 3875V2630l145-72 145-73 145 73 145 72v2490h-580V3875z"/><path d="M405 3034c-110-42-202-77-203-79-3-3 23-99 104-381l15-52 749-378c412-208 746-382 742-386-4-3-338-174-742-378s-739-375-743-380c-15-14-129-422-120-431 4-4 99-41 209-83l202-75 971 490 971 490 972-490 971-490 201 75c111 42 205 79 209 83 9 8-105 417-120 431-4 5-339 176-743 380s-738 375-742 378c-4 4 330 178 742 386l749 378 16 56c9 31 37 128 62 215s44 160 41 162c-2 3-97 39-210 81l-206 76-971-488-971-489-969 488c-533 268-972 487-977 487-5-1-99-35-209-76z"/><path d="m2413 967-143-72V0h580v895l-144 73c-79 39-145 72-147 71-2 0-68-32-146-72z"/></g></svg>',
    crossing: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" viewBox="0 0 5120 5120"><g><path d="M2270 3875V2630l145-72 145-73 145 73 145 72v2490h-580V3875z"/><path d="M405 3034c-110-42-202-77-203-79-3-3 23-99 104-381l15-52 749-378c412-208 746-382 742-386-4-3-338-174-742-378s-739-375-743-380c-15-14-129-422-120-431 4-4 99-41 209-83l202-75 971 490 971 490 972-490 971-490 201 75c111 42 205 79 209 83 9 8-105 417-120 431-4 5-339 176-743 380s-738 375-742 378c-4 4 330 178 742 386l749 378 16 56c9 31 37 128 62 215s44 160 41 162c-2 3-97 39-210 81l-206 76-971-488-971-489-969 488c-533 268-972 487-977 487-5-1-99-35-209-76z"/><path d="m2413 967-143-72V0h580v895l-144 73c-79 39-145 72-147 71-2 0-68-32-146-72z"/></g></svg>',
  },
  edit: '<svg xmlns="http://www.w3.org/2000/svg" width="auto" height="16" fill="#007bff" viewBox="0 0 24 24"><path d="M7.127 22.562l-7.127 1.438 1.438-7.128 5.689 5.69zm1.414-1.414l11.228-11.225-5.69-5.692-11.227 11.227 5.689 5.69zm9.768-21.148l-2.816 2.817 5.691 5.691 2.816-2.819-5.691-5.689z"/></svg>',
  osm: {
    node: 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB3aWR0aD0iMTIiIGhlaWdodD0iMTIiIHZpZXdCb3g9IjAgMCAxMiAxMiI+CjxwYXRoIGZpbGwtcnVsZT0ibm9uemVybyIgZmlsbD0icmdiKDEwMCUsIDEwMCUsIDEwMCUpIiBmaWxsLW9wYWNpdHk9IjEiIGQ9Ik0gMS44MjgxMjUgMC4zMjgxMjUgTCAxMC4xNzE4NzUgMC4zMjgxMjUgQyAxMSAwLjMyODEyNSAxMS42NzE4NzUgMSAxMS42NzE4NzUgMS44MjgxMjUgTCAxMS42NzE4NzUgMTAuMTcxODc1IEMgMTEuNjcxODc1IDExIDExIDExLjY3MTg3NSAxMC4xNzE4NzUgMTEuNjcxODc1IEwgMS44MjgxMjUgMTEuNjcxODc1IEMgMSAxMS42NzE4NzUgMC4zMjgxMjUgMTEgMC4zMjgxMjUgMTAuMTcxODc1IEwgMC4zMjgxMjUgMS44MjgxMjUgQyAwLjMyODEyNSAxIDEgMC4zMjgxMjUgMS44MjgxMjUgMC4zMjgxMjUgWiBNIDEuODI4MTI1IDAuMzI4MTI1ICIvPgo8cGF0aCBmaWxsLXJ1bGU9Im5vbnplcm8iIGZpbGw9InJnYig3NC41MDk4MDQlLCA5MC4xOTYwNzglLCA3NC41MDk4MDQlKSIgZmlsbC1vcGFjaXR5PSIxIiBzdHJva2Utd2lkdGg9IjEwIiBzdHJva2UtbGluZWNhcD0iYnV0dCIgc3Ryb2tlLWxpbmVqb2luPSJtaXRlciIgc3Ryb2tlPSJyZ2IoMCUsIDAlLCAwJSkiIHN0cm9rZS1vcGFjaXR5PSIxIiBzdHJva2UtbWl0ZXJsaW1pdD0iNCIgZD0iTSAxNTIgMTI4IEMgMTUyIDE0MS4yNSAxNDEuMjUgMTUyIDEyOCAxNTIgQyAxMTQuNzUgMTUyIDEwNCAxNDEuMjUgMTA0IDEyOCBDIDEwNCAxMTQuNzUgMTE0Ljc1IDEwNCAxMjggMTA0IEMgMTQxLjI1IDEwNCAxNTIgMTE0Ljc1IDE1MiAxMjggWiBNIDE1MiAxMjggIiB0cmFuc2Zvcm09Im1hdHJpeCgwLjA0Njg3NSwgMCwgMCwgMC4wNDY4NzUsIDAsIDApIi8+CjxwYXRoIGZpbGw9Im5vbmUiIHN0cm9rZS13aWR0aD0iMTIiIHN0cm9rZS1saW5lY2FwPSJidXR0IiBzdHJva2UtbGluZWpvaW49Im1pdGVyIiBzdHJva2U9InJnYigwJSwgMCUsIDAlKSIgc3Ryb2tlLW9wYWNpdHk9IjEiIHN0cm9rZS1taXRlcmxpbWl0PSI0IiBkPSJNIDM5IDcgTCAyMTcgNyBDIDIzNC42NjY2NjcgNyAyNDkgMjEuMzMzMzMzIDI0OSAzOSBMIDI0OSAyMTcgQyAyNDkgMjM0LjY2NjY2NyAyMzQuNjY2NjY3IDI0OSAyMTcgMjQ5IEwgMzkgMjQ5IEMgMjEuMzMzMzMzIDI0OSA3IDIzNC42NjY2NjcgNyAyMTcgTCA3IDM5IEMgNyAyMS4zMzMzMzMgMjEuMzMzMzMzIDcgMzkgNyBaIE0gMzkgNyAiIHRyYW5zZm9ybT0ibWF0cml4KDAuMDQ2ODc1LCAwLCAwLCAwLjA0Njg3NSwgMCwgMCkiLz4KPC9zdmc+Cg==',
    way: 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB3aWR0aD0iMTIiIGhlaWdodD0iMTIiIHZpZXdCb3g9IjAgMCAxMiAxMiI+CjxwYXRoIGZpbGwtcnVsZT0ibm9uemVybyIgZmlsbD0icmdiKDEwMCUsIDEwMCUsIDEwMCUpIiBmaWxsLW9wYWNpdHk9IjEiIGQ9Ik0gMS44MjgxMjUgMC4zMjgxMjUgTCAxMC4xNzE4NzUgMC4zMjgxMjUgQyAxMSAwLjMyODEyNSAxMS42NzE4NzUgMSAxMS42NzE4NzUgMS44MjgxMjUgTCAxMS42NzE4NzUgMTAuMTcxODc1IEMgMTEuNjcxODc1IDExIDExIDExLjY3MTg3NSAxMC4xNzE4NzUgMTEuNjcxODc1IEwgMS44MjgxMjUgMTEuNjcxODc1IEMgMSAxMS42NzE4NzUgMC4zMjgxMjUgMTEgMC4zMjgxMjUgMTAuMTcxODc1IEwgMC4zMjgxMjUgMS44MjgxMjUgQyAwLjMyODEyNSAxIDEgMC4zMjgxMjUgMS44MjgxMjUgMC4zMjgxMjUgWiBNIDEuODI4MTI1IDAuMzI4MTI1ICIvPgo8cGF0aCBmaWxsPSJub25lIiBzdHJva2Utd2lkdGg9IjE2IiBzdHJva2UtbGluZWNhcD0iYnV0dCIgc3Ryb2tlLWxpbmVqb2luPSJtaXRlciIgc3Ryb2tlPSJyZ2IoODAlLCA4MCUsIDgwJSkiIHN0cm9rZS1vcGFjaXR5PSIxIiBzdHJva2UtbWl0ZXJsaW1pdD0iNCIgZD0iTSAxNjkgNTggTCA1NyAxNDUgTCAxOTUgMTk5ICIgdHJhbnNmb3JtPSJtYXRyaXgoMC4wNDY4NzUsIDAsIDAsIDAuMDQ2ODc1LCAwLCAwKSIvPgo8cGF0aCBmaWxsLXJ1bGU9Im5vbnplcm8iIGZpbGw9InJnYigwJSwgMCUsIDAlKSIgZmlsbC1vcGFjaXR5PSIxIiBkPSJNIDkuMDQ2ODc1IDIuNzE4NzUgQyA5LjA0Njg3NSAzLjMzOTg0NCA4LjU0Mjk2OSAzLjg0Mzc1IDcuOTIxODc1IDMuODQzNzUgQyA3LjMwMDc4MSAzLjg0Mzc1IDYuNzk2ODc1IDMuMzM5ODQ0IDYuNzk2ODc1IDIuNzE4NzUgQyA2Ljc5Njg3NSAyLjA5NzY1NiA3LjMwMDc4MSAxLjU5Mzc1IDcuOTIxODc1IDEuNTkzNzUgQyA4LjU0Mjk2OSAxLjU5Mzc1IDkuMDQ2ODc1IDIuMDk3NjU2IDkuMDQ2ODc1IDIuNzE4NzUgWiBNIDkuMDQ2ODc1IDIuNzE4NzUgIi8+CjxwYXRoIGZpbGwtcnVsZT0ibm9uemVybyIgZmlsbD0icmdiKDAlLCAwJSwgMCUpIiBmaWxsLW9wYWNpdHk9IjEiIGQ9Ik0gMy43OTY4NzUgNi43OTY4NzUgQyAzLjc5Njg3NSA3LjQxNzk2OSAzLjI5Mjk2OSA3LjkyMTg3NSAyLjY3MTg3NSA3LjkyMTg3NSBDIDIuMDUwNzgxIDcuOTIxODc1IDEuNTQ2ODc1IDcuNDE3OTY5IDEuNTQ2ODc1IDYuNzk2ODc1IEMgMS41NDY4NzUgNi4xNzU3ODEgMi4wNTA3ODEgNS42NzE4NzUgMi42NzE4NzUgNS42NzE4NzUgQyAzLjI5Mjk2OSA1LjY3MTg3NSAzLjc5Njg3NSA2LjE3NTc4MSAzLjc5Njg3NSA2Ljc5Njg3NSBaIE0gMy43OTY4NzUgNi43OTY4NzUgIi8+CjxwYXRoIGZpbGwtcnVsZT0ibm9uemVybyIgZmlsbD0icmdiKDAlLCAwJSwgMCUpIiBmaWxsLW9wYWNpdHk9IjEiIGQ9Ik0gMTAuMjY1NjI1IDkuMzI4MTI1IEMgMTAuMjY1NjI1IDkuOTQ5MjE5IDkuNzYxNzE5IDEwLjQ1MzEyNSA5LjE0MDYyNSAxMC40NTMxMjUgQyA4LjUxOTUzMSAxMC40NTMxMjUgOC4wMTU2MjUgOS45NDkyMTkgOC4wMTU2MjUgOS4zMjgxMjUgQyA4LjAxNTYyNSA4LjcwNzAzMSA4LjUxOTUzMSA4LjIwMzEyNSA5LjE0MDYyNSA4LjIwMzEyNSBDIDkuNzYxNzE5IDguMjAzMTI1IDEwLjI2NTYyNSA4LjcwNzAzMSAxMC4yNjU2MjUgOS4zMjgxMjUgWiBNIDEwLjI2NTYyNSA5LjMyODEyNSAiLz4KPHBhdGggZmlsbD0ibm9uZSIgc3Ryb2tlLXdpZHRoPSIxMiIgc3Ryb2tlLWxpbmVjYXA9ImJ1dHQiIHN0cm9rZS1saW5lam9pbj0ibWl0ZXIiIHN0cm9rZT0icmdiKDAlLCAwJSwgMCUpIiBzdHJva2Utb3BhY2l0eT0iMSIgc3Ryb2tlLW1pdGVybGltaXQ9IjQiIGQ9Ik0gMzkgNyBMIDIxNyA3IEMgMjM0LjY2NjY2NyA3IDI0OSAyMS4zMzMzMzMgMjQ5IDM5IEwgMjQ5IDIxNyBDIDI0OSAyMzQuNjY2NjY3IDIzNC42NjY2NjcgMjQ5IDIxNyAyNDkgTCAzOSAyNDkgQyAyMS4zMzMzMzMgMjQ5IDcgMjM0LjY2NjY2NyA3IDIxNyBMIDcgMzkgQyA3IDIxLjMzMzMzMyAyMS4zMzMzMzMgNyAzOSA3IFogTSAzOSA3ICIgdHJhbnNmb3JtPSJtYXRyaXgoMC4wNDY4NzUsIDAsIDAsIDAuMDQ2ODc1LCAwLCAwKSIvPgo8L3N2Zz4K',
    relation: 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIj8+CjxzdmcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiIHhtbG5zOmNjPSJodHRwOi8vY3JlYXRpdmVjb21tb25zLm9yZy9ucyMiIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgdmVyc2lvbj0iMS4wIiBoZWlnaHQ9IjI1NiIgd2lkdGg9IjI1NiI+PHRpdGxlPk9wZW5TdHJlZXRNYXAgcmVsYXRpb24gZWxlbWVudCBpY29uPC90aXRsZT48bWV0YWRhdGE+PHJkZjpSREY+PGNjOldvcmsgcmRmOmFib3V0PSIiPjxkYzpmb3JtYXQ+aW1hZ2Uvc3ZnK3htbDwvZGM6Zm9ybWF0PjxkYzp0eXBlIHJkZjpyZXNvdXJjZT0iaHR0cDovL3B1cmwub3JnL2RjL2RjbWl0eXBlL1N0aWxsSW1hZ2UiLz48ZGM6dGl0bGU+T3BlblN0cmVldE1hcCByZWxhdGlvbiBlbGVtZW50IGljb248L2RjOnRpdGxlPjxjYzpsaWNlbnNlIHJkZjpyZXNvdXJjZT0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbGljZW5zZXMvYnkvMy4wLyIvPjxkYzpkYXRlPjIwMTQtMDMtMTA8L2RjOmRhdGU+PGRjOmNyZWF0b3I+PGNjOkFnZW50PjxkYzp0aXRsZT5odHRwczovL3dpa2kub3BlbnN0cmVldG1hcC5vcmcvd2lraS9Vc2VyOk1vcmVzYnk8L2RjOnRpdGxlPjwvY2M6QWdlbnQ+PC9kYzpjcmVhdG9yPjwvY2M6V29yaz48Y2M6TGljZW5zZSByZGY6YWJvdXQ9Imh0dHA6Ly9jcmVhdGl2ZWNvbW1vbnMub3JnL2xpY2Vuc2VzL2J5LzMuMC8iPjxjYzpwZXJtaXRzIHJkZjpyZXNvdXJjZT0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjUmVwcm9kdWN0aW9uIi8+PGNjOnBlcm1pdHMgcmRmOnJlc291cmNlPSJodHRwOi8vY3JlYXRpdmVjb21tb25zLm9yZy9ucyNEaXN0cmlidXRpb24iLz48Y2M6cmVxdWlyZXMgcmRmOnJlc291cmNlPSJodHRwOi8vY3JlYXRpdmVjb21tb25zLm9yZy9ucyNOb3RpY2UiLz48Y2M6cmVxdWlyZXMgcmRmOnJlc291cmNlPSJodHRwOi8vY3JlYXRpdmVjb21tb25zLm9yZy9ucyNBdHRyaWJ1dGlvbiIvPjxjYzpwZXJtaXRzIHJkZjpyZXNvdXJjZT0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjRGVyaXZhdGl2ZVdvcmtzIi8+PGNjOnJlcXVpcmVzIHJkZjpyZXNvdXJjZT0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjU2hhcmVBbGlrZSIvPjwvY2M6TGljZW5zZT48L3JkZjpSREY+PC9tZXRhZGF0YT48Zz48cmVjdCB3aWR0aD0iMjQyIiBoZWlnaHQ9IjI0MiIgc3Ryb2tlPSJub25lIiBmaWxsPSJ3aGl0ZSIgcnk9IjMyIiB4PSI3IiB5PSI3Ii8+PGc+PHBhdGggZD0iTSAwNjggMDY4IEwgMTk2IDA2MiIgc3Ryb2tlLXdpZHRoPSIxNiIgc3Ryb2tlPSIjY2NjIi8+PHBhdGggZD0iTSAwNjggMDY4IEwgMTk2IDE0MiIgc3Ryb2tlLXdpZHRoPSIxNiIgc3Ryb2tlPSIjY2NjIi8+PHBhdGggZD0iTSAwNjggMDY4IEwgMDYyIDE5NiIgc3Ryb2tlLXdpZHRoPSIxNiIgc3Ryb2tlPSIjY2NjIi8+PGNpcmNsZSBjeD0iMTk2IiBjeT0iMDYyIiByPSIwMjQiIGZpbGw9ImJsYWNrIi8+PGNpcmNsZSBjeD0iMTk2IiBjeT0iMTQyIiByPSIwMjQiIGZpbGw9ImJsYWNrIi8+PGNpcmNsZSBjeD0iMDYyIiBjeT0iMTk2IiByPSIwMjQiIGZpbGw9ImJsYWNrIi8+PC9nPjxnPjxwYXRoIGQ9Ik0gMDY4IDA2OCBMIDE0MiAxOTYiIHN0cm9rZS13aWR0aD0iMTYiIHN0cm9rZT0iI2NjYyIvPjxjaXJjbGUgY3g9IjE0MiIgY3k9IjE5NiIgcj0iMDI0IiBmaWxsPSJibGFjayIvPjxjaXJjbGUgY3g9IjA3MiIgY3k9IjA3MiIgcj0iMDMyIiBmaWxsPSIjYmVlNmJlIiBzdHJva2U9ImJsYWNrIiBzdHJva2Utd2lkdGg9IjgiLz48L2c+PHJlY3Qgd2lkdGg9IjI0MiIgaGVpZ2h0PSIyNDIiIHN0cm9rZT0iYmxhY2siIGZpbGw9Im5vbmUiIHN0cm9rZS13aWR0aD0iMTIiIHJ5PSIzMiIgeD0iNyIgeT0iNyIvPjwvZz48L3N2Zz4K',
  }
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

function facilitySearchUrl(type, term, language) {
  const url = new URL(`${location.origin}/api/facility`)
  url.searchParams.set('lang', language)

  switch (type) {
    case 'name':
      url.searchParams.set('name', term)
      break;

    case 'ref':
      url.searchParams.set('ref', term)
      break;

    case 'uic_ref':
      url.searchParams.set('uic_ref', term)
      break;

    case 'all':
    default:
      url.searchParams.set('q', term)
  }

  return url
}

function searchForFacilities(type, term, language) {
  if (!term || term.length < 2) {
    hideSearchResults();
  } else {
    fetch(facilitySearchUrl(type, term, language))
      .then(result => result.json())
      .then(result => result.map(item => ({
        ...item,
        label: [...new Set([item.localized_name, item.name])].join(' • '),
        icon: icons.railway[item.railway] ?? null,
      })))
      .then(result => {
        showSearchResults(result)
      })
      .catch(error => {
        hideSearchResults();
        hideSearch();
        console.error('Error during facility search', error);
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
        label: `Line ${item.line_ref} @ ${item.position}`,
        icon: icons.railway[item.railway] ?? null,
      })))
      .then(result => {
        showSearchResults(result)
      })
      .catch(error => {
        hideSearchResults();
        hideSearch();
        console.error('Error during milestone search', error);
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
          <span class="badge rounded-pill text-bg-light">0 results</span>
        </span>
      </div>
    `
    : `
      <div class="mb-1 d-flex align-items-center">
        <span class="flex-grow-1">
          <span class="badge rounded-pill text-bg-light">${results.length} results</span>
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
  if ((configuration.backgroundType ?? defaultConfiguration.backgroundType) === 'raster') {
    backgroundTypeRasterControl.checked = true;
  } else {
    backgroundTypeVectorControl.checked = true;
  }
  backgroundUrlControl.value = configuration.backgroundUrl ?? defaultConfiguration.backgroundUrl;

  if (configuration.backgroundHillShade ?? defaultConfiguration.backgroundHillShade) {
    backgroundHillShadeEnabledControl.checked = true
  } else {
    backgroundHillShadeDisabledControl.checked = true
  }

  const theme = configuration.theme ?? defaultConfiguration.theme;
  if (theme === 'system') {
    themeSystemControl.checked = true;
  } else if (theme === 'dark') {
    themeDarkControl.checked = true
  } else if (theme === 'light') {
    themeLightControl.checked = true;
  }

  const editor = configuration.editor ?? defaultConfiguration.editor;
  if (editor === 'josm') {
    editorJOSMControl.checked = true;
  } else {
    editorIDControl.checked = true;
  }

  const stationLowZoomLabel = configuration.stationLowZoomLabel ?? defaultConfiguration.stationLowZoomLabel
  if (stationLowZoomLabel === 'label') {
    stationLabelReferenceControl.checked = true
  } else if (stationLowZoomLabel === 'name') {
    stationLabelNameControl.checked = true
  }

  configurationBackdrop.style.display = 'block';
}

function hideConfiguration() {
  configurationBackdrop.style.display = 'none';
}

function hideLegend() {
  legend.style.display = 'none';
}

function showLegend() {
  legend.style.display = 'block';
}

function isLegendShown() {
  return legend.style.display === 'block';
}

function toggleLegend() {
  if (isLegendShown()) {
    hideLegend();
  } else {
    showLegend();
  }
}

function toggleNews() {
  if (newsBackdrop.style.display === 'block') {
    hideNews();
  } else {
    showNews();
  }
}

function showNews() {
  newsBackdrop.style.display = 'block';

  const newsHash = aboutControl.newsHash()
  if (newsHash) {
    updateConfiguration('newsHash', newsHash);
  }
}

function hideNews() {
  newsBackdrop.style.display = 'none';
}

function newsLink(style, zoom, lat, lon, date) {
  hideNews();
  selectStyle(style);
  selectDate(date ?? defaultDate);
  map.jumpTo({zoom, center: {lat, lon}});
}

function showAbout() {
  aboutBackdrop.style.display = 'block';
}

function hideAbout() {
  aboutBackdrop.style.display = 'none';
}

function toggleAbout() {
  if (aboutBackdrop.style.display === 'block') {
    showAbout();
  } else {
    showAbout();
  }
}

searchFacilitiesForm.addEventListener('submit', event => {
  event.preventDefault();
  const formData = new FormData(event.target);
  const data = Object.fromEntries(formData);
  searchForFacilities(data.type, data.term, locale.language)
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
newsBackdrop.onclick = event => {
  if (event.target === event.currentTarget) {
    hideNews();
  }
};

// Bind Escape keypress (without modifiers) to close all modal windows
document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && !(event.ctrlKey || event.altKey || event.shiftKey)) {
    hideSearch();
    hideConfiguration();
    hideNews();
    hideAbout();
    hideLegend();
    if (popup) {
      popup.remove();
      popup = null;
    }
  }
});

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
const globalMaxZoom = 20;

const knownStyles = {
  standard: {
    name: 'Infrastructure',
    styles: {
      default: 'standard',
      date: 'historical',
    },
  },
  speed: {
    name: 'Speed',
    styles: {
      default: 'speed',
    },
  },
  signals: {
    name: 'Train protection',
    styles: {
      default: 'signals',
    },
  },
  electrification: {
    name: 'Electrification',
    styles: {
      default: 'electrification',
    },
  },
  gauge: {
    name: 'Gauge',
    styles: {
      default: 'gauge',
    },
  },
  loading_gauge: {
    name: 'Loading gauge',
    styles: {
      default: 'loading_gauge',
    },
  },
  track_class: {
    name: 'Track class',
    styles: {
      default: 'track_class',
    },
  },
  operator: {
    name: 'Operator',
    styles: {
      default: 'operator',
    },
  },
};

const defaultStyle = Object.keys(knownStyles)[0];
const defaultDate = (new Date()).getFullYear();

const knownThemes = [
  'light',
  'dark',
]

function layerHasDateFilter(layer) {
  return layer.filter
    && layer.filter[0] === 'let'
    && layer.filter[1] === 'date'
}

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

function determineParametersFromHash(hash) {
  const hashObject = hashToObject(hash);

  const style = (hashObject.style && hashObject.style in knownStyles)
    ? hashObject.style
    : defaultStyle;

  const date = (hashObject.date && !isNaN(parseFloat(hashObject.date)))
    ? parseFloat(hashObject.date)
    : defaultDate;

  return {
    style,
    date,
  }
}

function determineZoomCenterFromHash(hash) {
  const hashObject = hashToObject(hash);
  if ('view' in hashObject && typeof hashObject.view === 'string') {
    const matches = hashObject.view.match(/^(?<zoom>[\d.]+)\/(?<latitude>-?[\d.]+)\/(?<longitude>-?[\d.]+)(?:\/(?<bearing>-?[\d.]+))?$/);
    if (matches) {
      const groups = matches.groups
      return {
        center: [parseFloat(groups.longitude), parseFloat(groups.latitude)],
        zoom: parseFloat(groups.zoom),
        bearing: groups.bearing ?? 0.0,
      }
    } else {
      return {};
    }
  } else {
    return {};
  }
}

function putParametersInHash(hash, style, date) {
  const hashObject = hashToObject(hash);
  hashObject.style = style !== defaultStyle ? style : undefined;
  hashObject.date = knownStyles[style].styles.date && dateControl.active ? date : undefined;
  return `#${Object.entries(hashObject).filter(([_, value]) => value).map(([key, value]) => `${key}=${value}`).join('&')}`;
}

let {style: selectedStyle, date: selectedDate} = determineParametersFromHash(window.location.hash)

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

function migrateConfiguration(localStorage, configuration) {
  if (configuration.backgroundSaturation && configuration.backgroundSaturation < 0.0) {
    console.info('Migrating background saturation from', configuration.backgroundSaturation, 'to', configuration.backgroundSaturation + 1.0)
    configuration.backgroundSaturation += 1.0;
    storeConfiguration(localStorage, configuration);
  }

  if (configuration.backgroundRasterUrl) {
    console.info('Migrating background raster URL:', configuration.backgroundRasterUrl)
    configuration.backgroundType = 'raster';
    configuration.backgroundUrl = configuration.backgroundRasterUrl;
    delete configuration.backgroundRasterUrl;
    storeConfiguration(localStorage, configuration);
  }

  return configuration;
}

function storeConfiguration(localStorage, configuration) {
  localStorage.setItem(localStorageKey, JSON.stringify(configuration));
}

function updateConfiguration(name, value) {
  configuration[name] = value;
  storeConfiguration(localStorage, configuration);
}

function clamp(value, min, max) {
  return Math.max(Math.min(value, max), min);
}

function buildBackgroundMapStyle() {
  if ((configuration.backgroundType ?? defaultConfiguration.backgroundType) === 'raster') {
    return {
      name: 'Background map',
      version: 8,
      layers: [
        {
          id: "background-map",
          type: "raster",
          source: "background_map",
        },
      ],
      sources: {
        background_map: {
          type: 'raster',
          tiles: [
            configuration.backgroundUrl ?? defaultConfiguration.backgroundUrl,
          ],
          tileSize: 256,
        },
      },
    };
  } else {
    return configuration.backgroundUrl ?? defaultConfiguration.backgroundUrl;
  }
}

function updateBackgroundMapStyle() {
  backgroundMap.setStyle(buildBackgroundMapStyle());
}

function enableHillShade() {
  updateConfiguration('backgroundHillShade', false)
  updateHillShadeOnMap();
}

function disableHillShade() {
  updateConfiguration('backgroundHillShade', true)
  updateHillShadeOnMap();
}

function updateHillShadeOnMap() {
  const hillshadeVisible = configuration.backgroundHillShade ?? defaultConfiguration.backgroundHillShade
  map.setLayoutProperty('hillshade', 'visibility', hillshadeVisible ? 'visible' : 'none')
}

function onStationLabelChange(stationlabel) {
  updateConfiguration('stationLowZoomLabel', stationlabel);

  if (map.loaded()) {
    map.setGlobalStateProperty('stationLowZoomLabel', stationlabel);
  }
  if (legendMap.loaded()) {
    legendMap.setGlobalStateProperty('stationLowZoomLabel', stationlabel);
  }
}

function resolveTheme(configuredTheme) {
  return configuredTheme === 'system'
    ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
    : configuredTheme;
}

function onThemeChange(theme) {
  updateConfiguration('theme', theme);
  updateTheme();
}

let selectedTheme;
function updateTheme() {
  const resolvedTheme = resolveTheme(configuration.theme ?? defaultConfiguration.theme)

  selectedTheme = resolvedTheme;

  document.documentElement.setAttribute('data-bs-theme', resolvedTheme);

  if (map.loaded()) {
    map.setGlobalStateProperty('theme', resolvedTheme);
  }
  if (legendMap.loaded()) {
    legendMap.setGlobalStateProperty('theme', resolvedTheme);
  }
}

function onEditorChange(editor) {
  updateConfiguration('editor', editor);
}

function updateBackgroundMapContainer() {
  backgroundMapContainer.style.filter = `saturate(${clamp(configuration.backgroundSaturation ?? defaultConfiguration.backgroundSaturation, 0.0, 1.0)}) opacity(${clamp(configuration.backgroundOpacity ?? defaultConfiguration.backgroundOpacity, 0.0, 1.0)})`;
}

/**
 * Based on https://github.com/osm-americana/openstreetmap-americana/blob/1c65cc6/shieldlib/src/screen_gfx.ts
 */
async function transposeImageData(context, source) {
  const imageData = context.createImageData(source.data.width, source.data.height);

  for (let i = 0; i < source.data.data.length; i += 4) {
    imageData.data[i] = source.data.data[i]; // Red
    imageData.data[i + 1] = source.data.data[i + 1]; // Green
    imageData.data[i + 2] = source.data.data[i + 2]; // Blue
    imageData.data[i + 3] = source.data.data[i + 3]; // Alpha
  }

  return await createImageBitmap(imageData)
}

function transposeSdfImageData(context, images, width, height) {
  const imageData = context.createImageData(width, height)

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {

      let distanceField = 0;
      for (const image of images) {
        if (
          image.sdfOffset.x <= x && x < image.sdfOffset.x + image.sdfImage.data.width &&
          image.sdfOffset.y <= y && y < image.sdfOffset.y + image.sdfImage.data.height
        ) {
          const imageI = 4 * ((y - image.sdfOffset.y) * image.sdfImage.data.width + (x - image.sdfOffset.x))
          distanceField = Math.max(distanceField, image.sdfImage.data.data[imageI + 3])
        }
      }

      const i = 4 * (y * width + x);
      // Indices 0, 1 and 2 of pixel are unused for SDF images
      imageData.data[i + 3] = distanceField;
    }
  }

  return imageData
}

const imageMatcher = /^(?<id>[^@]+)(@(?<position>center|bottom|top|right|left))?$/
function loadImages(imageIds) {
  return imageIds.map(imageId => {
    const parsed = imageId.match(imageMatcher)
    if (!parsed) {
      throw new Error(`Could not parse image ID '${imageId}'`)
    }

    const id = parsed.groups.id
    const position = parsed.groups.position ?? 'center'

    const image = map.getImage(id)
    if (!image) {
      throw new Error(`Could not load image ${id}`)
    }

    const sdfId = `sdf:${id}`
    const sdfImage = map.getImage(sdfId)
    if (!image) {
      throw new Error(`Could not load SDF image ${sdfId}`)
    }

    return {
      id,
      sdfId,
      image,
      sdfImage,
      position,
    }
  });
}

function layoutImages(images) {
  // Ignore position of first image
  // The width and height will grow as more images are composed
  let width = images[0].image.data.width
  let height = images[0].image.data.height

  // Offset: top left corner of the image
  // The offsets of all but the first image will be updated with their layed out position
  const offsetImages = images.map(image => ({
    ...image,
    offset: {
      x: 0,
      y: 0,
    },
    sdfOffset: null, // Will be filled in the last step
  }))

  // Offset of the top left corner of the composed image
  // Goal: allow expanding the composed image to the top or left without updating the offset of all other images
  // The global offset will be updated as images are added to the top or left of existing images
  const globalOffset = {
    x: 0,
    y: 0,
  }

  for (const image of offsetImages.slice(1)) {
    switch (image.position) {
      case 'center':
        image.offset.x = globalOffset.x + width / 2 - image.image.data.width / 2
        image.offset.y = globalOffset.y + height / 2 - image.image.data.height / 2
        globalOffset.x = Math.min(globalOffset.x, image.offset.x)
        globalOffset.y = Math.min(globalOffset.y, image.offset.y)
        width = Math.max(width, image.image.data.width)
        height = Math.max(height, image.image.data.height)
        break;

      case 'bottom':
        image.offset.x = globalOffset.x + width / 2 - image.image.data.width / 2
        image.offset.y = globalOffset.y + height
        globalOffset.x = Math.min(globalOffset.x, image.offset.x)
        globalOffset.y = Math.min(globalOffset.y, image.offset.y)
        width = Math.max(width, image.image.data.width)
        height = height + image.image.data.height
        break;

      case 'top':
        image.offset.x = globalOffset.x + width / 2 - image.image.data.width / 2
        image.offset.y = globalOffset.y - image.image.data.height
        globalOffset.x = Math.min(globalOffset.x, image.offset.x)
        globalOffset.y = Math.min(globalOffset.y, image.offset.y)
        width = Math.max(width, image.image.data.width)
        height = height + image.image.data.height
        break;

      case 'right':
        image.offset.x = globalOffset.x + width
        image.offset.y = globalOffset.y + height / 2 - image.image.data.height / 2
        globalOffset.x = Math.min(globalOffset.x, image.offset.x)
        globalOffset.y = Math.min(globalOffset.y, image.offset.y)
        width = width + image.image.data.width
        height = Math.max(height, image.image.data.height)
        break;

      case 'left':
        image.offset.x = globalOffset.x - image.image.data.width / 2
        image.offset.y = globalOffset.y + height / 2 - image.image.data.height / 2
        globalOffset.x = Math.min(globalOffset.x, image.offset.x)
        globalOffset.y = Math.min(globalOffset.y, image.offset.y)
        width = width + image.image.data.width
        height = Math.max(height, image.image.data.height)
        break;
    }
  }

  // Process SDF images which are larger than the normal images due to padding pixels
  offsetImages.forEach(image => {
    width = Math.max(width, image.offset.x - globalOffset.x + image.sdfImage.data.width)
    height = Math.max(height, image.offset.y - globalOffset.y + image.sdfImage.data.height)
  })
  offsetImages.forEach(image => {
    globalOffset.x = Math.min(globalOffset.x, image.offset.x + image.image.data.width / 2 - image.sdfImage.data.width / 2)
    globalOffset.y = Math.min(globalOffset.y, image.offset.y + image.image.data.height / 2 - image.sdfImage.data.height / 2)
  })

  // Get rid of global offset
  offsetImages.forEach(image => {
    image.offset.x -= globalOffset.x
    image.offset.y -= globalOffset.y
  })

  // Store the SDF image offset using the SDF image size
  offsetImages.forEach(image => {
    image.sdfOffset = {
      x: Math.floor(image.offset.x + image.image.data.width / 2 - image.sdfImage.data.width / 2),
      y: Math.floor(image.offset.y + image.image.data.height / 2 - image.sdfImage.data.height / 2),
    }
  })

  return {
    width,
    height,
    images: offsetImages
  }
}

/**
 * Given a list of maplibre images, this function merges them into into a single image by composing the images on top of each other.
 */
async function composeImages(imageIds) {
  const loadedImages = loadImages(imageIds)
  const { width, height, images } = layoutImages(loadedImages);

  const canvas = document.createElement("canvas");
  const context = canvas.getContext('2d')
  canvas.width = width;
  canvas.height = height;

  const imageDatas = await Promise.all(images.map(async image => ({
    data: await transposeImageData(context, image.image),
    offset: image.offset,
  })))
  for (const {data, offset} of imageDatas) {
    context.drawImage(data, offset.x, offset.y)
  }
  const renderedImageData = context.getImageData(0, 0, width, height);

  const canvas2 = document.createElement("canvas");
  const context2 = canvas2.getContext('2d')
  canvas2.width = width;
  canvas2.height = height;
  const sdfImageData = transposeSdfImageData(context2, images, width, height)

  return {
    width,
    height,
    imageData: new Uint8Array(renderedImageData.data.buffer),
    sdfImageData: new Uint8Array(sdfImageData.data.buffer),
    pixelRatio: images[0].image.pixelRatio,
  };
}

const generatedImages = {};
/**
 * Async function is not actually supported by Maplibre GL.
 * See https://github.com/mapbox/mapbox-gl-js/issues/9018 and https://maplibre.org/maplibre-gl-js/docs/examples/display-a-remote-svg-symbol/ (displays a warning)
 */
async function generateImage(maps, ids) {
  const rawImageIds = ids.startsWith('sdf:') ? ids.substr(4) : ids

  // Ensure every image is generated only once
  if (!generatedImages[rawImageIds]) {
    generatedImages[rawImageIds] = true;

    const imageIds = rawImageIds.split('|')
    if (!imageIds) {
      console.warn(`ignoring invalid missing image: ${rawImageIds}`);
      return;
    }

    console.info(`Generating image for ${rawImageIds}. MapLibre GL JS will log a warning below because it does not support async image loading yet.`)

    // Compose the images together into a normal image and SDF image
    const {width, height, imageData, sdfImageData, pixelRatio} = await composeImages(imageIds)

    maps.forEach(map => {
      map.addImage(rawImageIds, {width, height, data: imageData}, {pixelRatio, sdf: false});
      map.addImage(`sdf:${rawImageIds}`, {width, height, data: sdfImageData}, {pixelRatio, sdf: true});
    })
  }
}

const defaultConfiguration = {
  backgroundSaturation: 0.0,
  backgroundOpacity: 0.35,
  backgroundHillShade: false,
  backgroundType: 'raster',
  backgroundUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  theme: 'system',
  editor: 'id',
  view: {},
  stationLowZoomLabel: 'label'
};
let configuration = readConfiguration(localStorage);
configuration = migrateConfiguration(localStorage, configuration);

const coordinateFactor = legendZoom => Math.pow(2, 5 - legendZoom);

const legendPointToMapPoint = (zoom, [x, y]) =>
  [x * coordinateFactor(zoom), y * coordinateFactor(zoom)]

const mapStyles = Object.fromEntries(
  Object.values(knownStyles)
    .flatMap(style => Object.values(style.styles))
    .map(style => [style, `${location.origin}/style/${style}.json`])
);

const legendStyles = Object.fromEntries(
  Object.values(knownStyles)
    .flatMap(style => Object.values(style.styles))
    .map(style => [style, `${location.origin}/style/legend-${style}.json`])
);

const legendMap = new maplibregl.Map({
  container: 'legend-map',
  zoom: 5,
  center: [0, 0],
  attributionControl: false,
  interactive: false,
  // See https://github.com/maplibre/maplibre-gl-js/issues/3503
  maxCanvasSize: [Infinity, Infinity],
});

const backgroundMap = new maplibregl.Map({
  container: 'background-map',
  style: buildBackgroundMapStyle(),
  attributionControl: false,
  interactive: false,
  renderWorldCopies: false,
  ...(configuration.view || defaultConfiguration.view),
  // Ensure the background map loads using the hash, but does not update it whenever the map is updated.
  ...determineZoomCenterFromHash(window.location.hash),
});

updateBackgroundMapContainer();

const map = new maplibregl.Map({
  container: 'map',
  hash: 'view',
  minZoom: globalMinZoom,
  maxZoom: globalMaxZoom,
  minPitch: 0,
  maxPitch: 0,
  attributionControl: false,
  renderWorldCopies: false,
  ...(configuration.view || defaultConfiguration.view),
});

function selectStyle(style) {
  if (selectedStyle !== style) {
    selectedStyle = style;
    styleControl.onExternalStyleChange(style);
    onStyleChange();
  }
}

function selectDate(date) {
  if (selectedDate !== date) {
    selectedDate = date;
    dateControl.onExternalDateChange(date);
    onDateChange();
  }
}

function onPageParametersChange() {
  // Update URL
  const updatedHash = putParametersInHash(window.location.hash, selectedStyle, selectedDate);
  if (window.location.hash !== updatedHash) {
    const location = window.location.href.replace(/(#.+)?$/, updatedHash);
    window.history.replaceState(window.history.state, null, location);
  }
}

// See https://github.com/maplibre/maplibre-gl-js/issues/182#issuecomment-2462045216
// Rewrite paths to default to the current origin
function rewriteStylePathsToOrigin(style) {
  style.sources = Object.fromEntries(
    Object.entries(style.sources)
      .map(([key, source]) => [
        key,
        source && source.url && source.url.startsWith('/')
          ? ({...source, url: `${location.origin}${source.url}` })
          : source
      ])
  )

  style.glyphs = style.glyphs && style.glyphs.startsWith('/')
    ? `${location.origin}${style.glyphs}`
    : style.glyphs

  style.sprite = style.sprite
    .map(sprite =>
      sprite.url && sprite.url.startsWith('/')
        ? ({...sprite, url: `${location.origin}${sprite.url}` })
        : sprite
    )
}

// Rewrite source URLs to append the language query parameter
function addLanguageToSupportedSources(style) {
  style.sources = Object.fromEntries(
    Object.entries(style.sources)
      .map(([key, source]) => {
        if (source && source.url && ((source.metadata ?? {}).supports ?? []).includes('language')) {
          const parsedUrl = new URL(source.url)
          parsedUrl.searchParams.set('lang', locale.language)
          return [
            key,
            {
              ...source,
              url: parsedUrl.href,
            }
          ];
        } else {
          return [key, source]
        }
      })
  )
}

// Provide global state defaults as configured by the user
// Subsequent global state changes are applied directly to the map with setGlobalStateProperty
function rewriteGlobalStateDefaults(style) {
  style.state.date.default = selectedDate;
  style.state.theme.default = selectedTheme;
  style.state.stationLowZoomLabel.default = configuration.stationLowZoomLabel ?? defaultConfiguration.stationLowZoomLabel;
}

function toggleHillShadeLayer(style) {
  const hillshadeVisible = configuration.backgroundHillShade ?? defaultConfiguration.backgroundHillShade
  const layer = style.layers.find(layer => layer.id === 'hillshade')
  if (layer) {
    layer.layout = {
      ...layer.layout,
      visibility: hillshadeVisible ? 'visible' : 'none'
    }
  }
}

let lastSetMapStyle = null;
const onStyleChange = () => {
  const supportsDate = knownStyles[selectedStyle].styles.date;
  const dateActive = supportsDate && dateControl.active;
  const mapStyle = dateActive
    ? knownStyles[selectedStyle].styles.date
    : knownStyles[selectedStyle].styles.default

  if (mapStyle !== lastSetMapStyle) {
    lastSetMapStyle = mapStyle;

    // Change styles
    map.setStyle(mapStyles[mapStyle], {
      validate: false,
      transformStyle: (previous, next) => {
        rewriteStylePathsToOrigin(next)
        addLanguageToSupportedSources(next)
        rewriteGlobalStateDefaults(next)
        toggleHillShadeLayer(next)
        return next;
      },
    });

    legendMap.setStyle(legendStyles[mapStyle], {
      validate: false,
      // Do not calculate a diff because of the large structural layer differences causing a blocking performance hit
      diff: false,
      transformStyle: (previous, next) => {
        rewriteStylePathsToOrigin(next)
        rewriteGlobalStateDefaults(next)
        onStylesheetChange(next);
        return next;
      },
    });
  }

  if (supportsDate && !dateControl.isShown()) {
    dateControl.show();
  } else if (!supportsDate && dateControl.isShown()) {
    dateControl.hide();
  }

  onPageParametersChange();
}

const onDateChange = () => {
  map.setGlobalStateProperty('date', selectedDate);
  onPageParametersChange();
}

class StyleControl {
  constructor(options) {
    this.options = options
    this.buttons = {};
  }

  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group maplibregl-ctrl-group-style');
    const buttonGroup = createDomElement('div', 'maplibregl-ctrl-style', this._container);

    Object.entries(knownStyles).forEach(([style, {name}]) => {
      const button = createDomElement('button', '', buttonGroup);
      button.innerText = name
      button.onclick = () => {
        buttonGroup.classList.remove('active')
        this.activateStyle(style);
        this.options.onStyleChange(style)
      }

      this.buttons[style] = button;
    });

    const container = createDomElement('button', 'maplibregl-ctrl-style-toggle d-md-none', this._container);
    container.onclick = () => {
      buttonGroup.classList.toggle('active')
    };
    const icon = createDomElement('span', 'maplibregl-ctrl-icon', container);
    icon.title = 'Select map style'

    this.activateStyle(selectedStyle);

    return this._container;
  }

  activateStyle(style) {
    Object.entries(this.buttons).forEach(([buttonStyle, button]) => {
      if (buttonStyle === style) {
        button.classList.add('active')
      } else {
        button.classList.remove('active')
      }
    })
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }

  onExternalStyleChange(style) {
    const radio = this.buttons[style];
    if (radio && !radio.checked) {
      radio.checked = true;
    }
  }
}

class DateControl {
  constructor(options) {
    this.options = options;
  }

  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group maplibregl-ctrl-date');
    const container = createDomElement('button', '', this._container);
    this.icon = createDomElement('span', 'maplibregl-ctrl-icon', container);
    this.icon.title = 'Toggle date selection'
    this.icon.onclick = () => {
      this.slider.classList.toggle('hide-mobile-show-desktop');
      this.slider.classList.toggle('show-mobile-hide-desktop');
      this.dateDisplay.classList.toggle('hide-mobile-show-desktop');
      this.dateDisplay.classList.toggle('show-mobile-hide-desktop');
    };
    this.slider = createDomElement('input', 'date-input hide-mobile-show-desktop', this._container);
    this.slider.type = 'range'
    this.slider.min = 1758
    this.slider.max = (new Date()).getFullYear()
    this.slider.step = 1
    this.slider.valueAsNumber = this.options.initialSelection;
    this.slider.onchange = () => {
      this.detectChanges();
      this.updateDisplay();
      this.options.onChange(this.slider.valueAsNumber);
    }
    this.slider.oninput = () => {
      this.detectChanges();
      this.updateDisplay();
    }
    this.dateDisplay = createDomElement('span', 'date-display hide-mobile-show-desktop', this._container);
    this.active = null;

    this.detectChanges();
    this.updateDisplay();

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }

  onExternalDateChange(date) {
    if (date && this.slider.valueAsNumber !== date) {
      this.slider.valueAsNumber = date;
      this.detectChanges();
      this.updateDisplay();
    }
  }

  isShown() {
    return this._container.style.visibility === 'visible';
  }

  show() {
    this._container.style.visibility = 'visible'
  }

  hide() {
    this._container.style.visibility = 'hidden'
  }

  detectChanges() {
    const previouslyActive = this.active;
    this.active = this.slider.valueAsNumber !== defaultDate;

    if (this.active === true && previouslyActive !== true) {
      this.icon.classList.add('active')
      this.dateDisplay.classList.add('active')
      this.options.onActivation()
    } else if (this.active === false && previouslyActive !== false) {
      this.icon.classList.remove('active')
      this.dateDisplay.classList.remove('active')
      this.options.onDeactivation();
    }
  }

  updateDisplay() {
    this.dateDisplay.innerText = this.active
      ? this.slider.value
      : 'present'
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
    createDomElement('span', 'maplibregl-ctrl-icon', button);
    const text = createDomElement('span', '', button);
    text.className = 'maplibregl-ctrl-icon-text d-none d-md-inline';
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
    button.onclick = _ => {
      const editor = configuration.editor ?? defaultConfiguration.editor
      if (editor === 'josm') {
        const bounds = this._map.getBounds();
        const josmUrl = `http://localhost:8111/load_and_zoom?left=${bounds.getWest()}&right=${bounds.getEast()}&top=${bounds.getNorth()}&bottom=${bounds.getSouth()}`
        openJOSM(josmUrl)
      } else {
        const domain = dateControl.active
          ? 'https://www.openhistoricalmap.org'
          : 'https://www.openstreetmap.org';

        window.open(`${domain}/edit#map=${Math.round(this._map.getZoom()) + 1}/${this._map.getCenter().lat}/${this._map.getCenter().lng}`, '_blank');
      }
    }
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
    createDomElement('span', 'maplibregl-ctrl-icon', button);
    const text = createDomElement('span', '', button);
    text.className = 'maplibregl-ctrl-icon-text d-none d-md-inline';
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
const legendEntriesCount = Object.fromEntries(
  Object.values(knownStyles)
    .flatMap(style => Object.values(style.styles))
    .map(key => [key, {}])
);

class AboutControl {
  constructor(options) {
    this.options = options;
    this._newsHash = null;
  }

  onAdd(map) {
    this._map = map;
    this._container = createDomElement('div', 'maplibregl-ctrl maplibregl-ctrl-group maplibregl-ctrl-group-about');

    const button = createDomElement('button', 'maplibregl-ctrl-news', this._container);
    button.type = 'button';
    button.title = 'Show/hide news';
    createDomElement('span', 'maplibregl-ctrl-icon', button);
    const text = createDomElement('span', undefined, button);
    text.className = 'maplibregl-ctrl-icon-text d-none d-md-inline';
    text.innerText = 'News'
    createDomElement('span', 'news-marker', button);

    button.onclick = () => {
      button.classList.remove('news-updated');
      this.options.onNewsToggle();
    }

    const aboutButton = createDomElement('button', 'maplibregl-ctrl-about', this._container);
    aboutButton.type = 'button';
    aboutButton.title = 'Show/hide about';
    createDomElement('span', 'maplibregl-ctrl-icon', aboutButton);
    const aboutText = createDomElement('span', undefined, aboutButton);
    aboutText.className = 'maplibregl-ctrl-icon-text d-none d-md-inline';
    aboutText.innerText = 'About'

    aboutButton.onclick = () => this.options.onAboutToggle();

    fetch(`${location.origin}/news.html`)
      .then(news => {
        // Attach news hash to the button
        this._newsHash = news.headers.get('x-content-hash');
        if (this._newsHash && !configuration.newsHash || this._newsHash !== configuration.newsHash) {
          button.classList.add('news-updated');
          console.info('News has been updated');
        }

        return news.text()
      })
      .then(news => newsContent.innerHTML = news)
      .catch(error => {
        console.error('Error loading news', error);
      })

    return this._container;
  }

  onRemove() {
    removeDomElement(this._container);
    this._map = undefined;
  }

  newsHash() {
    return this._newsHash;
  }
}

const dateControl = new DateControl({
  initialSelection: selectedDate,
  onChange: selectDate,
  onActivation: () => onStyleChange(),
  onDeactivation: () => onStyleChange(),
});
const styleControl = new StyleControl({
  initialSelection: selectedStyle,
  onStyleChange: selectStyle,
});
const navigationControl = new maplibregl.NavigationControl({
  showCompass: true,
  visualizePitch: false,
})
map.addControl(dateControl);
map.addControl(styleControl);
map.addControl(navigationControl);
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
map.addControl(new EditControl());
map.addControl(new ConfigurationControl());

map.addControl(new SearchControl(), 'top-left');

const attributionOptions = {
  compact: true,
  // The field below may be mutated to dynamically add the data freshness information to the existing control
  customAttribution: '<a href="https://maplibre.org/" target="_blank">MapLibre</a> | <a href="https://github.com/hiddewie/OpenRailwayMap-vector" target="_blank">&copy; OpenRailwayMap contributors</a> | <a href="https://www.openstreetmap.org/about" target="_blank">&copy; OpenStreetMap contributors</a>',
}
const attributionControl = new maplibregl.AttributionControl(attributionOptions)
map.addControl(attributionControl, 'bottom-right');
map.addControl(new maplibregl.ScaleControl({
  maxWidth: 150,
  unit: 'metric',
}), 'bottom-right');
const aboutControl = new AboutControl({
  onAboutToggle: toggleAbout,
  onNewsToggle: toggleNews,
});
map.addControl(aboutControl, 'bottom-right');

map.addControl(new LegendControl({
  onLegendToggle: toggleLegend,
}), 'bottom-left');

const onMapZoom = zoom => {
  // Ensure the legend does not zoom below zoom 6 to ensure the coordinates the legend map uses
  //   stay within the bounds of the earth.
  const legendZoom = Math.max(Math.floor(zoom), 6);
  const shownStyle = knownStyles[selectedStyle].styles.date && dateControl.active
    ? knownStyles[selectedStyle].styles.date
    : knownStyles[selectedStyle].styles.default
  const numberOfLegendEntries = legendEntriesCount[shownStyle][legendZoom] ?? 100;

  legendMap.jumpTo({
    zoom: legendZoom,
    center: legendPointToMapPoint(legendZoom, [1, -((numberOfLegendEntries - 1) / 2) * 0.6]),
  });
  legendMapContainer.style.height = `${numberOfLegendEntries * 27.5}px`;
}
const onMapRotate = bearing => {
  const rotated = Math.abs(bearing) >= 1;
  const rotatedShownOnIcon = navigationControl._compassIcon.classList.contains('rotated');
  if (rotated && !rotatedShownOnIcon) {
    navigationControl._compassIcon.classList.add('rotated');
  } else if (!rotated && rotatedShownOnIcon) {
    navigationControl._compassIcon.classList.remove('rotated');
  }
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

function openJOSM(josmUrl, osmType, osmId) {
  const selectString = (osmType && osmId) ? `&select=${osmType}${osmId}` : '';

  fetch(`${josmUrl}${selectString}`)
    .catch(error => {
      console.error('Error invoking JOSM remote control:', error)
    })
  }

function popupContent(feature) {
  const bounds = map.getBounds();
  const editor = configuration.editor ?? defaultConfiguration.editor;
  const properties = feature.properties;
  const layerSource = `${feature.source}${feature.sourceLayer ? `-${feature.sourceLayer}` : ''}`;

  const featureCatalog = features && features[layerSource];
  if (!featureCatalog) {
    console.warn(`Feature catalog "${layerSource}" not found for feature`, feature);
    return;
  }

  const featureProperty = featureCatalog.featureProperty || 'feature';

  const constructCatalogKey = propertyValue => ({
    // Remove the variable part of the property, and icon position to get the key
    catalogKey: propertyValue && typeof propertyValue === 'string' ? propertyValue.replace(/\{[^}]+}/, '{}').replace(/@([^|]+|$)/, '') : propertyValue,
    // Capture the variable part as well for display
    keyVariable: propertyValue && typeof propertyValue === 'string'
      ? propertyValue.match(/\{([^}]+)}/)?.[1]
      : null
  });
  const {catalogKey, keyVariable} = constructCatalogKey(properties[featureProperty]);

  const featureContent = featureCatalog.features && featureCatalog.features[catalogKey];
  if (!featureContent) {
    console.warn(`Could not determine feature description content for feature property "${featureProperty}" with key "${catalogKey}" in catalog "${layerSource}", feature:`, feature);
  }
  // Unique labels
  const labels = [...new Set((featureCatalog.labelProperties || []).map(labelProperty => properties[labelProperty]).filter(it => it))];
  const featureDescription = featureContent ? `${featureContent.name}${keyVariable ? ` (${keyVariable})` : ''}${featureContent.country ? ` ${getFlagEmoji(featureContent.country)}` : ''}` : null;

  const determineDefaultOsmType = (properties, featureContent) => {
    if (properties.osm_type) {
      return properties.osm_type === 'N' ? 'node' : properties.osm_type == 'R' ? 'relation' : 'way';
    } else {
      const featureType = featureContent && featureContent.type || 'point';
      return featureType === 'point' ? 'node' : featureType === 'relation' ? 'relation' : 'way';
    }
  }

  const determineOsmFeatures = (properties, featureContent) => {
    const osmIds = properties.osm_id
      ? String(properties.osm_id).split('\u001e')
      : [];
    const defaultOsmType = determineDefaultOsmType(properties, featureContent);
    const osmTypes = properties.osm_type
      ? String(properties.osm_type).split('\u001e')
      : [];

    return osmIds.map((osm_id, index) => {
      const osmType = osmTypes && osmTypes.length > index
        ? osmTypes[index] === 'N' ? 'node' : osmTypes[index] === 'R' ? 'relation' : 'way'
        : defaultOsmType;

      return {
        id: osm_id,
        type: osmType,
      };
    })
  }

  const formatPropertyValue = (value, format) =>
    String(value)
      .split('\u001e')
      .map(stringValue => {
        if (!format) {
          return stringValue;
        } else if (format.template) {
          return format.template.replace('%s', () => stringValue).replace(/%(\.(\d+))?d/, (_1, _2, decimals) => Number(value).toFixed(Number(decimals)));
        } else if (format.lookup) {
          const lookupCatalog = features && features[format.lookup];
          if (!lookupCatalog) {
            console.warn('Lookup catalog', format.lookup, 'not found for feature', feature);
            return stringValue;
          } else {
            const {catalogKey: lookUpCatalogKey, keyVariable: lookUpKeyVariable} = constructCatalogKey(value);
            const lookedUpValue = lookupCatalog.features[lookUpCatalogKey];
            if (!lookedUpValue) {
              console.warn('Lookup catalog', format.lookup, 'did not contain value', value, 'for feature', feature);
              return stringValue;
            } else {
              return `${lookedUpValue.name}${lookUpKeyVariable ? ` (${lookUpKeyVariable})` : ''}${lookedUpValue.country ? ` ${getFlagEmoji(lookedUpValue.country)}` : ''}`;
            }
          }
        } else if (format.country_prefix) {
          if (stringValue && stringValue.length >= 3 && stringValue[2] == ':') {
            return `${getFlagEmoji(stringValue.substr(0, 2))} ${stringValue.substr(3)}`;
          } else {
            return stringValue;
          }
        } else {
          return stringValue;
        }
      })
      .join(', ');

  const propertyValues = Object.entries(featureCatalog.properties || {})
    .filter(([property, {name, format, link}]) => (properties[property] !== undefined && properties[property] !== null && properties[property] !== '' && properties[property] !== false))
    .map(([property, {name, format, link, paragraph, description}]) => ({
      title: name,
      value: properties[property],
      body: properties[property] === true ? '' : formatPropertyValue(properties[property], format),
      paragraph,
      link,
      tooltip: description,
    }));

  const osmFeatures = determineOsmFeatures(properties, featureContent);

  // Build HTML content dynamically to avoid cross site scripting

  const popupContainer = createDomElement('div');

  const popupTitle = createDomElement('h5', undefined, popupContainer);
  popupTitle.innerText = featureDescription;

  if (properties.icon || labels.length > 0) {
    const popupLabel = createDomElement('h6', undefined, popupContainer);
    if (properties.icon) {
      const popupLabelSpan = createDomElement('span', undefined, popupLabel);
      popupLabelSpan.title = properties.railway;
      popupLabelSpan.innerText = properties.icon;
    } else {
      popupLabel.innerText = labels.join(' • ');
    }
  }

  const popupOsmIds = createDomElement('h6', undefined, popupContainer);
  osmFeatures.forEach(({id, type}) => {
    const osmIdContainer = createDomElement('div', 'btn-group btn-group-sm', popupOsmIds);

    const osmIdButton = createDomElement('button', 'btn btn-outline-secondary', osmIdContainer);
    osmIdButton.type = 'button'
    osmIdButton.disabled = 'disabled';

    const osmTypeContent = createDomElement('img', 'osm-type-icon', osmIdButton);
    osmTypeContent.src = icons.osm[type];
    osmTypeContent.alt = type;

    const osmIdContent = createDomElement('code', undefined, osmIdButton);
    osmIdContent.innerText = id;

    const osmIdLink = createDomElement('a', 'btn btn-outline-primary', osmIdContainer);
    osmIdLink.title = 'View source'
    osmIdLink.href = featureCatalog.featureLinks.view.replace('{osm_type}', type).replace('{osm_id}', id).replace('{date}', String(selectedDate))
    osmIdLink.target = '_blank'
    osmIdLink.innerText = 'View'

    if (editor === 'josm') {
      const editButton = createDomElement('div', 'btn btn-outline-primary', osmIdContainer);
      editButton.title = 'Edit Source'
      editButton.onclick = () => openJOSM(`http://localhost:8111/load_and_zoom?left=${bounds.getWest()}&right=${bounds.getEast()}&top=${bounds.getNorth()}&bottom=${bounds.getSouth()}`, type, id)
      editButton.innerText = 'Edit'
    } else {
      const editButton = createDomElement('a', 'btn btn-outline-primary', osmIdContainer);
      editButton.title = 'Edit Source'
      editButton.href = featureCatalog.featureLinks.edit.replace('{osm_type}', type).replace('{osm_id}', id).replace('{date}', String(selectedDate))
      editButton.target = '_blank'
      editButton.innerText = 'Edit'
    }
  })

  // Images are not output as properties
  if (properties.wikidata || properties.wikimedia_commons_file || properties.image) {
    const popupImageContainer = createDomElement('p', undefined, popupContainer);

    if (properties.wikidata) {
      const popupImageLink = createDomElement('a', undefined, popupImageContainer)
      popupImageLink.href = `https://www.wikidata.org/wiki/${encodeURIComponent(properties.wikidata)}`
      popupImageLink.target = '_blank'
      popupImageLink.alt = `Wikidata: ${properties.wikidata}`

      const popupImage = createDomElement('img', 'popup-image', popupImageLink);
      popupImage.src = `/api/wikidata/${encodeURIComponent(properties.wikidata)}`
      popupImage.title = properties.wikidata
      popupImage.alt = `Wikidata: ${properties.wikidata}`
      popupImage.style.display = 'none' // Do not display images that cannot load
      popupImage.onload = () => popupImage.style.display = 'block'
    }

    if (properties.wikimedia_commons_file) {
      const sanitizedName = properties.wikimedia_commons_file.replaceAll(' ', '_');
      const nameHash = MD5(sanitizedName)
      const wikimediaUrl = `https://upload.wikimedia.org/wikipedia/commons/thumb/${nameHash.substr(0, 1)}/${nameHash.substr(0, 2)}/${encodeURIComponent(sanitizedName)}/330px-${encodeURIComponent(sanitizedName)}`
      const popupImageLink = createDomElement('a', undefined, popupImageContainer)
      popupImageLink.href = `https://commons.wikimedia.org/wiki/File:${encodeURIComponent(properties.wikimedia_commons_file)}#/media/File:${encodeURIComponent(properties.wikimedia_commons_file)}`
      popupImageLink.target = '_blank'
      popupImageLink.alt = `Wikimedia Commons file: ${properties.wikimedia_commons_file}`

      const popupImage = createDomElement('img', 'popup-image', popupImageLink);
      popupImage.src = wikimediaUrl
      popupImage.title = properties.wikimedia_commons_file
      popupImage.alt = `Wikimedia Commons file: ${properties.wikimedia_commons_file}`
      popupImage.style.display = 'none' // Do not display images that cannot load
      popupImage.onload = () => popupImage.style.display = 'block'
    }

    if (properties.image) {
      const popupImageLink = createDomElement('a', undefined, popupImageContainer);
      popupImageLink.href = properties.image
      popupImageLink.target = '_blank'
      popupImageLink.alt = `Image: ${properties.image}`

      const popupImage = createDomElement('img', 'popup-image', popupImageLink);
      popupImage.src = properties.image
      popupImage.title = properties.image
      popupImage.alt = `Image: ${properties.image}`
      popupImage.style.display = 'none' // Do not display images that cannot load
      popupImage.onload = () => popupImage.style.display = 'block'
    }
  }

  if (propertyValues.some(it => !it.paragraph)) {
    const popupValuesContainer = createDomElement('h6', undefined, popupContainer);
    propertyValues
      .filter(it => !it.paragraph)
      .forEach(({title, body, value, link, tooltip}) => {
        const popupValue = createDomElement('span', 'badge rounded-pill text-bg-light', popupValuesContainer);
        if (tooltip) {
          popupValue.title = tooltip;
          popupValue.style.cursor = 'help';
        }

        const popupValueTitle = createDomElement('span', 'fw-bold', popupValue);
        popupValueTitle.innerText = title;

        if (body) {
          if (link) {
            const popupValueBody = createDomElement('span', undefined, popupValue);
            const popupValueColon = createDomElement('span', undefined, popupValueBody);
            popupValueColon.innerText = ': ';
            const popupValueLink = createDomElement('a', undefined, popupValueBody);
            popupValueLink.href = link.replace('%s', () => encodeURIComponent(String(value)))
            popupValueLink.target = '_blank'
            const popupValueText = createDomElement('span', undefined, popupValueLink);
            popupValueText.innerText = body;
          } else {
            const popupValueBody = createDomElement('span', undefined, popupValue);
            popupValueBody.innerText = `: ${body}`;
          }
        }
      })
  }

  if (propertyValues.some(it => it.paragraph)) {
    const popupValuesContainer = createDomElement('div', undefined, popupContainer);
    propertyValues
      .filter(it => it.paragraph)
      .forEach(({title, body}) => {
        const popupParagraph = createDomElement('p', undefined, popupValuesContainer);

        const popupValueTitle = createDomElement('span', 'fw-bold', popupParagraph);
        popupValueTitle.innerText = title;

        if (body) {
          // Paragraph bodies do not support links
          const popupValueBody = createDomElement('span', undefined, popupParagraph);
          popupValueBody.innerText = `: ${body}`;
        }
      })
  }

  return popupContainer
}

map.on('load', () => onMapZoom(map.getZoom()));
map.on('zoomend', () => onMapZoom(map.getZoom()));
map.on('move', () => backgroundMap.jumpTo({center: map.getCenter(), zoom: map.getZoom(), bearing: map.getBearing()}));
map.on('zoom', () => backgroundMap.jumpTo({center: map.getCenter(), zoom: map.getZoom(), bearing: map.getBearing()}));
map.on('zoomend', () => updateConfiguration('view', {center: map.getCenter(), zoom: map.getZoom(), bearing: map.getBearing()}));
map.on('moveend', () => updateConfiguration('view', {center: map.getCenter(), zoom: map.getZoom(), bearing: map.getBearing()}));
map.on('rotate', () => onMapRotate(map.getBearing()));
map.on('styleimagemissing', event => generateImage([map, legendMap], event.id));
legendMap.on('styleimagemissing', event => generateImage([map, legendMap], event.id));

function formatTimespan(timespan) {
  if (timespan < 60 * 1000) {
    return '< 1 minute'
  } else if (timespan < 1.5 * 60 * 1000) {
    return '1 minute'
  } else if (timespan < 60 * 60 * 1000) {
    return `${Math.floor(timespan / (60 * 1000))} minutes`
  } else if (timespan < 1.5 * 60 * 60 * 1000) {
    return '1 hour'
  } else if (timespan < 24 * 60 * 60 * 1000) {
    return `${Math.floor(timespan / (60 * 60 * 1000))} hours`
  } else if (timespan < 1.5 * 24 * 60 * 60 * 1000) {
    return '1 day'
  } else {
    return `${Math.floor(timespan / (24 * 60 * 60 * 1000))} days`
  }
}

fetch(`${origin}/api/replication_timestamp`)
  .then(response => response.json())
  .then(source => {
    if (source.replication_timestamp) {
      const timestamp = new Date(source.replication_timestamp)
      const timespan = new Date().getTime() - timestamp.getTime();

      attributionOptions.customAttribution = `${attributionOptions.customAttribution} &mdash; data updated <abbr title="${timestamp}">${formatTimespan(timespan)} ago</abbr>`

      // Forcefully update the control, even if the map does not fire events.
      attributionControl._updateAttributions();
    }
  })
  .catch(error => console.error('Error while fetching tile metadata', error));

let hoveredFeature = null
map.on('mousemove', event => {
  const features = map.queryRenderedFeatures(event.point);
  if (features.length > 0) {
    map.getCanvas().style.cursor = 'pointer';

    const feature = features[0];
    if (hoveredFeature && hoveredFeature.id !== feature.id) {
      map.setFeatureState(hoveredFeature, {hover: false});
      hoveredFeature = null;
    }

    if (feature.id && !(hoveredFeature && hoveredFeature.id === feature.id)) {
      hoveredFeature = {source: feature.source, sourceLayer: feature.sourceLayer, id: feature.id}
      map.setFeatureState(hoveredFeature, {hover: true});
    }
  } else {
    map.getCanvas().style.cursor = '';

    if (hoveredFeature) {
      map.setFeatureState(hoveredFeature, {hover: false});
      hoveredFeature = null;
    }
  }
});

function closestPointOnLine(point, line) {
  const lngLatPoint = maplibregl.LngLat.convert(point)
  let {closest0, closest1} = line.map(maplibregl.LngLat.convert).reduce((acc, cur) => {
    const d = lngLatPoint.distanceTo(cur)
    if (acc.closest0 == null || d < lngLatPoint.distanceTo(acc.closest0)) {
      return {closest0: cur, closest1: acc.closest0}
    } else if (acc.closest1 == null || d < lngLatPoint.distanceTo(acc.closest1)) {
      return {closest0: acc.closest0, closest1: cur}
    } else {
      return acc;
    }
  }, {closest0: null, closest1: null});

  closest0 = closest0.toArray()
  closest1 = closest1.toArray()
  point = lngLatPoint.toArray()

  if (closest0 == null && closest1 == null) {
    return null;
  } else if (closest1 == null) {
    return closest0;
  } else {
    // project point onto line between closest0 and closest1
    const abx = closest1[0] - closest0[0]
    const aby = closest1[1] - closest0[1]
    const acx = point[0] - closest0[0]
    const acy = point[1] - closest0[1]
    const coeff = (abx * acx + aby * acy) / (abx * abx + aby * aby)
    return [closest0[0] + abx * coeff, closest0[1] + aby * coeff]
  }
}

let popup = null;
map.on('click', event => {
  const features = map.queryRenderedFeatures(event.point);
  if (features.length > 0) {
    const feature = features[0];

    const coordinates = feature.geometry.type === 'Point'
      ? feature.geometry.coordinates.slice()
      : feature.geometry.type === 'LineString'
        ? closestPointOnLine(event.lngLat, feature.geometry.coordinates)
        : event.lngLat;

    const iconHeight = 20;
    const iconWidth = 10;
    const popupOffsets = {
      'top': [0, iconHeight],
      'top-left': [iconWidth, iconHeight],
      'top-right': [-iconWidth, iconHeight],
      'bottom': [0, -iconHeight],
      'bottom-left': [iconWidth, -iconHeight],
      'bottom-right': [-iconWidth, -iconHeight],
      'left': [iconWidth, 0],
      'right': [-iconWidth, 0]
    }

    if (popup) {
      popup.remove();
    }

    popup = new maplibregl.Popup({offset: popupOffsets})
      .setLngLat(coordinates)
      .setDOMContent(popupContent(feature))
      .addTo(map);
  }
});

let features = null;
fetch(`${location.origin}/features.json`)
  .then(result => {
    if (result.status === 200) {
      return result.json()
    } else {
      throw `Invalid status code ${result.status}`
    }
  })
  .then(result => {
    console.info('Loaded features');
    features = result;
  })
  .catch(error => console.error('Error during fetching of features', error))

updateTheme();
onStyleChange();
onMapRotate(map.getBearing());
