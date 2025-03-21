FROM registry.fly.io/openrailwaymap-tiles-europe:deployment-01JPTMDF1ZSDZ00ZD5Z7A5Z1VY as source


# Build debug tools: heaptrack
FROM alpine:3.18 AS heaptrack-build

RUN apk update
RUN apk add -- gdb git g++ make cmake zlib-dev boost-dev libunwind-dev
RUN git clone https://github.com/KDE/heaptrack.git /heaptrack

WORKDIR /heaptrack/build
# going to a commit that builds properly. We will revisit this for new releases
RUN git reset --hard f9cc35ebbdde92a292fe3870fe011ad2874da0ca
RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN make -j$(nproc)



FROM ghcr.io/maplibre/martin:main

COPY martin /config
COPY symbols /symbols
COPY --from=source /tiles /tiles


RUN apk add --no-cache gdb libunwind

# Add heaptrack
COPY --from=heaptrack-build /heaptrack/build/ /heaptrack/build/

ENV LD_LIBRARY_PATH=/heaptrack/build/lib/heaptrack/
RUN ln -s /heaptrack/build/bin/heaptrack /usr/local/bin/heaptrack


RUN #apk add heaptrack

#ENTRYPOINT ["/heaptrack/build/bin/heaptrack", "--debug", "/usr/local/bin/martin"]

#COPY tiles/heaptrack /heaptrack
#COPY tiles/martin /martin
RUN #chmod +x /martin
# RUN rm -f /tiles/standard.mbtiles

#ENTRYPOINT ["/martin"]
#CMD ["/tiles", "--workers","1", "--save-config", "-", "--listen-addresses", "[::]:3000", "--cache-size", "0", "--sprite", "/symbols", "--font", "/config/fonts"]
# "/martin",
CMD ["/tiles", "--auto-bounds", "skip", "--workers","1", "--cache-size", "0","--pool-size","1", "--listen-addresses", "0.0.0.0:3000"]
#CMD ["/tiles", "--listen-addresses", "[::]:3000", "--sprite", "/symbols", "--font", "/config/fonts", "--cache-size", "1",  "--auto-bounds", "skip", "--workers","1", "--pool-size","1"]
