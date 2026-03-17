FROM ghcr.io/linuxserver/baseimage-selkies:alpine323

ENV HARDEN_DESKTOP=true \
    HARDEN_OPENBOX=true \
    TITLE=UxPlay \
    RESTART_APP=true \
    AIRPLAY_NAME="UxPlay-Web" \
    ENABLE_MDNS_REFLECTOR=false \
    MDNS_ALLOW_INTERFACES=""

RUN apk add --no-cache \
    avahi \
    dbus \
    gstreamer \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-libav \
    uxplay

# 1. Prepare D-Bus and Avahi directories
RUN mkdir -p /var/run/dbus /var/run/avahi-daemon && \
    sed -i 's/#enable-dbus=yes/enable-dbus=yes/g' /etc/avahi/avahi-daemon.conf

# 2. Create S6 service for D-Bus (Essential for Avahi)
RUN mkdir -p /etc/services.d/dbus && \
    echo -e "#!/usr/bin/with-contenv bash\n\
    # Cleanup stale pid file if it exists\n\
    rm -f /var/run/dbus/pid /run/dbus/dbus.pid\n\
    exec dbus-daemon --system --nofork" > /etc/services.d/dbus/run && \
    chmod +x /etc/services.d/dbus/run

# 3. Create S6 service for Avahi-daemon
RUN mkdir -p /etc/services.d/avahi && cat > /etc/services.d/avahi/run <<'RUNEOF'
#!/usr/bin/with-contenv bash
set -e

# Wait for dbus socket to exist before starting
while [ ! -S /var/run/dbus/system_bus_socket ]; do sleep 1; done

if [ "${ENABLE_MDNS_REFLECTOR,,}" = "true" ]; then
  sed -i 's/^#\?enable-reflector=.*/enable-reflector=yes/' /etc/avahi/avahi-daemon.conf
else
  sed -i 's/^#\?enable-reflector=.*/enable-reflector=no/' /etc/avahi/avahi-daemon.conf
fi

if [ -n "${MDNS_ALLOW_INTERFACES}" ]; then
  if grep -q '^allow-interfaces=' /etc/avahi/avahi-daemon.conf; then
    sed -i "s/^allow-interfaces=.*/allow-interfaces=${MDNS_ALLOW_INTERFACES}/" /etc/avahi/avahi-daemon.conf
  else
    echo "allow-interfaces=${MDNS_ALLOW_INTERFACES}" >> /etc/avahi/avahi-daemon.conf
  fi
fi

exec /usr/sbin/avahi-daemon --no-drop-root
RUNEOF
RUN chmod +x /etc/services.d/avahi/run

# 4. Configure Autostart for UxPlay
RUN mkdir -p /defaults && \
    echo "sleep 5 && uxplay -n \"\${AIRPLAY_NAME}\" -nh -fs" > /defaults/autostart
