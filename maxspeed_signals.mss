#railway_signals {
  [zoom>=17] {
  /*  */
    ["feature"="DE-ESO:db:zs10"]["signal_speed_limit_speed"="none"] {
      ["signal_speed_limit_form"="sign"] {
        marker-allow-overlap: true;
        marker-file: url('symbols/de/zs10-sign.svg');
        marker-width: 7;
        marker-height: 22;
      }

      ["signal_speed_limit_form"="light"] {
        marker-allow-overlap: true;
        marker-file: url('symbols/de/zs10-light.svg');
        marker-width: 10;
        marker-height: 22;
      }
    }

    /* German speed signals (Zs 3v) as signs */
    ["feature"="DE-ESO:zs3v"]["signal_speed_limit_distant_form"="sign"] {
      ["signal_speed_limit_distant_speed"=null],
      ["signal_speed_limit_distant_speed"=~"^(1[0-6]|[1-9])0$"] {
        marker-width: 22;
        marker-height: 19;
        marker-allow-overlap: true;
      }
      ["signal_speed_limit_distant_speed"=null] {
        marker-file: url('symbols/de/zs3v-empty-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="10"] {
        marker-file: url('symbols/de/zs3v-10-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="20"] {
        marker-file: url('symbols/de/zs3v-20-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/de/zs3v-30-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="40"] {
        marker-file: url('symbols/de/zs3v-40-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="50"] {
        marker-file: url('symbols/de/zs3v-50-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="60"] {
        marker-file: url('symbols/de/zs3v-60-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="70"] {
        marker-file: url('symbols/de/zs3v-70-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="80"] {
        marker-file: url('symbols/de/zs3v-80-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="90"] {
        marker-file: url('symbols/de/zs3v-90-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="100"] {
        marker-file: url('symbols/de/zs3v-100-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="110"] {
        marker-file: url('symbols/de/zs3v-110-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="120"] {
        marker-file: url('symbols/de/zs3v-120-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="130"] {
        marker-file: url('symbols/de/zs3v-130-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="140"] {
        marker-file: url('symbols/de/zs3v-140-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="150"] {
        marker-file: url('symbols/de/zs3v-150-sign-down.svg');
      }
    }

    /* German speed signals (Zs 3v) as light signals */
    ["feature"="DE-ESO:zs3v"]["signal_speed_limit_distant_form"="light"] {
      ["signal_speed_limit_distant_speed"=null],
      ["signal_speed_limit_distant_speed"="^off;\?$"],
      ["signal_speed_limit_distant_speed"=~"^(1[0-2]|[2-9])0$"] {
        marker-allow-overlap: true;
        marker-width: 14;
        marker-height: 19;
      }
      ["signal_speed_limit_distant_speed"=null],
      ["signal_speed_limit_distant_speed"="^off;\?$"] {
        marker-file: url('symbols/de/zs2v-unknown.svg'); /* */
      }
      ["signal_speed_limit_distant_speed"="20"] {
        marker-file: url('symbols/de/zs3v-20-light.svg');
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/de/zs3v-30-light.svg');
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/de/zs3v-30-light.svg');
      }
      ["signal_speed_limit_distant_speed"="40"] {
        marker-file: url('symbols/de/zs3v-40-light.svg');
      }
      ["signal_speed_limit_distant_speed"="50"] {
        marker-file: url('symbols/de/zs3v-50-light.svg');
      }
      ["signal_speed_limit_distant_speed"="60"] {
        marker-file: url('symbols/de/zs3v-60-light.svg');
      }
      ["signal_speed_limit_distant_speed"="70"] {
        marker-file: url('symbols/de/zs3v-70-light.svg');
      }
      ["signal_speed_limit_distant_speed"="80"] {
        marker-file: url('symbols/de/zs3v-80-light.svg');
      }
      ["signal_speed_limit_distant_speed"="90"] {
        marker-file: url('symbols/de/zs3v-90-light.svg');
      }
      ["signal_speed_limit_distant_speed"="100"] {
        marker-file: url('symbols/de/zs3v-100-light.svg');
      }
      ["signal_speed_limit_distant_speed"="110"] {
        marker-file: url('symbols/de/zs3v-110-light.svg');
      }
      ["signal_speed_limit_distant_speed"="120"] {
        marker-file: url('symbols/de/zs3v-120-light.svg');
      }
    }

    /* Austrian speed signals (Geschwindigkeitsvoranzeiger) as signs */
    ["feature"="AT-V2:geschwindigkeitsvoranzeiger"]["signal_speed_limit_distant_form"="sign"] {
      ["signal_speed_limit_distant_speed"=~"^(10|[1-9])0$"] {
        marker-allow-overlap: true;
        marker-width: 22;
        marker-height: 19;
      }
      ["signal_speed_limit_distant_speed"="10"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-10-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="20"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-20-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-30-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="40"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-40-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="50"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-50-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="60"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-60-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="70"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-70-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="80"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-80-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="90"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-90-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="100"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-100-sign.svg');
      }
    }

    /* Austrian speed signals (Geschwindigkeitsvoranzeiger) as light signals */
    ["feature"="AT-V2:geschwindigkeitsvoranzeiger"]["signal_speed_limit_distant_form"="light"] {
      ["signal_speed_limit_distant_speed"=~"^(1[0-2]|[3-9])0$"] {
        marker-allow-overlap: true;
        marker-width: 14;
        marker-height: 14;
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-30-light.svg');
      }
      ["signal_speed_limit_distant_speed"="40"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-40-light.svg');
      }
      ["signal_speed_limit_distant_speed"="50"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-50-light.svg');
      }
      ["signal_speed_limit_distant_speed"="60"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-60-light.svg');
      }
      ["signal_speed_limit_distant_speed"="70"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-70-light.svg');
      }
      ["signal_speed_limit_distant_speed"="80"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-80-light.svg');
      }
      ["signal_speed_limit_distant_speed"="90"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-90-light.svg');
      }
      ["signal_speed_limit_distant_speed"="100"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-100-light.svg');
      }
      ["signal_speed_limit_distant_speed"="120"] {
        marker-file: url('symbols/at/geschwindigkeitsvoranzeiger-120-light.svg');
      }
    }

    /* German speed signals (Zs 3) as signs */
    ["feature"="DE-ESO:zs3"]["signal_speed_limit_form"="sign"] {
      ["signal_speed_limit_speed"=~"^(1[0-6]|[1-9])0$"],
      ["signal_speed_limit_speed"=null] {
        marker-allow-overlap: true;
        marker-width: 22;
        marker-height: 19;
      }
      ["signal_speed_limit_speed"=null] {
        marker-file: url('symbols/de/zs3-empty-sign-up.svg');
      }
      ["signal_speed_limit_speed"="10"] {
        marker-file: url('symbols/de/zs3-10-sign-up.svg');
      }
      ["signal_speed_limit_speed"="20"] {
        marker-file: url('symbols/de/zs3-20-sign-up.svg');
      }
      ["signal_speed_limit_speed"="30"] {
        marker-file: url('symbols/de/zs3-30-sign-up.svg');
      }
      ["signal_speed_limit_speed"="40"] {
        marker-file: url('symbols/de/zs3-40-sign-up.svg');
      }
      ["signal_speed_limit_speed"="50"] {
        marker-file: url('symbols/de/zs3-50-sign-up.svg');
      }
      ["signal_speed_limit_speed"="60"] {
        marker-file: url('symbols/de/zs3-60-sign-up.svg');
      }
      ["signal_speed_limit_speed"="70"] {
        marker-file: url('symbols/de/zs3-70-sign-up.svg');
      }
      ["signal_speed_limit_speed"="80"] {
        marker-file: url('symbols/de/zs3-80-sign-up.svg');
      }
      ["signal_speed_limit_speed"="90"] {
        marker-file: url('symbols/de/zs3-90-sign-up.svg');
      }
      ["signal_speed_limit_speed"="100"] {
        marker-file: url('symbols/de/zs3-100-sign-up.svg');
      }
      ["signal_speed_limit_speed"="110"] {
        marker-file: url('symbols/de/zs3-110-sign-up.svg');
      }
      ["signal_speed_limit_speed"="120"] {
        marker-file: url('symbols/de/zs3-120-sign-up.svg');
      }
      ["signal_speed_limit_speed"="130"] {
        marker-file: url('symbols/de/zs3-130-sign-up.svg');
      }
      ["signal_speed_limit_speed"="140"] {
        marker-file: url('symbols/de/zs3-140-sign-up.svg');
      }
      ["signal_speed_limit_speed"="150"] {
        marker-file: url('symbols/de/zs3-150-sign-up.svg');
      }
      ["signal_speed_limit_speed"="160"] {
        marker-file: url('symbols/de/zs3-160-sign-up.svg');
      }
    }

    /* German speed signals (Zs 3) as light signals */
    ["feature"="DE-ESO:zs3"]["signal_speed_limit_form"="light"] {
      ["signal_speed_limit_speed"=null],
      ["signal_speed_limit_speed"="^off;\?$"],
      ["signal_speed_limit_speed"=~"^(1[0-2]|[2-9])0$"] {
        marker-width: 14;
        marker-height: 19;
        marker-allow-overlap: true;
      }
      ["signal_speed_limit_speed"=null],
      ["signal_speed_limit_speed"="^off;\?$"] {
        marker-file: url('symbols/de/zs2-unknown.svg'); /* for light signals: empty Zs3 "looks" exactly like empty Zs2 */
      }
      ["signal_speed_limit_speed"="20"] {
        marker-file: url('symbols/de/zs3-20-light.svg');
      }
      ["signal_speed_limit_speed"="30"] {
        marker-file: url('symbols/de/zs3-30-light.svg');
      }
      ["signal_speed_limit_speed"="40"] {
        marker-file: url('symbols/de/zs3-40-light.svg');
      }
      ["signal_speed_limit_speed"="50"] {
        marker-file: url('symbols/de/zs3-50-light.svg');
      }
      ["signal_speed_limit_speed"="60"] {
        marker-file: url('symbols/de/zs3-60-light.svg');
      }
      ["signal_speed_limit_speed"="70"] {
        marker-file: url('symbols/de/zs3-70-light.svg');
      }
      ["signal_speed_limit_speed"="80"] {
        marker-file: url('symbols/de/zs3-80-light.svg');
      }
      ["signal_speed_limit_speed"="90"] {
        marker-file: url('symbols/de/zs3-90-light.svg');
      }
      ["signal_speed_limit_speed"="100"] {
        marker-file: url('symbols/de/zs3-100-light.svg');
      }
      ["signal_speed_limit_speed"="110"] {
        marker-file: url('symbols/de/zs3-110-light.svg');
      }
      ["signal_speed_limit_speed"="120"] {
        marker-file: url('symbols/de/zs3-120-light.svg');
      }
    }

    /* Austrian speed signals (Geschwindigkeitsanzeiger)*/
    ["feature"="AT-V2:geschwindigkeitsanzeiger"]["signal_speed_limit_form"="sign"] {
      ["signal_speed_limit_speed"=~"^(1[0-26]|[1-9])0$"] {
        marker-allow-overlap: true;
        marker-width: 14;
        marker-height: 14;
      }
      ["signal_speed_limit_speed"="10"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-10-sign.svg');
      }
      ["signal_speed_limit_speed"="20"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-20-sign.svg');
      }
      ["signal_speed_limit_speed"="30"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-30-sign.svg');
      }
      ["signal_speed_limit_speed"="40"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-40-sign.svg');
      }
      ["signal_speed_limit_speed"="50"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-50-sign.svg');
      }
      ["signal_speed_limit_speed"="60"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-60-sign.svg');
      }
      ["signal_speed_limit_speed"="70"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-70-sign.svg');
      }
      ["signal_speed_limit_speed"="80"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-80-sign.svg');
      }
      ["signal_speed_limit_speed"="90"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-90-sign.svg');
      }
      ["signal_speed_limit_speed"="100"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-100-sign.svg');
      }
      ["signal_speed_limit_speed"="110"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-110-sign.svg');
      }
      ["signal_speed_limit_speed"="120"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-120-sign.svg');
      }
      ["signal_speed_limit_speed"="160"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-160-sign.svg');
      }
    }
    ["feature"="AT-V2:geschwindigkeitsanzeiger"]["signal_speed_limit_form"="light"] {
      ["signal_speed_limit_speed"=~"^(1[02]|[3-9])0$"] {
        marker-allow-overlap: true;
        marker-width: 14;
        marker-height: 14;
      }
      ["signal_speed_limit_speed"="30"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-30-light.svg');
      }
      ["signal_speed_limit_speed"="40"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-40-light.svg');
      }
      ["signal_speed_limit_speed"="50"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-50-light.svg');
      }
      ["signal_speed_limit_speed"="60"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-60-light.svg');
      }
      ["signal_speed_limit_speed"="70"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-70-light.svg');
      }
      ["signal_speed_limit_speed"="80"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-80-light.svg');
      }
      ["signal_speed_limit_speed"="90"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-90-light.svg');
      }
      ["signal_speed_limit_speed"="100"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-100-light.svg');
      }
      ["signal_speed_limit_speed"="120"] {
        marker-file: url('symbols/at/geschwindigkeitsanzeiger-120-light.svg');
      }
    }
  }

  [zoom>=14] {
    /* West German branch line speed signals (Lf 4 DS 301) */
    ["feature"="DE-ESO:db:lf4"]["signal_speed_limit_distant_form"="sign"] {
      ["signal_speed_limit_distant_speed"=~"^([2-8]0|1[05]|0)$"] {
        marker-allow-overlap: true;
        marker-width: 22;
        marker-height: 19;
      }
      ["signal_speed_limit_distant_speed"="0"] {
        marker-file: url('symbols/de/lf4-ds301-0-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="10"] {
        marker-file: url('symbols/de/lf4-ds301-10-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="15"] {
        marker-file: url('symbols/de/lf4-ds301-15-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="20"] {
        marker-file: url('symbols/de/lf4-ds301-20-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/de/lf4-ds301-30-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="40"] {
        marker-file: url('symbols/de/lf4-ds301-40-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="50"] {
        marker-file: url('symbols/de/lf4-ds301-50-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="60"] {
        marker-file: url('symbols/de/lf4-ds301-60-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="70"] {
        marker-file: url('symbols/de/lf4-ds301-70-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="80"] {
        marker-file: url('symbols/de/lf4-ds301-80-sign-down.svg');
      }
    }

    /* German line speed signals (Lf 6) */
    ["feature"="DE-ESO:lf6"]["signal_speed_limit_distant_form"="sign"] {
      ["signal_speed_limit_distant_speed"=~"^((1[0-9]|[1-9])0|5|15)$"] {
        marker-allow-overlap: true;
        marker-width: 22;
        marker-height: 19;
      }
      ["signal_speed_limit_distant_speed"="5"] {
        marker-file: url('symbols/de/lf6-5-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="10"] {
        marker-file: url('symbols/de/lf6-10-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="15"] {
        marker-file: url('symbols/de/lf6-15-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="20"] {
        marker-file: url('symbols/de/lf6-20-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/de/lf6-30-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="40"] {
        marker-file: url('symbols/de/lf6-40-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="50"] {
        marker-file: url('symbols/de/lf6-50-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="60"] {
        marker-file: url('symbols/de/lf6-60-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="70"] {
        marker-file: url('symbols/de/lf6-70-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="80"] {
        marker-file: url('symbols/de/lf6-80-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="90"] {
        marker-file: url('symbols/de/lf6-90-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="100"] {
        marker-file: url('symbols/de/lf6-100-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="110"] {
        marker-file: url('symbols/de/lf6-110-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="120"] {
        marker-file: url('symbols/de/lf6-120-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="130"] {
        marker-file: url('symbols/de/lf6-130-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="140"] {
        marker-file: url('symbols/de/lf6-140-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="150"] {
        marker-file: url('symbols/de/lf6-150-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="160"] {
        marker-file: url('symbols/de/lf6-160-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="170"] {
        marker-file: url('symbols/de/lf6-170-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="180"] {
        marker-file: url('symbols/de/lf6-180-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="190"] {
        marker-file: url('symbols/de/lf6-190-sign-down.svg');
      }
      ["signal_speed_limit_distant_speed"="200"] {
        marker-file: url('symbols/de/lf6-200-sign-down.svg');
      }
    }

    /* Austrian line speed signals (Ankündigungstafel) */
    ["feature"="AT-V2:ankündigungstafel"]["signal_speed_limit_distant_form"="sign"] {
      ["signal_speed_limit_distant_speed"=~"^(1[0-4]|[1-9])0$"] {
        marker-allow-overlap: true;
        marker-width: 22;
        marker-height: 19;
      }
      ["signal_speed_limit_distant_speed"="10"] {
        marker-file: url('symbols/at/ankuendigungstafel-10-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="20"] {
        marker-file: url('symbols/at/ankuendigungstafel-20-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/at/ankuendigungstafel-30-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="40"] {
        marker-file: url('symbols/at/ankuendigungstafel-40-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="50"] {
        marker-file: url('symbols/at/ankuendigungstafel-50-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="60"] {
        marker-file: url('symbols/at/ankuendigungstafel-60-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="70"] {
        marker-file: url('symbols/at/ankuendigungstafel-70-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="80"] {
        marker-file: url('symbols/at/ankuendigungstafel-80-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="90"] {
        marker-file: url('symbols/at/ankuendigungstafel-90-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="100"] {
        marker-file: url('symbols/at/ankuendigungstafel-100-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="110"] {
        marker-file: url('symbols/at/ankuendigungstafel-110-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="120"] {
        marker-file: url('symbols/at/ankuendigungstafel-120-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="130"] {
        marker-file: url('symbols/at/ankuendigungstafel-130-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="140"] {
        marker-file: url('symbols/at/ankuendigungstafel-140-sign.svg');
      }
    }

    ["feature"="DE-HHA:l1"]["signal_speed_limit_distant_form"="sign"] {
      ["signal_speed_limit_distant_speed"=~"^[3-7]0$"] {
        marker-allow-overlap: true;
        marker-width: 22;
        marker-height: 19;
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/de/hha/l1-30-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="40"] {
        marker-file: url('symbols/de/hha/l1-40-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="50"] {
        marker-file: url('symbols/de/hha/l1-50-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="60"] {
        marker-file: url('symbols/de/hha/l1-60-sign.svg');
      }
      ["signal_speed_limit_distant_speed"="70"] {
        marker-file: url('symbols/de/hha/l1-70-sign.svg');
      }
    }
  }

  [zoom>=15] {
    ["feature"="DE-BOStrab:g3"]["signal_speed_limit_form"="sign"] {
      marker-width: 11;
      marker-height: 16;
      marker-file: url('symbols/de/bostrab/g3.svg');
      marker-allow-overlap: true;
    }

    /* German tram distance speed limit signals as signs (G 1a) */
    ["feature"="DE-BOStrab:g1a"]["signal_speed_limit_distant_form"="sign"] {
      ["signal_speed_limit_distant_speed"=~"^[1-6]0$"],
      ["signal_speed_limit_distant_speed"=~"^[1-3]5$"] {
        marker-allow-overlap: true;
        marker-width: 22;
        marker-height: 19;
      }
      ["signal_speed_limit_distant_speed"="10"] {
        marker-file: url('symbols/de/bostrab/g1a-10.svg');
      }
      ["signal_speed_limit_distant_speed"="15"] {
        marker-file: url('symbols/de/bostrab/g1a-15.svg');
      }
      ["signal_speed_limit_distant_speed"="20"] {
        marker-file: url('symbols/de/bostrab/g1a-20.svg');
      }
      ["signal_speed_limit_distant_speed"="25"] {
        marker-file: url('symbols/de/bostrab/g1a-25.svg');
      }
      ["signal_speed_limit_distant_speed"="30"] {
        marker-file: url('symbols/de/bostrab/g1a-30.svg');
      }
      ["signal_speed_limit_distant_speed"="35"] {
        marker-file: url('symbols/de/bostrab/g1a-35.svg');
      }
      ["signal_speed_limit_distant_speed"="40"] {
        marker-file: url('symbols/de/bostrab/g1a-40.svg');
      }
      ["signal_speed_limit_distant_speed"="50"] {
        marker-file: url('symbols/de/bostrab/g1a-50.svg');
      }
      ["signal_speed_limit_distant_speed"="60"] {
        marker-file: url('symbols/de/bostrab/g1a-60.svg');
      }
    }

    /* German tram speed limit signals as signs (G 4) */
    ["feature"="DE-BOStrab:g4"]["signal_speed_limit_form"="sign"] {
      ["signal_speed_limit_speed"=~"^[2-7]0$"],
      ["signal_speed_limit_speed"=~"^[23]5$"] {
        marker-allow-overlap: true;
        marker-width: 11;
        marker-height: 16;
      }
      ["signal_speed_limit_speed"="20"] {
        marker-file: url('symbols/de/bostrab/g4-20.svg');
      }
      ["signal_speed_limit_speed"="25"] {
        marker-file: url('symbols/de/bostrab/g4-25.svg');
      }
      ["signal_speed_limit_speed"="30"] {
        marker-file: url('symbols/de/bostrab/g4-30.svg');
      }
      ["signal_speed_limit_speed"="35"] {
        marker-file: url('symbols/de/bostrab/g4-35.svg');
      }
      ["signal_speed_limit_speed"="40"] {
        marker-file: url('symbols/de/bostrab/g4-40.svg');
      }
      ["signal_speed_limit_speed"="50"] {
        marker-file: url('symbols/de/bostrab/g4-50.svg');
      }
      ["signal_speed_limit_speed"="60"] {
        marker-file: url('symbols/de/bostrab/g4-60.svg');
      }
      ["signal_speed_limit_speed"="70"] {
        marker-file: url('symbols/de/bostrab/g4-70.svg');
      }
    }

    /* German tram speed limit signals as signs (G 2a) */
    ["feature"="DE-BOStrab:g2a"]["signal_speed_limit_form"="sign"] {
      ["signal_speed_limit_speed"=~"^([1-3]?5|[1-6]0)$"] {
        marker-allow-overlap: true;
        marker-width: 11;
        marker-height: 16;
      }
      ["signal_speed_limit_speed"="5"] {
        marker-file: url('symbols/de/bostrab/g2a-5.svg');
      }
      ["signal_speed_limit_speed"="10"] {
        marker-file: url('symbols/de/bostrab/g2a-10.svg');
      }
      ["signal_speed_limit_speed"="15"] {
        marker-file: url('symbols/de/bostrab/g2a-15.svg');
      }
      ["signal_speed_limit_speed"="20"] {
        marker-file: url('symbols/de/bostrab/g2a-20.svg');
      }
      ["signal_speed_limit_speed"="25"] {
        marker-file: url('symbols/de/bostrab/g2a-25.svg');
      }
      ["signal_speed_limit_speed"="30"] {
        marker-file: url('symbols/de/bostrab/g2a-30.svg');
      }
      ["signal_speed_limit_speed"="35"] {
        marker-file: url('symbols/de/bostrab/g2a-35.svg');
      }
      ["signal_speed_limit_speed"="40"] {
        marker-file: url('symbols/de/bostrab/g2a-40.svg');
      }
      ["signal_speed_limit_speed"="50"] {
        marker-file: url('symbols/de/bostrab/g2a-50.svg');
      }
      ["signal_speed_limit_speed"="60"] {
        marker-file: url('symbols/de/bostrab/g2a-60.svg');
      }
    }
  }

  [zoom>=14] {
    /* East German line speed signal "Eckentafel" (Lf 5) */
    ["feature"="DE-ESO:dr:lf5"]["signal_speed_limit_form"="sign"] {
      marker-allow-overlap: true;
      marker-width: 12;
      marker-height: 16;
      marker-file: url('symbols/de/lf5-dv301-sign.svg');
    }

    /* West German line speed signal "Anfangstafel" (Lf 5) */
    ["feature"="DE-ESO:db:lf5"]["signal_speed_limit_form"="sign"] {
      marker-allow-overlap: true;
      marker-width: 11;
      marker-height: 16;
      marker-file: url('symbols/de/lf5-ds301-sign.svg');
    }

    /* German line speed signals (Lf 7) */
    ["feature"="DE-ESO:lf7"]["signal_speed_limit_form"="sign"] {
      ["signal_speed_limit_speed"=~"^((1?[1-9]|[12]0)0|5|15)$"] {
        marker-allow-overlap: true;
        marker-width: 13;
        marker-height: 16;
      }
      ["signal_speed_limit_speed"="5"] {
        marker-file: url('symbols/de/lf7-5-sign.svg');
      }
      ["signal_speed_limit_speed"="10"] {
        marker-file: url('symbols/de/lf7-10-sign.svg');
      }
      ["signal_speed_limit_speed"="15"] {
        marker-file: url('symbols/de/lf7-15-sign.svg');
      }
      ["signal_speed_limit_speed"="20"] {
        marker-file: url('symbols/de/lf7-20-sign.svg');
      }
      ["signal_speed_limit_speed"="30"] {
        marker-file: url('symbols/de/lf7-30-sign.svg');
      }
      ["signal_speed_limit_speed"="40"] {
        marker-file: url('symbols/de/lf7-40-sign.svg');
      }
      ["signal_speed_limit_speed"="50"] {
        marker-file: url('symbols/de/lf7-50-sign.svg');
      }
      ["signal_speed_limit_speed"="60"] {
        marker-file: url('symbols/de/lf7-60-sign.svg');
      }
      ["signal_speed_limit_speed"="70"] {
        marker-file: url('symbols/de/lf7-70-sign.svg');
      }
      ["signal_speed_limit_speed"="80"] {
        marker-file: url('symbols/de/lf7-80-sign.svg');
      }
      ["signal_speed_limit_speed"="90"] {
        marker-file: url('symbols/de/lf7-90-sign.svg');
      }
      ["signal_speed_limit_speed"="100"] {
        marker-file: url('symbols/de/lf7-100-sign.svg');
      }
      ["signal_speed_limit_speed"="110"] {
        marker-file: url('symbols/de/lf7-110-sign.svg');
      }
      ["signal_speed_limit_speed"="120"] {
        marker-file: url('symbols/de/lf7-120-sign.svg');
      }
      ["signal_speed_limit_speed"="130"] {
        marker-file: url('symbols/de/lf7-130-sign.svg');
      }
      ["signal_speed_limit_speed"="140"] {
        marker-file: url('symbols/de/lf7-140-sign.svg');
      }
      ["signal_speed_limit_speed"="150"] {
        marker-file: url('symbols/de/lf7-150-sign.svg');
      }
      ["signal_speed_limit_speed"="160"] {
        marker-file: url('symbols/de/lf7-160-sign.svg');
      }
      ["signal_speed_limit_speed"="170"] {
        marker-file: url('symbols/de/lf7-170-sign.svg');
      }
      ["signal_speed_limit_speed"="180"] {
        marker-file: url('symbols/de/lf7-180-sign.svg');
      }
      ["signal_speed_limit_speed"="190"] {
        marker-file: url('symbols/de/lf7-190-sign.svg');
      }
      ["signal_speed_limit_speed"="200"] {
        marker-file: url('symbols/de/lf7-200-sign.svg');
      }
    }

    /* Austrian line speed signals (Geschwindigkeitstafel) */
    ["feature"="AT-V2:geschwindigkeitstafel"]["signal_speed_limit_form"="sign"] {
      ["signal_speed_limit_speed"=~"^(1[0-6]0|[1-9][05])$"] {
        marker-allow-overlap: true;
        marker-width: 16;
        marker-height: 16;
      }
      ["signal_speed_limit_speed"="10"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-10-sign.svg');
      }
      ["signal_speed_limit_speed"="15"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-15-sign.svg');
      }
      ["signal_speed_limit_speed"="20"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-20-sign.svg');
      }
      ["signal_speed_limit_speed"="25"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-25-sign.svg');
      }
      ["signal_speed_limit_speed"="30"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-30-sign.svg');
      }
      ["signal_speed_limit_speed"="35"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-35-sign.svg');
      }
      ["signal_speed_limit_speed"="40"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-40-sign.svg');
      }
      ["signal_speed_limit_speed"="45"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-45-sign.svg');
      }
      ["signal_speed_limit_speed"="50"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-50-sign.svg');
      }
      ["signal_speed_limit_speed"="55"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-55-sign.svg');
      }
      ["signal_speed_limit_speed"="60"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-60-sign.svg');
      }
      ["signal_speed_limit_speed"="65"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-65-sign.svg');
      }
      ["signal_speed_limit_speed"="70"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-70-sign.svg');
      }
      ["signal_speed_limit_speed"="75"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-75-sign.svg');
      }
      ["signal_speed_limit_speed"="80"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-80-sign.svg');
      }
      ["signal_speed_limit_speed"="85"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-85-sign.svg');
      }
      ["signal_speed_limit_speed"="90"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-90-sign.svg');
      }
      ["signal_speed_limit_speed"="95"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-95-sign.svg');
      }
      ["signal_speed_limit_speed"="100"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-100-sign.svg');
      }
      ["signal_speed_limit_speed"="110"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-110-sign.svg');
      }
      ["signal_speed_limit_speed"="120"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-120-sign.svg');
      }
      ["signal_speed_limit_speed"="130"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-130-sign.svg');
      }
      ["signal_speed_limit_speed"="140"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-140-sign.svg');
      }
      ["signal_speed_limit_speed"="150"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-150-sign.svg');
      }
      ["signal_speed_limit_speed"="160"] {
        marker-file: url('symbols/at/geschwindigkeitstafel-160-sign.svg');
      }
    }

    ["feature"="DE-HHA:l4"]["signal_speed_limit_form"="sign"] {
      marker-allow-overlap: true;
      marker-file: url('symbols/de/hha/l4.svg');
      marker-width: 11;
      marker-height: 16;
    }

    /**********************************************/
    /* NL speed limit light (part of main signal) */
    /**********************************************/
    ["feature"="NL"]["signal_speed_limit_form"="light"] {
      marker-width: 16;
      marker-height: 16;
      marker-file: url('symbols/nl/speed_limit_light.svg');
    }
  }
}
